#!/bin/bash
# Lock in and push the current database state (including Nagios configs) to NEMS-Migrator
# Built for creating new sample hosts and services, and pushing to all other NEMS servers
# Requires NEMS 1.4+

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

systemctl stop mysql

if [[ ! -d /root/nems/nems-migrator/data/1.5/mysql ]]; then
  mkdir -p /root/nems/nems-migrator/data/1.5/mysql
fi
cd /root/nems/nems-migrator/data/1.5/mysql

if [[ -d NEMS-Sample ]]; then
  rm -rf NEMS-Sample
fi
cp -R /var/lib/mysql .
mv mysql NEMS-Sample

# Create the clean database (used after initialization with custom user)

systemctl start mysql

item=$(mysql -s -r -u nconf -pnagiosadmin nconf -e "SELECT fk_id_item FROM ConfigValues WHERE fk_id_attr=47;" | sed -n 1p)
if [[ $item != '' ]]; then
  mysql -s -u nconf -pnagiosadmin nconf -e "DELETE FROM ItemLinks WHERE fk_id_item=$item;"
fi
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigValues WHERE fk_id_attr=47;"  # admin username

item=$(mysql -s -r -u nconf -pnagiosadmin nconf -e "SELECT fk_id_item FROM ConfigValues WHERE fk_id_attr=55;" | sed -n 1p)
if [[ $item != '' ]]; then
  mysql -s -u nconf -pnagiosadmin nconf -e "DELETE FROM ItemLinks WHERE fk_id_item=$item;"
fi
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigValues WHERE fk_id_attr=55;"  # admin email

item=$(mysql -s -r -u nconf -pnagiosadmin nconf -e "SELECT fk_id_item FROM ConfigValues WHERE fk_id_attr=56;" | sed -n 1p)
if [[ $item != '' ]]; then
  mysql -s -u nconf -pnagiosadmin nconf -e "DELETE FROM ItemLinks WHERE fk_id_item=$item;"
fi
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigValues WHERE fk_id_attr=56;"  # admin phone

item=$(mysql -s -r -u nconf -pnagiosadmin nconf -e "SELECT fk_id_item FROM ConfigValues WHERE fk_id_attr=48;" | sed -n 1p)
if [[ $item != '' ]]; then
  mysql -s -u nconf -pnagiosadmin nconf -e "DELETE FROM ItemLinks WHERE fk_id_item=$item;"
fi
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigValues WHERE fk_id_attr=48;"  # admin name

item=$(mysql -s -r -u nconf -pnagiosadmin nconf -e "SELECT fk_id_item FROM ConfigValues WHERE fk_id_attr=51;" | sed -n 1p)
if [[ $item != '' ]]; then
  mysql -s -u nconf -pnagiosadmin nconf -e "DELETE FROM ItemLinks WHERE fk_id_item=$item;"
fi
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigValues WHERE fk_id_attr=51;"  # admin notifications

item=$(mysql -s -r -u nconf -pnagiosadmin nconf -e "SELECT fk_id_item FROM ConfigValues WHERE fk_id_attr=52;" | sed -n 1p)
if [[ $item != '' ]]; then
  mysql -s -u nconf -pnagiosadmin nconf -e "DELETE FROM ItemLinks WHERE fk_id_item=$item;"
fi
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigValues WHERE fk_id_attr=52;"  # admin notifications

item=$(mysql -s -r -u nconf -pnagiosadmin nconf -e "SELECT fk_id_item FROM ConfigValues WHERE fk_id_attr=96;" | sed -n 1p)
if [[ $item != '' ]]; then
  mysql -s -u nconf -pnagiosadmin nconf -e "DELETE FROM ItemLinks WHERE fk_id_item=$item;"
fi
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigValues WHERE fk_id_attr=96;"  # admin type

item=$(mysql -s -r -u nconf -pnagiosadmin nconf -e "SELECT fk_id_item FROM ConfigValues WHERE fk_id_attr=97;" | sed -n 1p)
if [[ $item != '' ]]; then
  mysql -s -u nconf -pnagiosadmin nconf -e "DELETE FROM ItemLinks WHERE fk_id_item=$item;"
fi
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigValues WHERE fk_id_attr=97;"  # admin enabled

item=$(mysql -s -r -u nconf -pnagiosadmin nconf -e "SELECT fk_id_item FROM ConfigValues WHERE fk_id_attr=58;" | sed -n 1p)
if [[ $item != '' ]]; then
  mysql -s -u nconf -pnagiosadmin nconf -e "DELETE FROM ItemLinks WHERE fk_id_item=$item;"
fi
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigValues WHERE fk_id_attr=58;"  # "Nagios Administrators"

item=$(mysql -s -r -u nconf -pnagiosadmin nconf -e "SELECT fk_id_item FROM ConfigValues WHERE fk_id_attr=15;" | sed -n 1p)
if [[ $item != '' ]]; then
  mysql -s -u nconf -pnagiosadmin nconf -e "DELETE FROM ItemLinks WHERE fk_id_item=$item;"
fi
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigValues WHERE fk_id_attr=15;"  # hosts

