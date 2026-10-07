#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

VERSION="1.18.2"
AUTHOR="localsend"
NAME="localsend"
REPO="${AUTHOR}/${NAME}"

rm -f "${STAGING_DIR}"/LocalSend*.deb
enter_work_dir

# Upstream's own .debs are published as-is, so each one is checked against
# the sha256 GitHub publishes for it, then moved into staging.
for ASSET in "LocalSend-${VERSION}-linux-x86-64.deb" "LocalSend-${VERSION}-linux-arm-64.deb"; do
  echo
  echo "Downloading ${ASSET}"
  download_verified "${REPO}" "v${VERSION}" "${ASSET}"
  mv "${ASSET}" "${STAGING_DIR}/"
done

echo
echo "Including both packages in testing repo"
include_testing ${NAME} \
  "${STAGING_DIR}/LocalSend-${VERSION}-linux-x86-64.deb" \
  "${STAGING_DIR}/LocalSend-${VERSION}-linux-arm-64.deb"

upload_testing
