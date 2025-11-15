#!/bin/bash

PACKAGE="ohmydebn-aether"
VERSION="2.17.0"
rm -f ${PACKAGE}_*.deb

fpm -s dir \
  -t deb \
  -n ${PACKAGE} \
  -v $VERSION \
  -a all \
  --maintainer "Doug Burks<doug.burks@example.com>" \
  --description "Aether theme builder packaged for OhMyDebn" \
  --url “https://ohmydebn.org” \
  -x opt/aether/.git \
  ~/git/aether/=/opt/${PACKAGE}

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
