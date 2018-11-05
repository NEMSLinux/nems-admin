#!/bin/bash
# Lock in and push the current database state (including Nagios configs) to NEMS-Migrator
# Built for creating new sample hosts and services, and pushing to all other NEMS servers
# Requires NEMS 1.4+

# Remove nconf history, should it exist
mysql -u nconf -pnagiosadmin nconf -e "TRUNCATE History"

systemctl stop nagios
systemctl stop mysql

cd /root/nems/nems-migrator/data/1.5/mysql
if [[ -d NEMS-Sample ]]; then
  rm -rf NEMS-Sample
fi
cp -R /var/lib/mysql .
mv mysql NEMS-Sample

systemctl start mysql
systemctl start nagios

echo "Press CTRL-C now to push manually, otherwise standby"
sleep 5

git add *
git commit -m "Push new default config"
git push origin master
