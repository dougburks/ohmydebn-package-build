#!/bin/bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

PACKAGE="ohmydebn-caskaydiamononerdfont"
VERSION="3.5.1"
# All three variants of the font (Caskaydia Mono Nerd Font, its Mono and
# Propo versions) in one package. Up to 3.4.0 they were three packages, to
# keep each file small for GitHub Pages; this one takes over the other two
# (Replaces moves their files, Conflicts makes apt remove them).
OLD_PACKAGES=(ohmydebn-caskaydiamononerdfontmono ohmydebn-caskaydiamononerdfontpropo)
rm -f "${STAGING_DIR}"/${PACKAGE}_*.deb
# Their old debs too, so promoting staging to stable doesn't bring them back.
for OLD in "${OLD_PACKAGES[@]}"; do
  rm -f "${STAGING_DIR}"/${OLD}_*.deb
done
enter_work_dir

echo
echo "Downloading Nerd Fonts ${VERSION} CascadiaMono"
download_verified ryanoasis/nerd-fonts "v${VERSION}" CascadiaMono.tar.xz
mkdir -p fonts pkgroot
tar -xJf CascadiaMono.tar.xz -C fonts
# Twelve weights and styles (Regular to ExtraLight and their italics) of
# each of the three variants.
if [ "$(find fonts -maxdepth 1 -name 'CaskaydiaMonoNerdFont*-*.ttf' | wc -l)" -ne 36 ]; then
  echo "Expected 36 font files in CascadiaMono.tar.xz" >&2
  exit 1
fi
install -m 644 fonts/CaskaydiaMonoNerdFont*-*.ttf fonts/LICENSE fonts/README.md pkgroot/

TAKEOVER=()
for OLD in "${OLD_PACKAGES[@]}"; do
  TAKEOVER+=(--replaces "${OLD}" --conflicts "${OLD}")
done

fpm -s dir \
  -t deb \
  -n ${PACKAGE} \
  -v ${VERSION} \
  --package "${STAGING_DIR}/" \
  -a all \
  --maintainer "Doug Burks<doug.burks@example.com>" \
  --description "Caskaydia Mono Nerd Font (with its Mono and Propo variants) packaged for OhMyDebn" \
  --url "https://ohmydebn.org" \
  "${TAKEOVER[@]}" \
  pkgroot/=/usr/share/fonts/truetype/${PACKAGE}

echo
ls -alh "${STAGING_DIR}"/${PACKAGE}_*.deb
echo
include_testing ${PACKAGE} "${STAGING_DIR}/${PACKAGE}_${VERSION}_all.deb"
# The packages this one took over, so the repo stops offering them.
for OLD in "${OLD_PACKAGES[@]}"; do
  reprepro -b "${TESTING_REPO}" remove trixie "${OLD}"
done

upload_testing
