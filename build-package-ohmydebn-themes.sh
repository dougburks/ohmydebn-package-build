#!/bin/bash

PACKAGE="ohmydebn-themes"
VERSION="1.0.0"
rm -f ${PACKAGE}_*.deb

fpm -s dir \
  -t deb \
  -n ${PACKAGE} \
  -v $VERSION \
  -a all \
  --maintainer "Doug Burks<doug.burks@example.com>" \
  --description "Themes for OhMyDebn" \
  --url “https://ohmydebn.org” \
  -x opt/ohmydebn/.git \
  ~/git/ohmydebn/themes/=/opt/${PACKAGE}

echo
ls -alh *.deb
echo
cd ohmydebn-packages-testing
reprepro remove trixie ${PACKAGE}
reprepro -b . includedeb trixie ../${PACKAGE}_${VERSION}_all.deb
git add -A
git commit -m "update ${PACKAGE} package"
git push
cd - >/dev/null
