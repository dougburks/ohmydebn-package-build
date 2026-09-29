#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

VERSION="2.0.2"
PACKAGE_NAME="gum"
REPO="charmbracelet/gum"

rm -f "${STAGING_DIR}"/${PACKAGE_NAME}_*.deb
enter_work_dir

echo
echo "Downloading amd64 .deb"
download_verified "${REPO}" "v${VERSION}" ${PACKAGE_NAME}_${VERSION}_amd64.deb
mv ${PACKAGE_NAME}_${VERSION}_amd64.deb "${STAGING_DIR}/"

echo
echo "Downloading arm64 .deb"
download_verified "${REPO}" "v${VERSION}" ${PACKAGE_NAME}_${VERSION}_arm64.deb
mv ${PACKAGE_NAME}_${VERSION}_arm64.deb "${STAGING_DIR}/"

echo
echo "Including both packages in testing repo"
include_testing ${PACKAGE_NAME} \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_amd64.deb" \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_arm64.deb"

upload_testing
