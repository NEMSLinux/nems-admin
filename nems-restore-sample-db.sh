#!/bin/bash
version=$(/usr/local/bin/nems-info nemsbranch)
#version=1.4
db=Sample
#db=Clean

# ----------------------

systemctl stop mysql
rm -rf /var/lib/mysql
cp -R /root/nems/nems-migrator/data/$version/mysql/NEMS-$db /var/lib/
chown -R mysql:mysql /var/lib/NEMS-$db
mv /var/lib/NEMS-$db /var/lib/mysql
systemctl start mysql

systemctl stop nagios
rm -rf /etc/nems/conf/Default_collector
rm -rf /etc/nems/conf/global
cp -R /root/nems/nems-migrator/data/$version/nagios/conf/* /etc/nems/conf/
# Import the live configs (sample data from dump)
#rm /etc/nems/conf/Default_collector/advanced_services.cfg
#mv /etc/nems/conf/Default_collector/advanced_services_sample.cfg /etc/nems/conf/Default_collector/advanced_services.cfg
#rm /etc/nems/conf/global/service_templates.cfg
#mv /etc/nems/conf/global/service_templates_sample.cfg /etc/nems/conf/global/service_templates.cfg
# Set ownership
chown -R www-data:www-data /etc/nems/conf/Default_collector
chown -R www-data:www-data /etc/nems/conf/global
systemctl start nagios

