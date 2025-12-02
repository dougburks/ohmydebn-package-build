#!/bin/bash

PACKAGE="ohmydebn-caskaydiamononerdfontmono"
VERSION="3.4.0"
rm -f ${PACKAGE}_*.deb

fpm -s dir \
  -t deb \
  -n ${PACKAGE} \
  -v ${VERSION} \
  -a all \
  --maintainer "Doug Burks<doug.burks@example.com>" \
  --description "Caskaydia Mono Nerd Font Mono packaged for OhMyDebn" \
  --url "https://ohmydebn.org" \
  -x usr/share/${PACKAGE}/.git \
  -x usr/share/${PACKAGE}/.github \
  ~/git/caskaydiamononerdfontmono/=/usr/share/fonts/truetype/${PACKAGE}

echo
ls -alh ${PACKAGE}_*.deb
echo
cd ohmydebn-packages-testing
reprepro remove trixie ${PACKAGE}
reprepro -b . includedeb trixie ../${PACKAGE}_${VERSION}_all.deb
cd - >/dev/null
