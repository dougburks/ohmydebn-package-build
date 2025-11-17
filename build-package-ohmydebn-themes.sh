#!/bin/bash

PACKAGE="ohmydebn-themes"
VERSION="1.0.0"
rm -f ${PACKAGE}_*.deb

fpm -s dir \
  -t deb \
  -n ${PACKAGE} \
  -v ${VERSION} \
  -a all \
  --maintainer "Doug Burks<doug.burks@example.com>" \
  --description "Themes for OhMyDebn" \
  --url "https://ohmydebn.org" \
  ~/git/ohmydebn/themes/=/usr/share/${PACKAGE}

echo
ls -alh ${PACKAGE}_*.deb
echo
cd ohmydebn-packages-testing
reprepro remove trixie ${PACKAGE}
reprepro -b . includedeb trixie ../${PACKAGE}_${VERSION}_all.deb
cd - >/dev/null
