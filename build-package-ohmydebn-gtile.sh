#!/bin/bash

PACKAGE="ohmydebn-gtile"
SOURCE_DIR=~/git/gTile-OhMyDebn
VERSION=$(jq -r '.version' ${SOURCE_DIR}/metadata.json)
rm -f ${PACKAGE}_*.deb

fpm -s dir \
  -t deb \
  -n ${PACKAGE} \
  -v ${VERSION} \
  -a all \
  --maintainer "Doug Burks<doug.burks@example.com>" \
  --description "gtile-OhMyDebn extension for Cinnamon desktop" \
  --url "https://ohmydebn.org" \
  -x usr/share/cinnamon/extensions/gTile@OhMyDebn/.git \
  ${SOURCE_DIR}/=/usr/share/cinnamon/extensions/gTile@OhMyDebn

echo
ls -alh ${PACKAGE}_*.deb
echo
cd ohmydebn-packages-testing
reprepro remove trixie ${PACKAGE}
reprepro -b . includedeb trixie ../${PACKAGE}_${VERSION}_all.deb
cd - >/dev/null
