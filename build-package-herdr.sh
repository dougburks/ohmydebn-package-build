#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

VERSION="0.9.3"
DESC="The runtime your coding agents live on"
REPO="herdrdev/herdr"
URL="https://github.com/${REPO}"
PACKAGE_NAME="herdr"

rm -f "${STAGING_DIR}"/${PACKAGE_NAME}_*.deb
enter_work_dir

echo
echo "Downloading amd64 binary"
download_verified "${REPO}" "v${VERSION}" herdr-linux-x86_64
mv herdr-linux-x86_64 herdr
chmod +x herdr

echo
echo "Building amd64 package"
fpm -s dir -t deb \
  --maintainer "Doug Burks<doug.burks@example.com>" \
  -n "${PACKAGE_NAME}" \
  -v "${VERSION}" \
  --package "${STAGING_DIR}/" \
  --architecture amd64 \
  --description "${DESC}" \
  --url "${URL}" \
  --license "Apache-2.0" \
  herdr=/usr/bin/herdr

echo
echo "Removing temp files"
rm -f herdr

echo
echo "Downloading arm64 binary"
download_verified "${REPO}" "v${VERSION}" herdr-linux-aarch64
mv herdr-linux-aarch64 herdr
chmod +x herdr

echo
echo "Building arm64 package"
fpm -s dir -t deb \
  --maintainer "Doug Burks<doug.burks@example.com>" \
  -n "${PACKAGE_NAME}" \
  -v "${VERSION}" \
  --package "${STAGING_DIR}/" \
  --architecture arm64 \
  --description "${DESC}" \
  --url "${URL}" \
  --license "Apache-2.0" \
  herdr=/usr/bin/herdr

echo
echo "Removing temp files"
rm -f herdr

echo
echo "Including both packages in testing repo"
include_testing ${PACKAGE_NAME} \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_amd64.deb" \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_arm64.deb"

upload_testing
