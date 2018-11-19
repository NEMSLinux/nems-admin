#!/bin/bash
systemctl stop mysql
rm -rf /var/lib/mysql
cp -R /root/nems/nems-migrator/data/`/usr/local/bin/nems-info nemsbranch`/mysql/NEMS-Sample /var/lib/
chown -R mysql:mysql /var/lib/NEMS-Sample
mv /var/lib/NEMS-Sample /var/lib/mysql
systemctl start mysql
