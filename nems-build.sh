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

ver=$1

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

  echo "Usage: $0 [version]"
  exit
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

# Add repositories needed for deployment of apps

# Webmin
echo "deb http://download.webmin.com/download/repository sarge contrib
deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list
wget -qO - http://www.webmin.com/jcameron-key.asc | apt-key add -

# Monitorix
echo "deb [arch=all] https://apt.izzysoft.de/ubuntu generic universe" > /etc/apt/sources.list.d/monitorix.list
wget -qO - https://apt.izzysoft.de/izzysoft.asc | apt-key add -

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

# Upgrade firmware
rpi-update

# Upgrade again in case anything changed on the new kernel
apt update
apt --yes upgrade && apt --yes dist-upgrade

# Disable firstrun
systemctl disable firstrun
rm /etc/init.d/firstrun # ARMbian

echo "------------------------------"

# Run the scripts in the build folder
run-parts --exit-on-error -v build

echo "------------------------------"

echo ""

read -n 1 -s -r -p "Press any key to clean up our build..."

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
echo "Don't forget to run: echo DEVID > /etc/.nems_hw_model_identifier"

fi
