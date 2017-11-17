#!/bin/bash

####
# Some of the ideas in this process come from DietPi - https://github.com/Fourdee/DietPi/blob/master/PREP_SYSTEM_FOR_DIETPI.sh
####

# Add nomodeset to grub (otherwise display may turn off after boot if connected to a TV)
  if ! grep -q "nomodeset" /etc/default/grub; then
    sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nomodeset /g' /etc/default/grub
    /usr/sbin/update-grub
  fi

# Remove cruft
apt update
apt --yes --force-yes clean
apt --yes --force-yes --purge remove $(grep -vE "^\s*#" build/packages.remove | tr "\n" " ")
apt autoremove --purge -y
rm -R /usr/share/fonts/*
rm -R /usr/share/icons/*
apt --yes --force-yes --no-install-recommends install $(grep -vE "^\s*#" build/packages.base | tr "\n" " ")

# Add packages from repositories
apt --yes --force-yes install $(grep -vE "^\s*#" build/packages.add | tr "\n" " ")

# Be up to date
apt --yes --force-yes upgrade && apt --yes --force-yes dist-upgrade

# Delete any non-root user (eg: pi)
userdel -f pi
userdel -f test #armbian
userdel -f odroid
userdel -f rock64
userdel -f linaro # ASUS TinkerBoard
userdel -f dietpi

# Disable firstrun
systemctl disable firstrun
rm /etc/init.d/firstrun # ARMbian

# Add NEMS packages
cd /root/nems # this was created with nems-prep.sh
git clone https://github.com/Cat5TV/nems-admin
git clone https://github.com/Cat5TV/nems-migrator
git clone https://github.com/zorkian/nagios-api

cd /usr/local/share/
mkdir nems
printf "version=" > /usr/local/share/nems.conf && cat /root/nems/nems-migrator/data/nems/ver-current.txt >> /usr/local/share/nems.conf
git clone https://github.com/Cat5TV/nems-scripts

# Create symlinks, etc.
/usr/local/share/nems/nems-scripts/fixes.sh

# Import package configurations from NEMS-Migrator

# Import default data from NEMS-Migrator

# Integrate crontab


