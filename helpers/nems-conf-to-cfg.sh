#!/bin/bash
# Convert NEMS Nconf Database to Nagios Config files.
# Used to create the default reconciliation files

# Automatically replaces the config files in NEMS Migrator any time you update NEMS-Sample mysql db (so they match)

dest=/root/nems/nems-migrator/data/nagios/conf

echo ""
echo "Ready to copy your /etc/nems/conf folder. Please open NConf and Generate Config."

read -n 1 -s -r -p "Generate Config and press any key to continue"

if [[ ! -d $dest ]]; then
  mkdir -p $dest
else
  rm -rf $dest
  mkdir -p $dest
fi
cd $dest

cp -R /etc/nems/conf/Default_collector $dest
cp -R /etc/nems/conf/global $dest

echo Done. Files in $dest have been updated. Remember, these are part of debpack now. Must copy and PR.
