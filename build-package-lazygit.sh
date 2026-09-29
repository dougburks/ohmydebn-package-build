#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

VERSION="0.65.1"
DESC="A simple terminal UI for git commands"
REPO="jesseduffield/lazygit"
URL="https://github.com/${REPO}"
PACKAGE_NAME="lazygit"

rm -f "${STAGING_DIR}"/${PACKAGE_NAME}_*.deb
enter_work_dir

echo
echo "Downloading amd64 binary"
download_verified "${REPO}" "v${VERSION}" lazygit_${VERSION}_linux_x86_64.tar.gz
tar zxvf lazygit_${VERSION}_linux_x86_64.tar.gz lazygit

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
  lazygit=/usr/bin/lazygit

echo
echo "Removing temp files"
rm -f lazygit lazygit_${VERSION}_linux_x86_64.tar.gz

echo
echo "Downloading arm64 binary"
download_verified "${REPO}" "v${VERSION}" lazygit_${VERSION}_linux_arm64.tar.gz
tar zxvf lazygit_${VERSION}_linux_arm64.tar.gz lazygit

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
  lazygit=/usr/bin/lazygit

echo
echo "Removing temp files"
rm -f lazygit lazygit_${VERSION}_linux_arm64.tar.gz

echo
echo "Including both packages in testing repo"
include_testing ${PACKAGE_NAME} \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_amd64.deb" \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_arm64.deb"

upload_testing
