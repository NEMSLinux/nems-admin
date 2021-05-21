#!/bin/bash
db=Sample
#db=Clean

# ----------------------

/bin/systemctl stop mysql
rm -rf /var/lib/mysql/
cd /var/lib/
tar xfz /root/nems/nems-migrator/data/mysql/NEMS-${db}.tar.gz
chown -R mysql:mysql /var/lib/mysql
/bin/systemctl start mysql

systemctl stop nagios
rm -rf /etc/nems/conf/Default_collector
rm -rf /etc/nems/conf/global
cp -R /root/nems/nems-migrator/data/nagios/conf/* /etc/nems/conf/

# Set ownership
chown -R www-data:www-data /etc/nems/conf/Default_collector
chown -R www-data:www-data /etc/nems/conf/global
systemctl start nagios
