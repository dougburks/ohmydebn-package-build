#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

VERSION="0.99.1"
NAME="pi"
AUTHOR="earendil-works"
DESC="Coding agent CLI with read, bash, edit, write tools and session management"
PACKAGE_NAME="ohmydebn-pi-coding-agent"
REPO="${AUTHOR}/${NAME}"
URL="https://github.com/${REPO}"

rm -f "${STAGING_DIR}"/${PACKAGE_NAME}*.deb
enter_work_dir

declare -A GH_ARCH=(
  [amd64]="x64"
  [arm64]="arm64"
)

for ARCHITECTURE in amd64 arm64; do
  GHARCH="${GH_ARCH[${ARCHITECTURE}]}"

  echo
  echo "Downloading ${ARCHITECTURE} release"
  download_verified "${REPO}" "v${VERSION}" ${NAME}-linux-${GHARCH}.tar.gz
  tar zxf ${NAME}-linux-${GHARCH}.tar.gz

  echo
  echo "Building ${ARCHITECTURE} package"
  fpm -s dir -t deb \
    --maintainer "Doug Burks<doug.burks@example.com>" \
    -n "${PACKAGE_NAME}" \
    -v "${VERSION}" \
    --package "${STAGING_DIR}/" \
    --architecture ${ARCHITECTURE} \
    --description "${DESC}" \
    --url "${URL}" \
    --license "MIT" \
    ${NAME}/=/usr/lib/${PACKAGE_NAME}/

  echo
  echo "Removing ${ARCHITECTURE} temp files"
  rm -rf ${NAME} ${NAME}-linux-${GHARCH}.tar.gz
done

echo
echo "Including both packages in testing repo"
include_testing ${PACKAGE_NAME} \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_amd64.deb" \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_arm64.deb"

upload_testing
