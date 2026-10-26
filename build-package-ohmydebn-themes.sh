#!/bin/bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

PACKAGE="ohmydebn-themes"
VERSION="4.0.0"
# Bumped whenever the same version is rebuilt with changes, so apt
# upgrades existing installs. 1: files no longer group-writable. 2: intros
# for the OhMyDebn theme's salty_mountains and yosemite backgrounds
# (rendered by a script since removed). 3: those intros start on
# the background instead of black. 4: the light arriving and a shimmer,
# instead of the grin. 5: no intros: ohmydebn-theme-intro-play now draws
# that light intro live for any background without a clip of its own.
REVISION="5"
rm -f "${STAGING_DIR}"/${PACKAGE}_*.deb
stage_checkout "${GIT_ROOT}/ohmydebn/themes" themes

fpm -s dir \
  -t deb \
  -n ${PACKAGE} \
  -v ${VERSION} \
  --iteration ${REVISION} \
  --package "${STAGING_DIR}/" \
  -a all \
  --maintainer "Doug Burks <https://github.com/dougburks/ohmydebn>" \
  --description "Themes for OhMyDebn" \
  --url "https://ohmydebn.org" \
  "${STAGED_DIR}/"=/usr/share/${PACKAGE}

echo
ls -alh "${STAGING_DIR}"/${PACKAGE}_*.deb
echo
include_testing ${PACKAGE} "${STAGING_DIR}/${PACKAGE}_${VERSION}-${REVISION}_all.deb"

upload_testing
