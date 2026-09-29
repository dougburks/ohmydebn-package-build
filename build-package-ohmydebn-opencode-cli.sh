#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

VERSION="1.18.33"
NAME="opencode"
DESC="The open source AI coding agent"
REPO="anomalyco/${NAME}"
URL="https://github.com/${REPO}"
PACKAGE_NAME="ohmydebn-opencode-cli"

rm -f "${STAGING_DIR}"/${PACKAGE_NAME}*.deb
enter_work_dir

echo
echo "Downloading amd64 binary"
download_verified "${REPO}" "v${VERSION}" opencode-linux-x64.tar.gz
tar zxvf opencode-linux-x64.tar.gz

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
  --license "MIT" \
  opencode=/usr/bin/opencode-cli

echo
echo "Removing temp files"
rm -f opencode ${NAME}-linux-x64.tar.gz

echo
echo "Downloading arm64 binary"
download_verified "${REPO}" "v${VERSION}" opencode-linux-arm64.tar.gz
tar zxvf opencode-linux-arm64.tar.gz

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
  --license "MIT" \
  opencode=/usr/bin/opencode-cli

echo
echo "Removing temp files"
rm -f opencode ${NAME}-linux-arm64.tar.gz

echo
echo "Including both packages in testing repo"
include_testing ${PACKAGE_NAME} \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_amd64.deb" \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_arm64.deb"

upload_testing
