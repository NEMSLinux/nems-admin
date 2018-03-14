#!/bin/bash
ip=$(/usr/bin/nems-info ip)
#dialog --infobox "$ip" 3 34 ; sleep 5
echo $ip
