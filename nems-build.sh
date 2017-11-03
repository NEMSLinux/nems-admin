#!/bin/bash
version=1.3.1
echo "NOT SAFE"
exit
####
# Some of the ideas in this process come from DietPi - https://github.com/Fourdee/DietPi/blob/master/PREP_SYSTEM_FOR_DIETPI.sh
####

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
userdel -f linaro #ASUS TB
userdel -f dietpi

# Disable firstrun
systemctl disable firstrun
rm /etc/init.d/firstrun # ARMbian

# Add NEMS packages

# Import package configurations from NEMS-Migrator

