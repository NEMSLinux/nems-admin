#!/bin/bash
# Prepare a deployment for NEMS Installation
# This is the firstrun script which simply installs the needed repositories

# Run like this:
# wget -O /tmp/nems-prep.sh https://raw.githubusercontent.com/Cat5TV/nems-admin/master/nems-prep.sh && chmod +x /tmp/nems-prep.sh && /tmp/nems-prep.sh


if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root" 2>&1
  exit 1
else

PATH=$PATH:/sbin

apt update
apt install --yes git screen dialog gnupg nano apt-utils sudo

# Add NEMS Linux Repositories
echo "# NEMS Linux 1.6 Repositories
deb https://repos.nemslinux.com/ 1.6 main
deb https://repos.nemslinux.com/ 1.6 migrator
deb https://repos.nemslinux.com/ 1.6 plugins" > /etc/apt/sources.list.d/nemslinux.list

# Add the public key [expires: 2024-07-05]
wget -O - https://repos.nemslinux.com/nemslinux.gpg.key | apt-key add -

# Base OS won't necessarily have these key components yet
apt-get update
apt-get install -y wget python3

printf "RTC reports date/time as: "
date

echo "Adjusting based on my nerdgasm..."
# We know I have a valid cert, but we'll ignore it because IF the clock is indeed wrong, it will fail
# Note - 192 is America/Toronto. If you are building this elsewhere, make sure you change the tz=
wget --no-check-certificate -O - https://www.baldnerd.com/nerdgasms/linuxdate/ajax.php?tz=192 | { read gmt; date -s "$gmt"; }

printf "New time is reported as: "
date

echo ""
sleep 5

# Tell apt to retry up to 10 times before giving up. This should
# help for all the times the Raspberry Pi repos are down during
# a build...
echo "APT::Acquire::Retries \"3\";" > /etc/apt/apt.conf.d/80-retries && chmod 644 /etc/apt/apt.conf.d/80-retries

# Give apt-get a fancy progress bar like apt
echo "Dpkg::Progress-Fancy \"1\";
Dpkg::Progress-Fancy::Progress-Bg \"%1b[40m\";
" > /etc/apt/apt.conf.d/99-progressbar && chmod 644 /etc/apt/apt.conf.d/99-progressbar

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
  
  # Make absolutely certain sudo is installed (as we'll be removing root login)
  command -v sudo >/dev/null 2>&1 || { echo "sudo could not be installed.  Aborting." >&2; exit 1; }

  # Setup default account info
  git config --global user.email "nems@baldnerd.com"
  git config --global user.name "NEMS Linux"

  cd /root
  mkdir nems
  cd nems

  git -c http.sslVerify=false clone https://github.com/NEMSLinux/nems-admin
  
  cd /root/nems/nems-admin
  git config pull.rebase false

  # Configure default locale
  apt install -y locales
  if grep -q "# en_US.UTF-8" /etc/locale.gen; then
    /bin/sed -i -- 's,# en_US.UTF-8,en_US.UTF-8,g' /etc/locale.gen
  fi
  locale-gen
  export LANGUAGE=en_US.UTF-8
  export LANG=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
  export LC_TIME=en_US.UTF-8
  #dpkg-reconfigure locales # Set second screen to UTF8

  # Make it so SSH does not load the locale from the connecting machine (causes problems on Pine64)
  # This requires the user to re-connect
  sed -i -e 's/    SendEnv LANG LC_*/#   SendEnv LANG LC_*/g' /etc/ssh/ssh_config

  # Create nemsadmin user
  adduser --disabled-password --gecos "" nemsadmin

  # Allow user to become super-user
  usermod -aG sudo nemsadmin

  # Set the user password
  echo -e "nemsadmin\nnemsadmin" | passwd nemsadmin >/tmp/init 2>&1

  # Add nemsadmin to sudoers and disable root login if that's successful
  usermod -aG sudo nemsadmin && passwd -l root

  # Add files to nemsadmin home folder (which later get moved to NEMS user account at init)
  cd /home/nemsadmin
  wget -O license.txt https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt
  wget -O changelog.txt https://raw.githubusercontent.com/Cat5TV/nems-migrator/master/data/nems/changelog.txt

  # Setup log folder so hw-detect can run. Permissions will be setup later.
  if [[ ! -e /var/log/nems ]]; then
    mkdir /var/log/nems
  fi

  # Setup Vendor capabilities
  if [[ ! -e /boot/vendor ]]; then
    mkdir /boot/vendor
  fi

  # Install any NEMS components that are required immediately
  apt-get install -y hw-detect

  # Setup default paths
  echo 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/bin:/usr/games:/sbin"' > /etc/environment

  echo "System Prepped. Please restart, re-connect as nemsadmin, run screen, then run your build script (see ./notes)."

  if [[ -e /sbin/reboot ]]; then
    /sbin/reboot
  fi

fi
