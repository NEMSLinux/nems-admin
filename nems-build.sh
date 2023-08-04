#!/bin/bash

####
# This script is *DESTRUCTIVE*
# This is how I build NEMS distros from scratch
# This is *NOT* meant to be run by users - please do not run it unless you understand clearly what you're doing.
#
# Some of the ideas in this process come from DietPi - https://github.com/Fourdee/DietPi/blob/master/PREP_SYSTEM_FOR_DIETPI.sh
#
###########
# INSTALLING THIS ON A NORMAL LINUX MACHINE WILL DESTROY THAT MACHINE #
###########
####

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root" 2>&1
  exit 1
else

if [[ -e /usr/local/share/nems ]]; then
  echo "NEMS is already built. Aborting.";
  exit 1
fi

# Create the log folder
if [[ ! -d /var/log/nems ]]; then
  mkdir /var/log/nems
fi

# If /sbin is not in PATH, add it (eg., halt, reboot)
if [[ ! $PATH == *"/sbin"* ]]; then
  export PATH=$PATH:/sbin
fi
# And again for /usr/sbin (eg., dpkg-reconfigure)
if [[ ! $PATH == *"/usr/sbin"* ]]; then
  export PATH=$PATH:/usr/sbin
fi

ver=$(cat /root/nems/nems-admin/build-version)

# Detect hardware
if [ ! -z $1 ]; then
  echo $1 > /etc/.nems_hw_model_identifier
fi

/usr/local/bin/hw-detect

if [[ ! -e /var/log/nems/hw_model ]]; then
  echo "Cannot run hw_model detection. Fail."
  exit
fi
hw_model=$(cat /var/log/nems/hw_model | sed -n 2p)

printf "\e[97;1mDETECTED HARDWARE:\e[92;1m $hw_model\e[0m"
echo ""
echo ""
echo "If this is incorrect, press CTRL-C and rerun with the hw number on command line."
echo ""
echo "eg., $0 98000"
echo ""
sleep 10

# Create a script which can be used for troubleshooting
# Provides a list of all the individual build components
# Do not set the executable bit since it is highly destructive
if [[ -d /root/nems/nems-admin/build ]]; then
  run-parts -v --test /root/nems/nems-admin/build > /tmp/nems-build.sh
else
  echo "System not prepped. This is not a user script."
  exit
fi

if [ -z $ver ]; then

  echo ""
  echo "
██╗    ██╗ █████╗ ██████╗ ███╗   ██╗██╗███╗   ██╗ ██████╗
██║    ██║██╔══██╗██╔══██╗████╗  ██║██║████╗  ██║██╔════╝
██║ █╗ ██║███████║██████╔╝██╔██╗ ██║██║██╔██╗ ██║██║  ███╗
██║███╗██║██╔══██║██╔══██╗██║╚██╗██║██║██║╚██╗██║██║   ██║
╚███╔███╔╝██║  ██║██║  ██║██║ ╚████║██║██║ ╚████║╚██████╔╝
 ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚═════╝
This program is NOT for end-users.
If you run this program, you will lose everything!
"

  echo "Usage: $0 [hw_num]"
  exit
fi

# Check disk space is adequate to build
diskfree=$(($(stat -f --format="%a*%S" .)))
if (( "$diskfree" < "6000000000" )); then
  # First, attempt to resize:
  echo "Resizing the filesystem in preparation to build..."
  /root/nems/nems-admin/resize_rootfs/nems-fs-resize > /dev/null 2>&1
  # Check again:
  diskfree=$(($(stat -f --format="%a*%S" .)))
  if (( "$diskfree" < "6000000000" )); then
    echo "You still don't have enough free space to build. Aborting."
    echo ""
    df -h
    exit
  fi
fi

echo Building NEMS $ver
cd /usr/local/share/
mkdir nems
cd nems
echo "version=$ver" > nems.conf
chown www-data:www-data nems.conf

cd /root/nems/nems-admin

echo "" > /tmp/errors.log

echo "Usage before build:"
df -hT /etc
sleep 5

# Remove cruft
apt-get update
apt-get -y --allow-remove-essential clean
for pkg in $(grep -vE "^\s*#" build/packages.remove | tr "\n" " ")
do
  if [ $(dpkg-query -W -f='${Status}' $pkg 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
    echo "*** Removing $pkg ***"
    apt-get -y --allow-remove-essential --purge remove $pkg
    echo "***"
    echo ""
  fi
  if [ $(dpkg-query -W -f='${Status}' $pkg 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
    # It still shows as installed after attempting, so try again
    echo "*** Failed to remove $pkg... trying again. ***"
    sleep 15
    echo "** Fixing broken installs **"
    apt-get -y --fix-broken install
    echo "**"
    echo "*** Retry: Removing $pkg ***"
    apt-get -y --allow-remove-essential --purge remove $pkg
    echo "***"
    echo ""
  fi
done
echo "*** Removals are done. Purging orphans..."
apt-get autoremove --purge -y
if [[ -e /usr/share/fonts/ ]]; then
  rm -R /usr/share/fonts/*
fi
if [[ -e /usr/share/icons/ ]]; then
  rm -R /usr/share/icons/*
fi
echo "***"
echo ""

# Fix any broken packages to allow installation to occur in next step
echo "*** Fixing broken installs ***"
apt-get -y --fix-broken install
echo "***"
echo ""

echo "Usage after cruft removal:"
df -hT /etc
sleep 5

# Install base packages
echo ""
echo "***** BUILDING NEMS LINUX *****"
echo ""
for pkg in $(grep -vE "^\s*#" build/packages.base | tr "\n" " ")
do
  apt-get -y --no-install-recommends install $pkg
  if [ $(dpkg-query -W -f='${Status}' $pkg 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    # It still isn't showing as installed after attempting, so try again
    sleep 15
    apt-get -y --no-install-recommends install $pkg
  fi
done

# Add packages from repositories
for pkg in $(grep -vE "^\s*#" build/packages.add | tr "\n" " ")
do
  apt-get -y --no-install-recommends install $pkg
  if [ $(dpkg-query -W -f='${Status}' $pkg 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    # It still isn't showing as installed after attempting, so try again
    sleep 15
    apt-get -y --no-install-recommends install $pkg
  fi
done

# Install dependencies, if any
apt-get -y install -f

# Be up to update
apt-get update
apt-get -y upgrade

# Disable firstrun (ARMbian)
if [[ -e /etc/init.d/firstrun ]]; then
  systemctl disable firstrun
  rm /etc/init.d/firstrun
fi

# Configure default timezone
printf 'tzdata tzdata/Areas select America\ntzdata tzdata/Zones/America select Toronto\n' | sudo debconf-set-selections
rm -f /etc/timezone
rm -f /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

#echo "Run manually parts"
#exit

echo "------------------------------"
# Run the scripts in the build folder
run-parts --exit-on-error -v build

# If build is not completing, run parts manually to find out which script
# is dying and stopping the installation

echo "------------------------------"

echo ""

# Final cleanup...

cd /tmp
apt-get -y autoremove

echo "Usage after build:"
df -hT /etc

# Output any errors encountered along the way.
cat /tmp/errors.log

echo "NEMS $ver compiled."
echo ""

# Remove progress
if [[ -e /var/www/html/userfiles/nems-build.cur ]]; then
  rm /var/www/html/userfiles/nems-build.cur
fi

# Force reboot to avoid accidental cloberring of running kernel
reboot

fi # end of else running as root
