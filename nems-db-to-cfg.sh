#!/bin/bash
# Convert NEMS Nconf Database to Nagios Config files.
# Used to create the default reconciliation files

# Should run this and replace the config files in NEMS Migrator any time you update NEMS-Sample mysql db (so they match)

dest=/tmp/nems-dump
if [[ ! -d $dest ]]; then
  mkdir $dest
fi
cd $dest
if [[ ! -d 'global' ]]; then
  mkdir global
fi
if [[ ! -d 'Default_collector' ]]; then
  mkdir Default_collector
fi

# Global
/var/www/nconf/bin/get_items.pl -c timeperiod -f > $dest/global/timeperiods.cfg
/var/www/nconf/bin/get_items.pl -c misccommand -f > $dest/global/misccommands.cfg
/var/www/nconf/bin/get_items.pl -c checkcommand -f > $dest/global/checkcommands.cfg
/var/www/nconf/bin/get_items.pl -c contact -f > $dest/global/contacts.cfg
/var/www/nconf/bin/get_items.pl -c contactgroup -f > $dest/global/contactgroups.cfg
/var/www/nconf/bin/get_items.pl -c host-template -f > $dest/global/host_templates.cfg
/var/www/nconf/bin/get_items.pl -c service-template -f > $dest/global/service_templates.cfg

# Default Collector
/var/www/nconf/bin/get_items.pl -c host -f > $dest/Default_collector/hosts.cfg
/var/www/nconf/bin/get_items.pl -c hostgroup -f > $dest/Default_collector/hostgroups.cfg
/var/www/nconf/bin/get_items.pl -c host-dependency -f > $dest/Default_collector/host_dependencies.cfg
/var/www/nconf/bin/get_items.pl -c service -f > $dest/Default_collector/services.cfg
/var/www/nconf/bin/get_items.pl -c advanced-service -f > $dest/Default_collector/advanced_services.cfg && /bin/sed -i -- 's,advancedservice,service,g' $dest/Default_collector/advanced_services.cfg
/var/www/nconf/bin/get_items.pl -c servicegroup -f > $dest/Default_collector/servicegroups.cfg
/var/www/nconf/bin/get_items.pl -c service-dependency -f > $dest/Default_collector/service_dependencies.cfg

echo Done. Files are located in $dest'
echo You can now copy these (upon review) to NEMS-Migrator's nagios/conf folder
