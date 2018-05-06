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

apt --yes install -f

# Be up to date
apt --yes upgrade && apt --yes dist-upgrade

# Create nemsadmin user
adduser --disabled-password --gecos "" nemsadmin
# Allow user to become super-user
usermod -aG sudo nemsadmin
# Set the user password
echo -e "nemsadmin\nnemsadmin" | passwd nemsadmin >/tmp/init 2>&1

# Delete any non-root user (eg: pi)
userdel -f -r pi
userdel -f -r test #armbian
userdel -f -r odroid
userdel -f -r rock64
userdel -f -r linaro # ASUS TinkerBoard
userdel -f -r dietpi

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

# Install cockpit
  ./build/110-cockpit

exit

# Setup NEMS software
  ./build/150-nems

# Add nomodeset to grub (otherwise display may turn off after boot if connected to a TV)
  if ! grep -q "nomodeset" /etc/default/grub; then
    sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nomodeset /g' /etc/default/grub
    /usr/sbin/update-grub
  fi

# Disable swap
  sed -i '/ swap / s/^/#/' /etc/fstab
  swapoff -a


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

# clean it up!
apt --yes autoremove

# Add nemsadmin to sudoers and disable root login if that's successful
usermod -aG sudo nemsadmin && passwd -l root

# Add files to nemsadmin home folder (which later get moved to NEMS user account at init)
cd /home/nemsadmin
wget -O license.txt https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt
cp /root/nems/nems-migrator/data/nems/changelog.txt .

echo "Usage after build:"
df -hT /etc

echo "Don't forget to run: echo DEVID > /etc/.nems_hw_model_identifier"

# Output any errors encountered along the way.
cat /tmp/errors.log

fi
