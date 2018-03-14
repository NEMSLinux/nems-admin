#!/bin/bash
mkdir /etc/systemd/system/getty@tty1.service.d
systemctl disable getty@tty1.service
systemctl stop getty@tty1.service
echo "
[Service]
ExecStart=
ExecStart=-/usr/bin/top
StandardInput=tty
StandardOutput=tty
"> /etc/systemd/system/getty@tty1.service.d/override.conf
systemctl daemon-reload
systemctl enable getty@tty1.service
systemctl start getty@tty1.service
