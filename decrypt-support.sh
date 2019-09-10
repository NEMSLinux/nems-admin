#!/bin/bash

if [[ $1 = "" ]] || [[ $2 = "" ]]; then
  echo Usage: $0 filename hwid
  exit
fi

mkdir support
/usr/bin/gpg --yes --batch --passphrase="$2" --decrypt $1 > support/support.tar.gz

if [[ -s support/support.tar.gz ]]; then
  cd support
  tar -xvzf support.tar.gz
  rm support.tar.gz
else
  echo Error decrypting file. Correct HWID?
fi
