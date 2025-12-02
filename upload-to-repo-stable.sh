#!/bin/bash

cd ohmydebn-packages

for PACKAGE in mint-themes mint-x-icons ohmydebn-aether ohmydebn-caskaydiamononerdfont ohmydebn-gtile ohmydebn-themes-omarchy ohmydebn-themes ohmydebn; do
  reprepro remove trixie ${PACKAGE}
  reprepro -b . includedeb trixie ../${PACKAGE}_*
done

git add -A
git commit -m "update packages"
git push

cd - >/dev/null
