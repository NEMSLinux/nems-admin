#!/bin/bash

if [[ $1 = "" ]] || [[ $2 = "" ]]; then
  echo Usage: $0 filename hwid
  exit
fi

/usr/bin/gpg --yes --batch --passphrase="$2" --decrypt $1 > /tmp/support.tar.gz

if [[ -s /tmp/support.tar.gz ]]; then
  echo File saved to /tmp/support.tar.gz
else
  echo Error decrypting file. Correct HWID?
fi
