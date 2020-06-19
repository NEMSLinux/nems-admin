#!/bin/bash
DATE=`date +%Y-%m-%d`
if [[ "$1" == '' ]]; then comment="Update $DATE"; else comment=$1; fi

echo Pushing NEMS update: $comment
echo ""
read -s -p "Github Password: " password

ram=$(grep MemTotal /proc/meminfo | awk '{print $2 * 1024}')
ram=$(( ${ram}*80/100 ))
ram=
ramMB=$(( ${ram}/1024/1024 ))
echo ""
echo ""
echo "Setting postBuffer to $ram bytes ($ramMB MB)."
echo ""

git config --global https.postBuffer $ram

cd /root/nems/nems-admin
echo ""
pwd
git pull
git add *
git commit -am "$comment"
#git push origin master
git config https.postBuffer $ram
git push "https://Cat5TV:$password@github.com/Cat5TV/nems-admin.git"

cd /usr/local/share/nems/nems-scripts/
echo ""
pwd
git pull
git add *
git commit -am "$comment"
#git push origin master
git config https.postBuffer $ram
git push "https://Cat5TV:$password@github.com/Cat5TV/nems-scripts.git"

cd /var/www/html/
echo ""
pwd
git pull
git add *
git commit -am "$comment"
#git push origin master
git config https.postBuffer $ram
git push "https://Cat5TV:$password@github.com/Cat5TV/nems-www.git"

cd /var/www/nems-tv/
echo ""
pwd
git pull
git add *
git commit -am "$comment"
git config https.postBuffer $ram
git push "https://Cat5TV:$password@github.com/Cat5TV/nems-tv.git"

cd /root/nems/nems-migrator/
echo ""
pwd
git pull
git add *
git commit -am "$comment"
#git push origin master
git config https.postBuffer $ram
git push "https://Cat5TV:$password@github.com/Cat5TV/nems-migrator.git"

cd /var/www/nconf/
echo ""
pwd
git pull
git add *
git commit -am "$comment"
#git push origin develop
git config https.postBuffer $ram
git push "https://Cat5TV:$password@github.com/Cat5TV/nconf.git"

if [[ -d /root/nems/nems-tools ]]; then
  cd /root/nems/nems-tools
  echo ""
  pwd
  git pull
  git add *
  git commit -am "$comment"
  #git push origin master
  git config https.postBuffer $ram
  git push "https://Cat5TV:$password@github.com/Cat5TV/nems-tools.git"
fi
