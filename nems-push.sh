#!/bin/bash
DATE=`date +%Y-%m-%d`
if [[ "$1" == '' ]]; then comment="Update $DATE"; else comment=$1; fi

echo Pushing NEMS update: $comment
echo ""
read -p "Github Password: " password

cd /root/nems/nems-admin
git add *
git commit -am "$comment"
#git push origin master
git push "https://Cat5TV:$password@github.com/Cat5TV/nems-admin.git"

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

if [[ -d /root/nems/nems-tools ]]; then
  cd /root/nems/nems-tools
  git add *
  git commit -am "$comment"
  git push origin master
fi
