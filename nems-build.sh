#!/bin/bash

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

echo "Usage before build:"
df -hT /etc
sleep 5

# Add repositories needed for deployment of apps

# Webmin
echo "deb http://download.webmin.com/download/repository sarge contrib
deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list
wget -qO - http://www.webmin.com/jcameron-key.asc | apt-key add -

# Monitorix
echo "deb http://apt.izzysoft.de/ubuntu generic universe" > /etc/apt/sources.list.d/monitorix.list
wget -qO - http://apt.izzysoft.de/izzysoft.asc | apt-key add -

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

apt --yes install -f

# Be up to date
apt --yes upgrade && apt --yes dist-upgrade

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

# Install Nagios Core
  useradd nagios
  groupadd nagcmd
  usermod -a -G nagios www-data
  usermod -a -G nagcmd nagios
  usermod -a -G nagcmd www-data
  cd /tmp
  wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.3.4.tar.gz
  tar -zxvf nagios-4.3.4.tar.gz
  cd /tmp/nagios-4.3.4/
  ./configure --with-nagios-group=nagios --with-command-group=nagcmd --with-httpd_conf=/etc/apache2/conf-available/
  make all
  make install
  make install-init
  make install-config
  make install-commandmode
  make install-webconf

  cd /tmp
  wget https://nagios-plugins.org/download/nagios-plugins-2.2.1.tar.gz
  tar -zxvf /tmp/nagios-plugins-2.2.1.tar.gz
  cd /tmp/nagios-plugins-2.2.1/
  ./configure --with-nagios-user=nagios --with-nagios-group=nagios
  make
  make install

  a2enmod rewrite
  a2enmod cgi
  a2enconf nagios

  systemctl start nagios
  systemctl enable nagios

# Finished installing Nagios Core

# Add NEMS packages

# System
cd /root/nems # this was created with nems-prep.sh
git clone https://github.com/Cat5TV/nems-admin
git clone https://github.com/Cat5TV/nems-migrator
git clone https://github.com/zorkian/nagios-api

# Import NEMS crontab (must happen after nems-migrator but before fixes.sh)
crontab /root/nems/nems-migrator/data/nems/crontab

# Web Interface
cd /var/www
rm -rf html && git clone https://github.com/Cat5TV/nems-www && mv nems-www html && chown -R www-data:www-data html
git clone https://github.com/Cat5TV/nconf && chown -R www-data:www-data nconf

# Point Nagios to the NEMS Nagios Theme in nems-www and import the config
if [[ -d /usr/share/nagios3/htdocs ]]; then
  rm -rf /usr/share/nagios3/htdocs
fi
ln -s /var/www/html/share/nagios3/ /usr/share/nagios3/htdocs
cp -R /root/nems/nems-migrator/data/nagios/conf/* /etc/nagios3/

# Import the apache2 config (must come after nems-migrator)
# FIRST NEED TO DETERMINE WHICH MODS NEED INSTALLING
# DO THESE ONE AT A TIME UNTIL WORKING
# rm -rf /etc/apache2 && cp -R /root/nems/nems-migrator/data/apache2 /etc/

# Restart related services
systemctl restart apache2
systemctl start nagios3

cd /usr/local/share/
mkdir nems
cd nems
printf "version=" > nems.conf && cat /root/nems/nems-migrator/data/nems/ver-current.txt >> nems.conf
git clone https://github.com/Cat5TV/nems-scripts

# Create symlinks, apply patches/fixes, etc.
/usr/local/share/nems/nems-scripts/fixes.sh

# Add nomodeset to grub (otherwise display may turn off after boot if connected to a TV)
  if ! grep -q "nomodeset" /etc/default/grub; then
    sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nomodeset /g' /etc/default/grub
    /usr/sbin/update-grub
  fi


# Install apps from tar like Check-MK, NConf
cd /tmp

  # pnp4nagios
  git clone https://github.com/lingej/pnp4nagios
  cd pnp4nagios
  ./configure
  make
  make all
  make install

# Migrate NEMS' customizations such as Nagios theme and icons

# Import package configurations from NEMS-Migrator

# Import default data from NEMS-Migrator

# Enable systemd items
systemctl enable webmin

# Enable NEMS MOTD
echo > /etc/motd
cp /root/nems/nems-migrator/data/nems/motd.tcl /etc/
chmod 755 /etc/motd.tcl
echo "/etc/motd.tcl" >> /etc/profile

# clean it up!
apt --yes autoremove

echo "Usage after build:"
df -hT /etc

fi
