#!/bin/bash

PACKAGE="ohmydebn-gtile"
VERSION="2.2.1"
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
  ~/git/gTile-OhMyDebn/=/usr/share/cinnamon/extensions/gTile@OhMyDebn

echo
ls -alh ${PACKAGE}_*.deb
echo
cd ohmydebn-packages-testing
reprepro remove trixie ${PACKAGE}
reprepro -b . includedeb trixie ../${PACKAGE}_${VERSION}_all.deb
cd - >/dev/null
