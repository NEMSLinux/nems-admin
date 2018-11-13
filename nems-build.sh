#!/bin/bash

# TO DO
# Add removal of swap

####
# This script is *DESTRUCTIVE*
# This is how I build NEMS distros from scratch
# This is *NOT* meant to be run by users - please do not run it unless you understand clearly what you're doing.
#
# Some of the ideas in this process come from DietPi - https://github.com/Fourdee/DietPi/blob/master/PREP_SYSTEM_FOR_DIETPI.sh
####

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root" 2>&1
  exit 1
else

ver=$(cat /root/nems/nems-admin/build-version)

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

diskfree=$(($(stat -f --format="%a*%S" .)))
if (( "$diskfree" < "8589934592" )); then
  echo You do not have enough free space to build. Did you resize the root fs?
  exit
fi

if [[ ! -d /var/log/nems ]]; then
  mkdir /var/log/nems
fi

echo Building NEMS $ver
cd /usr/local/share/
mkdir nems
cd nems
echo "version=$ver" > nems.conf
chown www-data:www-data nems.conf

# Detect hardware
if [ ! -z $1 ]; then
  echo $1 > /etc/.nems_hw_model_identifier
fi
wget -O /tmp/hw_model.sh https://raw.githubusercontent.com/Cat5TV/nems-scripts/master/hw_model.sh
chmod +x /tmp/hw_model.sh
/tmp/hw_model.sh
hw_model=$(cat /var/log/nems/hw_model | sed -n 2p)
echo "Detected Hardware: $hw_model"
echo "If this is incorrect, press CTRL-C and rerun with the hw number on command line."
echo "eg., $0 $ver 98000"
sleep 5

cd /root/nems/nems-admin

echo "" > /tmp/errors.log

echo "Usage before build:"
df -hT /etc
sleep 5

# Add repositories needed for deployment of apps

# Webmin
echo "deb http://download.webmin.com/download/repository sarge contrib
deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list
wget -qO - http://www.webmin.com/jcameron-key.asc | apt-key add -

# Remove cruft
apt update
apt --yes --allow-remove-essential clean
apt --yes --allow-remove-essential --purge remove $(grep -vE "^\s*#" build/packages.remove | tr "\n" " ")
apt autoremove --purge -y
rm -R /usr/share/fonts/*
rm -R /usr/share/icons/*

echo "Usage after cruft removal:"
df -hT /etc
sleep 5

for pkg in $(grep -vE "^\s*#" build/packages.base | tr "\n" " ")
do
  apt --yes --no-install-recommends install $pkg
done

# Add packages from repositories
for pkg in $(grep -vE "^\s*#" build/packages.add | tr "\n" " ")
do
  apt --yes --no-install-recommends install $pkg
done

# Install dependencies, if any
apt --yes install -f

# Be up to date
apt --yes upgrade && apt --yes dist-upgrade

# Upgrade firmware (Removed; will stick with stable firmware via raspberrypi-bootloader)
# rpi-update

# Upgrade again in case anything changed on the new kernel
apt update
apt --yes upgrade && apt --yes dist-upgrade

# Disable firstrun (ARMbian)
if [[ -e /etc/init.d/firstrun ]]; then
  systemctl disable firstrun
  rm /etc/init.d/firstrun
fi

echo "------------------------------"
# Run the scripts in the build folder
run-parts --exit-on-error -v build

# If build is not completing, run parts manually to find out which script
# is dying and stopping the installation

echo "------------------------------"

echo ""

# Final cleanup...

cd /tmp
apt --yes autoremove

echo "Usage after build:"
df -hT /etc

# Output any errors encountered along the way.
cat /tmp/errors.log

echo "NEMS $ver compiled."
echo ""

fi # end of else running as root
