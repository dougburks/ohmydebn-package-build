#!/bin/bash

PACKAGE="ohmydebn-templates"
VERSION="1.0.0"
rm -f ${PACKAGE}_*.deb

fpm -s dir \
  -t deb \
  -n ${PACKAGE} \
  -v ${VERSION} \
  -a all \
  --maintainer "Doug Burks<doug.burks@example.com>" \
  --description "Theme templates for Cinnamon desktop" \
  --url "https://ohmydebn.org" \
  -x usr/share/ohmydebn-templates/.git \
  ~/git/ohmydebn-templates/=/usr/share/ohmydebn-templates

echo
ls -alh ${PACKAGE}_*.deb
echo
cd ohmydebn-packages-testing
reprepro remove trixie ${PACKAGE}
reprepro -b . includedeb trixie ../${PACKAGE}_${VERSION}_all.deb
cd - >/dev/null
