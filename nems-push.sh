#!/bin/bash

cd /root/nems/nems-admin
git commit -am "Update"
git push origin master

cd /home/pi/nems-scripts/
git commit -am "Update"
git push origin master

cd /var/www/html/
git commit -am "Update"
git push origin master

cd /root/nems/nems-migrator/
git commit -am "Update"
git push origin master
