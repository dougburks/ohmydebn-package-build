#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

VERSION="1.26.0"
DESC="The minimal, blazing-fast, and infinitely customizable prompt for any shell"
REPO="starship/starship"
URL="https://github.com/${REPO}"
PACKAGE_NAME="starship"

rm -f "${STAGING_DIR}"/${PACKAGE_NAME}*.deb
enter_work_dir

echo
echo "Downloading amd64 binary"
download_verified "${REPO}" "v${VERSION}" starship-x86_64-unknown-linux-gnu.tar.gz
tar zxvf starship-x86_64-unknown-linux-gnu.tar.gz

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
  --license "ISC" \
  starship=/usr/bin/starship

echo
echo "Removing temp files"
rm -f starship starship-x86_64-unknown-linux-gnu.tar.gz

# No linux-gnu build is published for arm64 - only a musl one. That's fine to
# ship on a glibc system: musl builds are statically linked against musl
# itself, so they don't depend on the host's glibc at all.
echo
echo "Downloading arm64 binary"
download_verified "${REPO}" "v${VERSION}" starship-aarch64-unknown-linux-musl.tar.gz
tar zxvf starship-aarch64-unknown-linux-musl.tar.gz

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
  --license "ISC" \
  starship=/usr/bin/starship

echo
echo "Removing temp files"
rm -f starship starship-aarch64-unknown-linux-musl.tar.gz

echo
echo "Including both packages in testing repo"
include_testing ${PACKAGE_NAME} \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_amd64.deb" \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_arm64.deb"

upload_testing
