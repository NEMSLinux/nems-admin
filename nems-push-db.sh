#!/bin/bash
# Lock in and push the current database state (including Nagios configs) to NEMS-Migrator
# Built for creating new sample hosts and services, and pushing to all other NEMS servers
# Requires NEMS 1.6+

echo ""
echo "You must have UI access in order to proceed."
echo ""

echo Starting Nagios.
systemctl start nagios
echo If you see an error, press CTRL-C immediately!!
systemctl stop nagios
sleep 5

echo "DO NOT press CTRL-C from this point forward (will leave system broken)"

sleep 3


# Proceed with DB conversion and migration

systemctl stop mysql

if [[ -d /tmp/mysql ]]; then
  rm -rf /tmp/mysql
fi
mkdir /tmp/mysql
cd /tmp/mysql

# Master copy of my live database
# As I will be working on the running one
cp -R /var/lib/mysql .

# Edit the Sample database (nemsadmin user)

systemctl start mysql

# Replace my user info with defaults
echo "Before:"
mysql -t -u nconf -pnagiosadmin nconf -e "SELECT * FROM ConfigValues WHERE fk_id_attr=47;"
mysql -t -u nconf -pnagiosadmin nconf -e "UPDATE ConfigValues SET attr_value='nemsadmin' WHERE fk_id_attr=47;"
echo "After:"
mysql -t -u nconf -pnagiosadmin nconf -e "SELECT * FROM ConfigValues WHERE fk_id_attr=47;"

echo "Before:"
mysql -t -u nconf -pnagiosadmin nconf -e "SELECT * FROM ConfigValues WHERE fk_id_attr=55;"
mysql -t -u nconf -pnagiosadmin nconf -e "UPDATE ConfigValues SET attr_value='nagios@localhost' WHERE fk_id_attr=55;"
echo "After:"
mysql -t -u nconf -pnagiosadmin nconf -e "SELECT * FROM ConfigValues WHERE fk_id_attr=55;"


# Remove nconf history, should it exist
mysql -u nconf -pnagiosadmin nconf -e "TRUNCATE History"

systemctl stop nagios

echo Starting Nagios.
systemctl start nagios
echo If you see an error, press CTRL-C immediately!!
systemctl stop nagios
sleep 5

# Convert the database to new default config files (for reconciliation)
/root/nems/nems-admin/helpers/nems-db-to-cfg.sh

# Copy the active config for use as default at init
systemctl start nagios
/root/nems/nems-admin/helpers/nems-conf-to-cfg.sh
systemctl stop nagios


systemctl stop mysql

if [[ ! -d /root/nems/nems-migrator/data/mysql ]]; then
  mkdir -p /root/nems/nems-migrator/data/mysql
fi
cd /root/nems/nems-migrator/data/mysql

if [[ -d NEMS-Sample ]]; then
  rm -rf NEMS-Sample
fi
cp -R /var/lib/mysql .
mv mysql NEMS-Sample
if [[ -e NEMS-Sample/queries.log ]]; then
  rm NEMS-Sample/queries.log
fi

# Create the clean database (used for NEMS Migrator Restore)

systemctl start mysql

# Delete commands obtained by manually doing this while having General Query Log enabled in MariaDB and monitoring the log file for DELETE queries
# https://mariadb.com/kb/en/library/general-query-log/
: '
Empty:
Hosts
Hostgroups
Services
#Advanced Services
Servicegroups
Contacts
Contactgroups
#Checkcommands
Misccommands
Timeperiods
Host templates
Service templates
Host deps.
Service deps.
Central monitors

Not Empty:
OS
Host presets
Distrib. collectors
'
# Upon adding more services/checks/etc., observe the output database "clean" to then find and add the id_item for the new additions
# As they will be the only remaining items after running this script

# Delete NEMS Host, plus the services Internet Speed Test, NEMS SBC Temperature and Root Partition
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigItems WHERE id_item=5460 OR id_item=5447 OR id_item=5350 OR id_item=5340"

