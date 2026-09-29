#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

VERSION="1.17.0"
AUTHOR="localsend"
NAME="localsend"
REPO="${AUTHOR}/${NAME}"

rm -f "${STAGING_DIR}"/LocalSend*.deb

echo
URL="https://github.com/${REPO}/releases/download/v${VERSION}/LocalSend-${VERSION}-linux-x86-64.deb"
echo "Downloading amd64 package from ${URL}"
wget -q -P "${STAGING_DIR}" "${URL}"

echo
URL="https://github.com/${REPO}/releases/download/v${VERSION}/LocalSend-${VERSION}-linux-arm-64.deb"
echo "Downloading arm64 package from ${URL}"
wget -q -P "${STAGING_DIR}" "${URL}"

echo
echo "Including both packages in testing repo"
include_testing ${NAME} \
  "${STAGING_DIR}/LocalSend-${VERSION}-linux-x86-64.deb" \
  "${STAGING_DIR}/LocalSend-${VERSION}-linux-arm-64.deb"

upload_testing
