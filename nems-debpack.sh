#!/bin/bash

if [[ -d /tmp/nems-debpack ]]; then
  rm -rf /tmp/nems-debpack
fi

# Create the function
debpack () {
  echo Building $name
  mkdir -p /tmp/nems-debpack/build/DEBIAN
  cp $src/control /tmp/nems-debpack/build/DEBIAN/
  mkdir -p /tmp/nems-debpack/build$src && rm -rf /tmp/nems-debpack/build$src
  cp -R $src /tmp/nems-debpack/build`dirname $src`
  rm -rf /tmp/nems-debpack/build$src/.git
  # Product specific removals
  if [[ $name == 'nems-www' ]]; then
    rm -rf /tmp/nems-debpack/build/var/www/html/backup/snapshot
    mkdir /tmp/nems-debpack/build/var/www/html/backup/snapshot
    chattr +i /tmp/nems-debpack/build/var/www/html/backup/snapshot/
    rm /tmp/nems-debpack/build/var/www/html/monitorix/img/*
  fi
  dpkg-deb --build /tmp/nems-debpack/build/
  mv /tmp/nems-debpack/build.deb /root/nems/nems-admin/deb/$name.deb
  rm -rf /tmp/nems-debpack/build
  echo Done.
  echo ""
}

# Compile each product

# nems-scripts
name=nems-scripts
src=/usr/local/share/nems/nems-scripts
debpack

# nems-www
name=nems-www
src=/var/www/html
debpack

# nems-migrator
name=nems-migrator
src=/root/nems/nems-migrator
debpack

