#!/bin/bash

VERSION=$(cat ~/git/omarchy/version)
PREFIX="ohmydebn-themes"

# Create individual package for each omarchy theme
for THEME in catppuccin catppuccin-latte ethereal everforest flexoki-light gruvbox hackerman kanagawa matte-black miasma nord osaka-jade ristretto rose-pine tokyo-night vantablack white; do

  PACKAGE="${PREFIX}-${THEME}"
  rm -f ${PACKAGE}_*.deb

  fpm -s dir \
    -t deb \
    -n ${PACKAGE} \
    -v ${VERSION} \
    -a all \
    --maintainer "Doug Burks<doug.burks@example.com>" \
    --description "${THEME} theme from Omarchy packaged for OhMyDebn" \
    --url "https://ohmydebn.org" \
    ~/git/omarchy/themes/${THEME}=/usr/share/ohmydebn-themes/

  echo
  ls -alh ${PACKAGE}_*.deb
  echo
  cd ohmydebn-packages-testing
  reprepro remove trixie ${PACKAGE}
  reprepro -b . includedeb trixie ../${PACKAGE}_${VERSION}_all.deb
  cd - >/dev/null

done

# Create the ohmydebn-themes-omarchy package that just contains the version file
PACKAGE="${PREFIX}-omarchy"
rm -f ${PACKAGE}_*.deb

fpm -s empty \
  -t deb \
  -n ${PACKAGE} \
  -v ${VERSION} \
  -a all \
  --maintainer "Doug Burks<doug.burks@example.com>" \
  --description "Themes from Omarchy packaged for OhMyDebn" \
  --url "https://ohmydebn.org" \
  -d ${PREFIX}-catppuccin \
  -d ${PREFIX}-catppuccin-latte \
  -d ${PREFIX}-ethereal \
  -d ${PREFIX}-everforest \
  -d ${PREFIX}-flexoki-light \
  -d ${PREFIX}-gruvbox \
  -d ${PREFIX}-hackerman \
  -d ${PREFIX}-kanagawa \
  -d ${PREFIX}-matte-black \
  -d ${PREFIX}-miasma \
  -d ${PREFIX}-nord \
  -d ${PREFIX}-osaka-jade \
  -d ${PREFIX}-ristretto \
  -d ${PREFIX}-rose-pine \
  -d ${PREFIX}-tokyo-night \
  -d ${PREFIX}-vantablack \
  -d ${PREFIX}-white

echo
ls -alh ${PACKAGE}_*.deb
echo
cd ohmydebn-packages-testing
reprepro remove trixie ${PACKAGE}
reprepro -b . includedeb trixie ../${PACKAGE}_${VERSION}_all.deb
cd - >/dev/null
