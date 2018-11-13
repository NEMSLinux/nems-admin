#!/bin/bash
# Lock in and push the current database state (including Nagios configs) to NEMS-Migrator
# Built for creating new sample hosts and services, and pushing to all other NEMS servers
# Requires NEMS 1.4+

# Remove nconf history, should it exist
mysql -u nconf -pnagiosadmin nconf -e "TRUNCATE History"

systemctl stop nagios
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

cd /root/nems/nems-migrator/data/1.5/mysql

if [[ -d NEMS-Sample ]]; then
  rm -rf NEMS-Sample
fi
cp -R /var/lib/mysql .
mv mysql NEMS-Sample

# Create the clean database (used after initialization with custom user)

systemctl start mysql

mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigValues WHERE fk_id_attr=47;"
mysql -u nconf -pnagiosadmin nconf -e "DELETE FROM ConfigValues WHERE fk_id_attr=55;"

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
