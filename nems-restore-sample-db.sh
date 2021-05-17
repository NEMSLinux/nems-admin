#!/bin/bash
db=Sample
#db=Clean

# ----------------------

systemctl stop mysql
rm -rf /var/lib/mysql
cp -R /root/nems/nems-migrator/data/mysql/NEMS-$db /var/lib/
chown -R mysql:mysql /var/lib/NEMS-$db
mv /var/lib/NEMS-$db /var/lib/mysql
systemctl start mysql

systemctl stop nagios
rm -rf /etc/nems/conf/Default_collector
rm -rf /etc/nems/conf/global
cp -R /root/nems/nems-migrator/data/nagios/conf/* /etc/nems/conf/

# Set ownership
chown -R www-data:www-data /etc/nems/conf/Default_collector
chown -R www-data:www-data /etc/nems/conf/global
systemctl start nagios

