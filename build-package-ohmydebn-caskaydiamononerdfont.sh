#!/bin/bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

PACKAGE="ohmydebn-caskaydiamononerdfont"
VERSION="3.4.0"
rm -f "${STAGING_DIR}"/${PACKAGE}_*.deb

fpm -s dir \
  -t deb \
  -n ${PACKAGE} \
  -v ${VERSION} \
  --package "${STAGING_DIR}/" \
  -a all \
  --maintainer "Doug Burks<doug.burks@example.com>" \
  --description "Caskaydia Mono Nerd Font packaged for OhMyDebn" \
  --url "https://ohmydebn.org" \
  -x usr/share/${PACKAGE}/.git \
  -x usr/share/${PACKAGE}/.github \
  "${GIT_ROOT}/caskaydiamononerdfont/"=/usr/share/fonts/truetype/${PACKAGE}

echo
ls -alh "${STAGING_DIR}"/${PACKAGE}_*.deb
echo
include_testing ${PACKAGE} "${STAGING_DIR}/${PACKAGE}_${VERSION}_all.deb"

upload_testing
