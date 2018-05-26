#!/bin/bash
# Lock in and push the current database state (including Nagios configs) to NEMS-Migrator
# Built for creating new sample hosts and services, and pushing to all other NEMS servers
# NEMS 1.4+ only

cd /root/nems/nems-migrator/data/1.4/
if [[ -d mysql ]]; then
  rm -rf mysql
fi
cp -R /var/lib/mysql .

cd nagios/conf
if [[ -d Default_collector ]]; then
  rm -rf Default_collector
fi
if [[ -d global ]]; then
  rm -rf global
fi
cp -R /etc/nems/conf/Default_collector .
cp -R /etc/nems/conf/global .

git add *
git commit -m "Push new default config"
git push origin master
