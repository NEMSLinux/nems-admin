#!/bin/bash
# Prepare a deployment for NEMS Installation
# This is the firstrun script which simply installs the needed repositories

# run as root

cd /root
apt update
apt install git
mkdir nems
cd nems

git clone https://github.com/Cat5TV/nems-admin
git clone https://github.com/Cat5TV/nems-migrator
git clone https://github.com/zorkian/nagios-api

cd nems-admin