# Delete contact
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigItems WHERE id_item=5443"

# Delete the default timeperiods
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigItems WHERE id_item=5305 OR id_item=5307 OR id_item=5306"

# Delete all Hostgroups
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigItems WHERE id_item=5449 OR id_item=5347 OR id_item=5445 OR id_item=5346 OR id_item=5422 OR id_item=5423 OR id_item=5345 OR id_item=5344"

# Delete all Advanced Services
#mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigItems WHERE id_item=5383 OR id_item=5383 OR id_item=5369 OR id_item=5367 OR id_item=5356 OR id_item=5370 OR id_item=5361 OR id_item=5368 OR id_item=5358 OR id_item=5365 OR id_item=5355 OR id_item=5362 OR id_item=5363 OR id_item=5360 OR id_item=5359 OR id_item=5357 OR id_item=5364 OR id_item=5366"

# Delete the one sample service group
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigItems WHERE id_item=5275"

# Delete contact group
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigItems WHERE id_item=5444"

# Delete check commands
#mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigItems WHERE id_item=5419 OR id_item=5451 OR id_item=5450 OR id_item=5319 OR id_item=5463 OR id_item=5464 OR id_item=5457 OR id_item=5410 OR id_item=5314 OR id_item=5315 OR id_item=5317 OR id_item=5409 OR id_item=5322 OR id_item=5459 OR id_item=5456 OR id_item=5453 OR id_item=5452 OR id_item=5454 OR id_item=5455 OR id_item=5308 OR id_item=5309 OR id_item=5313 OR id_item=5310 OR id_item=5312 OR id_item=5311 OR id_item=5462 OR id_item=5432 OR id_item=5435 OR id_item=5434 OR id_item=5433 OR id_item=5431 OR id_item=5382 OR id_item=5326 OR id_item=5320 OR id_item=5321 OR id_item=5461 OR id_item=5458 OR id_item=5446 OR id_item=5323 OR id_item=5316 OR id_item=5411 OR id_item=5318 OR id_item=5324 OR id_item=5408 OR id_item=5325 OR id_item=5397 OR id_item=5398 OR id_item=5396 OR id_item=5414 OR id_item=5415 OR id_item=5394 OR id_item=5413 OR id_item=5407 OR id_item=5393 OR id_item=5392 OR id_item=5391 OR id_item=5404 OR id_item=5399 OR id_item=5405 OR id_item=5418 OR id_item=5416 OR id_item=5412 OR id_item=5406 OR id_item=5400 OR id_item=5401 OR id_item=5402 OR id_item=5403 OR id_item=5417 OR id_item=5395 OR id_item=5390 OR id_item=5421 OR id_item=5420"

# Miscellaneous Commands
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigItems WHERE id_item=5331 OR id_item=5327 OR id_item=5442 OR id_item=5436 OR id_item=5328 OR id_item=5441 OR id_item=5437 OR id_item=5329 OR id_item=5330 OR id_item=5448 OR id_item=5296"

# Host templates
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigItems WHERE id_item=5297 OR id_item=5298 OR id_item=5335 OR id_item=5338 OR id_item=5339 OR id_item=5336 OR id_item=5337"

# Service templates
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigItems WHERE id_item=5301 OR id_item=5302 OR id_item=5348 OR id_item=5349"

systemctl stop mysql

cd /root/nems/nems-migrator/data/mysql

if [[ -d NEMS-Clean ]]; then
  rm -rf NEMS-Clean
fi
cp -R /var/lib/mysql .
mv mysql NEMS-Clean
if [[ -e NEMS-Clean/queries.log ]]; then
  rm NEMS-Clean/queries.log
fi

# Restore original MySQL database and resume operation as normal
rm -rf /var/lib/mysql
cp -R /tmp/mysql/mysql /var/lib
chown -R mysql:mysql /var/lib/mysql

systemctl start mysql
systemctl start nagios

echo "Done. Remember to migrate /root/nems/nems-migrator/data/mysql to debpack!"
