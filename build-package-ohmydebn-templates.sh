#!/bin/bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

PACKAGE="ohmydebn-templates"
VERSION="1.0.0"
# Bumped whenever the same version is rebuilt with changes, so apt
# upgrades existing installs. 1: files no longer group-writable.
REVISION="1"
rm -f "${STAGING_DIR}"/${PACKAGE}_*.deb
stage_checkout "${GIT_ROOT}/ohmydebn-templates" ohmydebn-templates

fpm -s dir \
  -t deb \
  -n ${PACKAGE} \
  -v ${VERSION} \
  --iteration ${REVISION} \
  --package "${STAGING_DIR}/" \
  -a all \
  --maintainer "Doug Burks <https://github.com/dougburks/ohmydebn>" \
  --description "Theme templates for Cinnamon desktop" \
  --url "https://ohmydebn.org" \
  -x usr/share/ohmydebn-templates/.git \
  "${STAGED_DIR}/"=/usr/share/ohmydebn-templates

echo
ls -alh "${STAGING_DIR}"/${PACKAGE}_*.deb
echo
include_testing ${PACKAGE} "${STAGING_DIR}/${PACKAGE}_${VERSION}-${REVISION}_all.deb"

upload_testing
