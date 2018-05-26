#!/bin/bash
DATE=`date +%Y-%m-%d`
if [[ "$1" == '' ]]; then comment="Update $DATE"; else comment=$1; fi

cd /root/nems/nems-admin
git add *
git commit -am "$comment"
git push origin master

cd /usr/local/share/nems/nems-scripts/
git add *
git commit -am "$comment"
git push origin master

cd /var/www/html/
git add *
git commit -am "$comment"
git push origin master

cd /root/nems/nems-migrator/
git add *
git commit -am "$comment"
git push origin master

cd /var/www/nconf/
git add *
git commit -am "$comment"
git push origin develop

