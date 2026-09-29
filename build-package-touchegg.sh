#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

VERSION="2.0.17"
NAME="touchegg"
AUTHOR="JoseExposito"
REPO="${AUTHOR}/${NAME}"

rm -f "${STAGING_DIR}"/${NAME}*.deb

echo
URL="https://github.com/${REPO}/releases/download/${VERSION}/${NAME}_${VERSION}_amd64.deb"
echo "Downloading amd64 package from ${URL}"
wget -q -P "${STAGING_DIR}" "${URL}"

echo
URL="https://github.com/${REPO}/releases/download/${VERSION}/${NAME}_${VERSION}_arm64.deb"
echo "Downloading arm64 package from ${URL}"
wget -q -P "${STAGING_DIR}" "${URL}"

echo
echo "Including both packages in testing repo"
include_testing ${NAME} \
  "${STAGING_DIR}/${NAME}_${VERSION}_amd64.deb" \
  "${STAGING_DIR}/${NAME}_${VERSION}_arm64.deb"

upload_testing
