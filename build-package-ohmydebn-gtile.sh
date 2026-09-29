#!/bin/bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

PACKAGE="ohmydebn-gtile"
SOURCE_DIR="${GIT_ROOT}/gTile-OhMyDebn"
VERSION=$(jq -r '.version' "${SOURCE_DIR}/metadata.json")
rm -f "${STAGING_DIR}"/${PACKAGE}_*.deb

fpm -s dir \
  -t deb \
  -n ${PACKAGE} \
  -v ${VERSION} \
  --package "${STAGING_DIR}/" \
  -a all \
  --maintainer "Doug Burks<doug.burks@example.com>" \
  --description "gtile-OhMyDebn extension for Cinnamon desktop" \
  --url "https://ohmydebn.org" \
  -x usr/share/cinnamon/extensions/gTile@OhMyDebn/.git \
  "${SOURCE_DIR}/"=/usr/share/cinnamon/extensions/gTile@OhMyDebn

echo
ls -alh "${STAGING_DIR}"/${PACKAGE}_*.deb
echo
include_testing ${PACKAGE} "${STAGING_DIR}/${PACKAGE}_${VERSION}_all.deb"

upload_testing
