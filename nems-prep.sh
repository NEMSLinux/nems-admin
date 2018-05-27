#!/bin/bash
# Prepare a deployment for NEMS Installation
# This is the firstrun script which simply installs the needed repositories

# Run like this:
# wget -O /tmp/nems-prep.sh https://raw.githubusercontent.com/Cat5TV/nems-admin/master/nems-prep.sh && chmod +x /tmp/nems-prep.sh && /tmp/nems-prep.sh


if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root" 2>&1
  exit 1
else

# NEED TO ADD REPOS MANUALLY FOR NOW
# Pi:
#deb http://mirrordirector.raspbian.org/raspbian/ stretch main contrib non-free rpi firmware

#Debian:
#  echo "deb http://deb.debian.org/debian/ stretch non-free main
#        deb-src http://deb.debian.org/debian/ stretch non-free main
#        deb http://security.debian.org/debian-security stretch/updates non-free main contrib
#        deb-src http://security.debian.org/debian-security stretch/updates non-free main contrib
        # stretch-updates, previously known as 'volatile'
#        deb http://deb.debian.org/debian/ stretch-updates non-free main contrib
#       deb-src http://deb.debian.org/debian/ stretch-updates non-free main contrib
#  " > /etc/apt/sources.list
  
  apt update
  apt install --yes git screen ca-certificates
  
  # Setup default account info
  git config --global user.email "nems@baldnerd.com"
  git config --global user.name "NEMS Linux"

  cd /root
  mkdir nems
  cd nems

  git clone https://github.com/Cat5TV/nems-admin

  cd /root/nems/nems-admin

  echo System Prepped... run screen, then /root/nems/nems-admin/nems-build.sh
fi
