#!/bin/bash

cd /root/nems/nems-admin
git add *
git commit -m "Update"
git push origin master

cd /home/pi/nems-scripts/
git add *
git commit -m "Update"
git push origin master

cd /var/www/html/
git add *
git commit -m "Update"
git push origin master

cd /root/nems/nems-migrator/
git add *
git commit -m "Update"
git push origin master
