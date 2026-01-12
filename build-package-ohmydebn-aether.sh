#!/bin/bash

PACKAGE="ohmydebn-aether"
VERSION="2.20.3"
rm -f ${PACKAGE}_*.deb

fpm -s dir \
  -t deb \
  -n ${PACKAGE} \
  -v ${VERSION} \
  -a all \
  --maintainer "Doug Burks<doug.burks@example.com>" \
  --description "Aether theme builder packaged for OhMyDebn" \
  --url "https://ohmydebn.org" \
  -x usr/share/${PACKAGE}/.git \
  -x usr/share/${PACKAGE}/.github \
  ~/git/aether/=/usr/share/${PACKAGE}

echo
ls -alh ${PACKAGE}_*.deb
echo
cd ohmydebn-packages-testing
reprepro remove trixie ${PACKAGE}
reprepro -b . includedeb trixie ../${PACKAGE}_${VERSION}_all.deb
cd - >/dev/null
