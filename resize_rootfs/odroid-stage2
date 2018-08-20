#!/bin/bash
ROOTFS=`ls -l /dev/disk/by-uuid/ | grep "e139ce78-9841-40fe-8823-96a304a09859" | awk '{print $11}' | sed "s/\.\.\/\.\.\///" | sed "s/p1//"`
resize2fs /dev/$ROOTFS
sed -i "s/\/root\/scripts\/resize//" /etc/rc.local
