#!/bin/bash

# Omarchy version currently has an alpha tag
#VERSION=$(cat ~/git/omarchy/version)
# so let's hardcode it for now:
VERSION="4.0.0"
PREFIX="ohmydebn-themes"
OMARCHY_THEMES_DIR=~/git/omarchy/themes

# Dynamically determine the list of themes from the omarchy themes directory
THEMES=()
for dir in "${OMARCHY_THEMES_DIR}"/*/; do
  THEMES+=("$(basename "$dir")")
done

# Create individual package for each omarchy theme
for THEME in "${THEMES[@]}"; do

  echo "Working on $THEME"
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
    ${OMARCHY_THEMES_DIR}/${THEME}=/usr/share/ohmydebn-themes/

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

DEPENDS=()
for THEME in "${THEMES[@]}"; do
  DEPENDS+=(-d "${PREFIX}-${THEME}")
done

fpm -s empty \
  -t deb \
  -n ${PACKAGE} \
  -v ${VERSION} \
  -a all \
  --maintainer "Doug Burks<doug.burks@example.com>" \
  --description "Themes from Omarchy packaged for OhMyDebn" \
  --url "https://ohmydebn.org" \
  "${DEPENDS[@]}"

echo
ls -alh ${PACKAGE}_*.deb
echo
cd ohmydebn-packages-testing
reprepro remove trixie ${PACKAGE}
reprepro -b . includedeb trixie ../${PACKAGE}_${VERSION}_all.deb
cd - >/dev/null
