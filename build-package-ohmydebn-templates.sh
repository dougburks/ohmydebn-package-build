#!/bin/bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

PACKAGE="ohmydebn-templates"
VERSION="1.0.0"
rm -f "${STAGING_DIR}"/${PACKAGE}_*.deb

fpm -s dir \
  -t deb \
  -n ${PACKAGE} \
  -v ${VERSION} \
  --package "${STAGING_DIR}/" \
  -a all \
  --maintainer "Doug Burks<doug.burks@example.com>" \
  --description "Theme templates for Cinnamon desktop" \
  --url "https://ohmydebn.org" \
  -x usr/share/ohmydebn-templates/.git \
  "${GIT_ROOT}/ohmydebn-templates/"=/usr/share/ohmydebn-templates

echo
ls -alh "${STAGING_DIR}"/${PACKAGE}_*.deb
echo
include_testing ${PACKAGE} "${STAGING_DIR}/${PACKAGE}_${VERSION}_all.deb"

upload_testing
