#!/bin/bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

PACKAGE="ohmydebn-themes"
VERSION="4.0.0"
# Bumped whenever the same version is rebuilt with changes, so apt
# upgrades existing installs. 1: files no longer group-writable.
REVISION="1"
rm -f "${STAGING_DIR}"/${PACKAGE}_*.deb
stage_checkout "${GIT_ROOT}/ohmydebn/themes" themes

fpm -s dir \
  -t deb \
  -n ${PACKAGE} \
  -v ${VERSION} \
  --iteration ${REVISION} \
  --package "${STAGING_DIR}/" \
  -a all \
  --maintainer "Doug Burks<doug.burks@example.com>" \
  --description "Themes for OhMyDebn" \
  --url "https://ohmydebn.org" \
  "${STAGED_DIR}/"=/usr/share/${PACKAGE}

echo
ls -alh "${STAGING_DIR}"/${PACKAGE}_*.deb
echo
include_testing ${PACKAGE} "${STAGING_DIR}/${PACKAGE}_${VERSION}-${REVISION}_all.deb"

upload_testing
