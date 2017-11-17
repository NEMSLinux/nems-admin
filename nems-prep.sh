#!/bin/bash
# Prepare a deployment for NEMS Installation
# This is the firstrun script which simply installs the needed repositories

# Run like this:
# wget -O /tmp/nems-prep.sh https://raw.githubusercontent.com/Cat5TV/nems-admin/master/nems-prep.sh && chmod +x /tmp/nems-prep.sh && /tmp/nems-prep.sh

# run as root

cd /root
apt update
apt install git
mkdir nems
cd nems

git clone https://github.com/Cat5TV/nems-admin

cd nems-admin