item=$(mysql -s -r -u nconf -pnagiosadmin nconf -e "SELECT fk_id_item FROM ConfigValues WHERE fk_id_attr=27;" | sed -n 1p)
if [[ $item != '' ]]; then
  mysql -s -u nconf -pnagiosadmin nconf -e "DELETE FROM ItemLinks WHERE fk_id_item=$item;"
fi
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigValues WHERE fk_id_attr=27;"  # hostgroups

item=$(mysql -s -r -u nconf -pnagiosadmin nconf -e "SELECT fk_id_item FROM ConfigValues WHERE fk_id_attr=60;" | sed -n 1p)
if [[ $item != '' ]]; then
  mysql -s -u nconf -pnagiosadmin nconf -e "DELETE FROM ItemLinks WHERE fk_id_item=$item;"
fi
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigValues WHERE fk_id_attr=60;"  # services

item=$(mysql -s -r -u nconf -pnagiosadmin nconf -e "SELECT fk_id_item FROM ConfigValues WHERE fk_id_attr=182;" | sed -n 1p)
if [[ $item != '' ]]; then
  mysql -s -u nconf -pnagiosadmin nconf -e "DELETE FROM ItemLinks WHERE fk_id_item=$item;"
fi
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigValues WHERE fk_id_attr=182;" # advanced-services

item=$(mysql -s -r -u nconf -pnagiosadmin nconf -e "SELECT fk_id_item FROM ConfigValues WHERE fk_id_attr=70;" | sed -n 1p)
if [[ $item != '' ]]; then
  mysql -s -u nconf -pnagiosadmin nconf -e "DELETE FROM ItemLinks WHERE fk_id_item=$item;"
fi
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigValues WHERE fk_id_attr=70;"  # servicegroups

#mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigValues WHERE fk_id_attr=12;"  # OS's

item=$(mysql -s -r -u nconf -pnagiosadmin nconf -e "SELECT fk_id_item FROM ConfigValues WHERE fk_id_attr=57;" | sed -n 1p)
if [[ $item != '' ]]; then
  mysql -s -u nconf -pnagiosadmin nconf -e "DELETE FROM ItemLinks WHERE fk_id_item=$item;"
fi
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigValues WHERE fk_id_attr=57;"  # contactgroups

item=$(mysql -s -r -u nconf -pnagiosadmin nconf -e "SELECT fk_id_item FROM ConfigValues WHERE fk_id_attr=30;" | sed -n 1p)
if [[ $item != '' ]]; then
  mysql -s -u nconf -pnagiosadmin nconf -e "DELETE FROM ItemLinks WHERE fk_id_item=$item;"
fi
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigValues WHERE fk_id_attr=30;"  # checkcommands

item=$(mysql -s -r -u nconf -pnagiosadmin nconf -e "SELECT fk_id_item FROM ConfigValues WHERE fk_id_attr=98;" | sed -n 1p)
if [[ $item != '' ]]; then
  mysql -s -u nconf -pnagiosadmin nconf -e "DELETE FROM ItemLinks WHERE fk_id_item=$item;"
fi
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigValues WHERE fk_id_attr=98;"  # misccommands

item=$(mysql -s -r -u nconf -pnagiosadmin nconf -e "SELECT fk_id_item FROM ConfigValues WHERE fk_id_attr=32;" | sed -n 1p)
if [[ $item != '' ]]; then
  mysql -s -u nconf -pnagiosadmin nconf -e "DELETE FROM ItemLinks WHERE fk_id_item=$item;"
fi
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigValues WHERE fk_id_attr=32;"  # timeperiods

#mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigValues WHERE fk_id_attr=73;"  # host-presets

item=$(mysql -s -r -u nconf -pnagiosadmin nconf -e "SELECT fk_id_item FROM ConfigValues WHERE fk_id_attr=108;" | sed -n 1p)
if [[ $item != '' ]]; then
  mysql -s -u nconf -pnagiosadmin nconf -e "DELETE FROM ItemLinks WHERE fk_id_item=$item;"
fi
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigValues WHERE fk_id_attr=108;" # host-templates

item=$(mysql -s -r -u nconf -pnagiosadmin nconf -e "SELECT fk_id_item FROM ConfigValues WHERE fk_id_attr=129;" | sed -n 1p)
if [[ $item != '' ]]; then
  mysql -s -u nconf -pnagiosadmin nconf -e "DELETE FROM ItemLinks WHERE fk_id_item=$item;"
fi
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigValues WHERE fk_id_attr=129;" # service-templates

systemctl stop mysql

cd /root/nems/nems-migrator/data/1.5/mysql

if [[ -d NEMS-Clean ]]; then
  rm -rf NEMS-Clean
fi
cp -R /var/lib/mysql .
mv mysql NEMS-Clean


# Restore original MySQL database and resume operation as normal
rm -rf /var/lib/mysql
cp -R /tmp/mysql/mysql /var/lib
chown -R mysql:mysql /var/lib/mysql

systemctl start mysql
systemctl start nagios

echo "Press CTRL-C now to push manually, otherwise standby"
sleep 5

git add *
git commit -m "Push new default config"
git push origin master
