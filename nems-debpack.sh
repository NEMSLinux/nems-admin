#!/bin/bash
dpkg-deb --build /root/nems/nems-admin/build/nems-debpack/nems-scripts
dpkg-deb --build /root/nems/nems-admin/build/nems-debpack/nems-www
mv /root/nems/nems-admin/build/nems-debpack/*.deb /root/nems/nems-admin/deb/
