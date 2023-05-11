#!/bin/bash
# Just a simple cleanup script so we don't leave
# a bunch of history behind at build-time
# THIS IS NOT AN END-USER SCRIPT
# Running this will DESTROY all your NEMS configuration and reset to factory defaults

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root" 2>&1
  exit 1
else

  if [[ $1 != "halt" ]]; then echo "Pass the halt option to halt after execution or the reboot option to reboot."; echo ""; fi;

  ver=$(/usr/local/bin/nems-info nemsver)

  echo "Cleaning up NEMS Linux $ver"
  echo ""
  read -r -p "What build number is this? " buildnum

  if [[ -f /tmp/qf.sh ]]; then
    qfrunning=`ps aux | grep -i "myscript.sh" | grep -v "grep" | wc -l`
    if [ $qfrunning -ge 1 ]
     then
      printf "Please wait... your NEMS server is being updated."
      while [ -f /tmp/qf.sh ]
      do
        printf "."
        sleep 2
      done
      echo " Ready."
     else
      rm /tmp/qf.sh
     fi
  fi

  platform=$(/usr/local/bin/nems-info platform)

  # Check if nemsadmin exists, and create it if not
  if [ ! -d /home/nemsadmin ]; then
    # Create the nemsadmin user
    /root/nems/nems-admin/build/030-user
  fi

  # Ensure all upgrades have been performed
  /usr/local/bin/nems-upgrade

  if (( $platform >= 0 )) && (( $platform <= 9 )); then
    # Reset the RPi-Monitor users
    cp -f /root/nems/nems-migrator/data/rpimonitor/daemon.conf /etc/rpimonitor/
  fi

  # Reset Samba users
  cp -f /root/nems/nems-migrator/data/samba/smb.conf /etc/samba/

  usercount=$(find /home/* -maxdepth 0 -type d | wc -l)
  if (( $usercount == 1)); then
    echo "Looks like user accounts are ready to go."
  else
    username=`/usr/local/bin/nems-info username`
    echo "You have not removed your test users. Aborting."
    echo "Run: userdel -fr $username && reboot"
    echo "Then login as nemsadmin after reboot completes."
    exit
  fi

  # Disable phpmyadmin by default
  a2disconf phpmyadmin

  sync

  echo "Did you cp the database? This script will restore from Migrator. CTRL-C to abort."
  sleep 5

  # Stop services which may be using these files
  systemctl stop webmin
  systemctl stop rpimonitor
  systemctl stop monitorix
  systemctl stop apache2
  systemctl stop nagios
  systemctl stop smbd

  touch /tmp/nems.freeze

  # Delete system email
  rm /var/spool/mail/*

  # Remove nems-tools configuration file
  if [[ -e /etc/nems/nems-tools.conf ]]; then
    rm /etc/nems/nems-tools.conf
  fi

#  /usr/local/bin/nems-push # Ensure all changes are saved to github before continuing

  # Remove system-specific NEMS configuration
  echo 'version='$ver > /usr/local/share/nems/nems.conf # Create a base config file for this version of NEMS
  chown www-data:www-data /usr/local/share/nems/nems.conf # Make it writeable by NEMS SST
  rm /usr/local/share/nems/nems.conf~ # the backup file created by fixes.sh

  # Remove nano search history and such
  rm -rf /root/.nano
  rm -rf /home/nemsadmin/.nano

  # Remove ODROID resize log
  rm -rf /root/resize--log.txt

  sudo apt-get clean
  sudo apt-get autoclean
  apt-get autoremove

  #echo "Don't forget to remove the old kernels:"
  #dpkg --get-selections | grep linux-image
#  echo "Removing old kernels..."
#  apt-get remove --purge -y $(dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d')

# Delete all Samba users
  pdbedit -L | while read USER; do pdbedit -x -u $(echo $USER | cut -d: -f1); done

  # Empty old logs
  find /var/log/ -type f -not -path "/var/log/nems/*" -exec cp /dev/null {} \;
  find /var/log/ -iname "*.gz" -type f -delete
  find /var/log/ -iname "*.log.*" -type f -delete
  rm /var/log/nagios/archives/*.log
  cat /dev/null > /var/log/wtmp
  cat /dev/null > /var/log/btmp

  # Clear system mail
  find /var/mail/ -type f -exec cp /dev/null {} \;

  # Remove Webmin logs and sessions
  rm /var/webmin/webmin.log
  rm /var/webmin/miniserv.log
  rm /var/webmin/miniserv.error
  rm /var/webmin/sessiondb.pag

  # Clear RPi-Monitor history and stats
  rm /usr/share/rpimonitor/web/stat/*.rrd

  # Clear Monitorix history, stats and config
  echo "" > /etc/monitorix/conf.d/nems.conf
  rm /var/lib/monitorix/*.rrd
  rm /var/log/monitorix*
  rm /var/lib/monitorix/www/imgs/*.png
  rm /var/lib/monitorix/usage/*

  cd /root
  rm .nano_history
  history -c
  history -w
  rm .bash_history

  cd /home/nemsadmin
  rm .nano_history
  su - nemsadmin -c "history -c"
  su - nemsadmin -c "history -w"
  rm .bash_history

  rm /var/log/lastlog
  touch /var/log/lastlog

  # Remove Robbie's key pair
  rm /home/nemsadmin/.ssh/authorized_keys

  if (( $platform != 22 )); then
    # Remove DNS Resolver config (will be auto-generated on first boot)
    echo "# Default resolv.conf file created by NEMS Admin

# Cloudflare
nameserver 1.1.1.1
nameserver 1.0.0.1
nameserver 2606:4700:4700::1111
nameserver 2606:4700:4700::1001

# Google
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 2001:4860:4860::8888
nameserver 2001:4860:4860::8844
" > /etc/resolv.conf
  fi

  # remove output from nconf
  rm /var/www/nconf/output/*

  # Remove NEMS init password file
  rm /var/www/htpasswd

  # Remove resize from patches.log
  # This will be put back in below for non-applicable platforms such as virtual appliance
  /bin/sed -i~ '/PATCH-000002/d' /var/log/nems/patches.log

  # Move patches.log so it can persist after clear
  mv /var/log/nems/patches.log /tmp
  find /var/log/nems/ -name "*" -type f -delete
  if [[ ! -d /var/log/nems ]]; then
    mkdir /var/log/nems
  fi
  if [[ ! -d /var/log/nems/nems-tools ]]; then
    mkdir /var/log/nems/nems-tools
  fi
  # Restore patches.log so patches don't get reinstalled on new img
  mv /tmp/patches.log /var/log/nems/
  echo $buildnum > /var/log/nems/build

  # Reset Nagios Core User
  cp -f /root/nems/nems-migrator/data/nagios/etc/cgi.cfg /usr/local/nagios/etc/

  # Clear Nagios' resource.cfg file
  echo "################################################################################" > /usr/local/nagios/etc/resource.cfg
  echo "# Do not edit this file here. Use the NEMS System Settings Tool web interface. #" >> /usr/local/nagios/etc/resource.cfg
  echo "################################################################################" >> /usr/local/nagios/etc/resource.cfg
  echo "\$USER1$=/usr/lib/nagios/plugins" >> /usr/local/nagios/etc/resource.cfg

  # Import default Nagios configs
  /root/nems/nems-admin/nems-restore-sample-db.sh

  # Replace the database with Sample database
  /root/nems/nems-admin/build/034-mariadb

  # Remove nconf history, should it exist
  mysql -u nconf -pnagiosadmin nconf -e "TRUNCATE History"

  # Remove NagVis user accounts and reset to default (empty) auth database
  cp -f /root/nems/nems-migrator/data/nagvis/auth.db /etc/nagvis/etc/
  chown www-data:www-data /etc/nagvis/etc/auth.db

  # Sync the current running version as the current available version
  # Will be overwritten on first boot
  /usr/local/bin/nems-info nemsver > /var/www/html/inc/ver-available.txt

  # Replace installed certs with defaults
  rm -rf /var/www/certs/
  cp -R /root/nems/nems-migrator/data/certs /var/www
  chown -R root:root /var/www/certs

  # double check that rc.local is configured correctly, which happens during tty setup
  /root/nems/nems-admin/build/011-tty

  # Make it so filesystem resizes at first boot
  # 32 = Orange Pi Zero
  # 69 = NanoPi NEO Plus2
  # 100 = Tinker Board
  # 101 = Tinker Board S
  # 120 = Khadas VIM3 Basic
  # 121 = Khadas VIM3 Pro
  # 200-202 = Indiedroid Nova
  if (( $platform == 32 )) || (( $platform == 69 )) || (( $platform == 100 )) || (( $platform == 101 )) || (( $platform == 120 )) || (( $platform == 121 )) || (( $platform == 200 )) || (( $platform == 201 )) || (( $platform == 202 )); then
    # NEMS Universal Filesystem Restore
     addition="/root/nems/nems-admin/resize_rootfs/nems-fs-resize\n"
     if grep -q "exit" /etc/rc.local; then
       # This file contains an exit command, so make sure our new command comes before it
       /bin/sed -i -- 's,exit,'"$addition"'exit,g' /etc/rc.local
     else
       # No exit command within the file, so just add it
       echo "PLACEHERE" >> /etc/rc.local
       /bin/sed -i -- 's,PLACEHERE,'"$addition"'exit 0,g' /etc/rc.local
     fi
  fi
  if (( $platform >= 0 )) && (( $platform <= 9 )); then
    # Raspberry Pi
     addition="/root/nems/nems-admin/resize_rootfs/raspi\n"
     if grep -q "exit" /etc/rc.local; then
       # This file contains an exit command, so make sure our new command comes before it
       /bin/sed -i -- 's,exit,'"$addition"'exit,g' /etc/rc.local
     else
       # No exit command within the file, so just add it
       echo "PLACEHERE" >> /etc/rc.local
       /bin/sed -i -- 's,PLACEHERE,'"$addition"'exit 0,g' /etc/rc.local
     fi
  fi
  if (( $platform >= 10 )) && (( $platform <= 19 )); then
     # ODROID
     addition="/root/nems/nems-admin/resize_rootfs/odroid-stage1\n"
     # nems-fs-resize supports the ODROID N2
     if (( $platform == 15 )); then
       addition="/root/nems/nems-admin/resize_rootfs/nems-fs-resize"
     fi

     if grep -q "exit" /etc/rc.local; then
       # This file contains an exit command, so make sure our new command comes before it
       /bin/sed -i -- 's,exit,'"$addition"'exit,g' /etc/rc.local
     else
       # No exit command within the file, so just add it
       echo "PLACEHERE" >> /etc/rc.local
       /bin/sed -i -- 's,PLACEHERE,'"$addition"'exit 0,g' /etc/rc.local
     fi
     # Also a bit of extra cleanup on the ODROID:
     rm -rf /root/scripts
  fi

  if (( $platform == 20 )) || (( $platform == 21 )) || (( $platform == 22 )); then
    # Virtual Appliance / Docker / Amazon Web Services does not need to resize the filesystem, so pretend it has already been done
    if ! grep -q "PATCH-000002" /var/log/nems/patches.log; then
      echo "PATCH-000002" >> /var/log/nems/patches.log
    fi
  fi

  if (( $platform >= 45 )) && (( $platform <= 49 )); then
    # ROCK64 and ROCKPRO64
    rm -rf /var/lib/rock64 # Ayufan's build places a file in that folder which stops it from resizing on boot
  fi

  if (( $platform >= 40 )) && (( $platform <= 42 )); then
    # PINE A64+
    rm -rf /var/lib/pine64 # Ayufan's build places a file in that folder which stops it from resizing on boot
    addition="/root/nems/nems-admin/resize_rootfs/pine64\n"
    if grep -q "exit" /etc/rc.local; then
      # This file contains an exit command, so make sure our new command comes before it
      /bin/sed -i -- 's,exit,'"$addition"'exit,g' /etc/rc.local
    else
      # No exit command within the file, so just add it
      echo "PLACEHERE" >> /etc/rc.local
      /bin/sed -i -- 's,PLACEHERE,'"$addition"'exit 0,g' /etc/rc.local
    fi
  fi


  if (( $platform == 44 )); then
    # PINE64 SOPINE
    addition="/root/nems/nems-admin/resize_rootfs/pine64\n"
    if grep -q "exit" /etc/rc.local; then
      # This file contains an exit command, so make sure our new command comes before it
      /bin/sed -i -- 's,exit,'"$addition"'exit,g' /etc/rc.local
    else
      # No exit command within the file, so just add it
      echo "PLACEHERE" >> /etc/rc.local
      /bin/sed -i -- 's,PLACEHERE,'"$addition"'exit 0,g' /etc/rc.local
    fi
  fi

  if (( $platform >= 67 )) && (( $platform <= 68 )); then
    # NanoPi M4
    addition="/root/nems/nems-admin/resize_rootfs/nems-fs-resize\n"
    if grep -q "exit" /etc/rc.local; then
      # This file contains an exit command, so make sure our new command comes before it
      /bin/sed -i -- 's,exit,'"$addition"'exit,g' /etc/rc.local
    else
      # No exit command within the file, so just add it
      echo "PLACEHERE" >> /etc/rc.local
      /bin/sed -i -- 's,PLACEHERE,'"$addition"'exit 0,g' /etc/rc.local
    fi
  fi
  
  # remove any package data left behind after removal
  apt-get purge $(dpkg -l | awk '/^rc/ { print $2 }')

  # Some final cleanup
  # This script removes any MOTD that were added during installs (annoying!)
  /root/nems/nems-admin/build/230-motd

  # Clear all network interface configs
  /usr/local/share/nems/nems-scripts/reset-network-manager.sh

  # Remove all docs except copyright
  find /usr/share/doc -depth -type f ! -name copyright|xargs rm || true
  find /usr/share/doc -empty|xargs rmdir || true
  rm -rf /usr/share/groff/* /usr/share/info/*
  rm -rf /usr/share/lintian/* /usr/share/linda/* /var/cache/man/*

  # Remove dphys-swapfile swap file if applicable (will be re-created at first boot)
  if [[ -e /var/swap ]]; then
    echo "Removing swap file (will be re-created at first boot)."
    dphys-swapfile swapoff
    systemctl stop dphys-swapfile
    rm /var/swap
  fi

  # Cleanup lingering logs and so-on
  /root/nems/nems-admin/build/999-cleanup

  sync

#  if (( $platform != 20 )) && (( $platform != 21 )) && (( $platform != 22 )); then
    # Write zeros to unused blocks before halting to create the img
#    echo "Filling empty space with zeros..."
#    dd if=/dev/zero bs=1M of=/root/.null && sync
#    while [ -f /root/.null ]
#    do
#      sync
#      rm -f /root/.null
#      sync
#      sleep 5
#    done
#  fi

echo ""
echo "Disk Usage"
echo "----------"
df -h /root

  if [[ $1 == "halt" ]]; then
echo "

Run the following command to clear history and halt:

> /root/.bash_history && history -c && history -w && > /home/nemsadmin/.bash_history && su - nemsadmin -c \"history -c\" && su - nemsadmin -c \"history -w\" && halt

"
  exit; fi;

  if [[ $1 == "reboot" ]]; then echo "Rebooting..."; reboot; exit; fi;

  # System still running: Restart services
  service networking restart
  systemctl start smbd
  systemctl start webmin
  systemctl start rpimonitor
  systemctl start monitorix
  systemctl start apache2
  systemctl start nagios
  rm /tmp/nems.freeze

fi
