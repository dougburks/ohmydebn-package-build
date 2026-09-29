#!/bin/bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

PACKAGE="ohmydebn-themes"
VERSION="4.0.0"
rm -f "${STAGING_DIR}"/${PACKAGE}_*.deb

fpm -s dir \
  -t deb \
  -n ${PACKAGE} \
  -v ${VERSION} \
  --package "${STAGING_DIR}/" \
  -a all \
  --maintainer "Doug Burks<doug.burks@example.com>" \
  --description "Themes for OhMyDebn" \
  --url "https://ohmydebn.org" \
  "${GIT_ROOT}/ohmydebn/themes/"=/usr/share/${PACKAGE}

echo
ls -alh "${STAGING_DIR}"/${PACKAGE}_*.deb
echo
include_testing ${PACKAGE} "${STAGING_DIR}/${PACKAGE}_${VERSION}_all.deb"

upload_testing
