#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

VERSION="2.69.0"
PACKAGE_NAME="fastfetch"
REPO="fastfetch-cli/fastfetch"

rm -f "${STAGING_DIR}"/${PACKAGE_NAME}_*.deb
enter_work_dir

echo
echo "Downloading amd64 .deb"
download_verified "${REPO}" "${VERSION}" fastfetch-linux-amd64.deb
mv fastfetch-linux-amd64.deb "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_amd64.deb"

echo
echo "Downloading arm64 .deb"
download_verified "${REPO}" "${VERSION}" fastfetch-linux-aarch64.deb
mv fastfetch-linux-aarch64.deb "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_arm64.deb"

echo
echo "Including both packages in testing repo"
include_testing ${PACKAGE_NAME} \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_amd64.deb" \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_arm64.deb"

upload_testing
