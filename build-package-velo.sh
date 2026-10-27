#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# velo: a terminal speed test (latency, download, upload and bufferbloat)
# against the nearest speedtest.net servers, counting only its own test
# traffic. Offered beside OhMyDebn's own fast.com speed test.
VERSION="0.1.1"
# Package revision, for a rebuild of the same velo version. Reset it to 1
# for a new upstream VERSION.
REVISION="1"
NAME="velo"
DESC="Terminal speed test: latency, download, upload and bufferbloat"
REPO="bjarneo/${NAME}"
URL="https://github.com/${REPO}"

rm -f "${STAGING_DIR}"/${NAME}_*.deb
enter_work_dir

for ARCHITECTURE in amd64 arm64; do
  TARBALL="${NAME}_${VERSION}_linux_${ARCHITECTURE}.tar.gz"
  echo
  echo "Downloading ${ARCHITECTURE} release"
  download_verified "${REPO}" "v${VERSION}" "${TARBALL}"
  mkdir -p "${ARCHITECTURE}"
  # The archive's LICENSE (MIT) is the package's copyright file.
  tar -C "${ARCHITECTURE}" -xzf "${TARBALL}" "${NAME}" LICENSE
  chmod 755 "${ARCHITECTURE}/${NAME}"

  echo
  echo "Building ${ARCHITECTURE} package"
  fpm -s dir -t deb \
    --maintainer "Doug Burks <https://github.com/dougburks/ohmydebn>" \
    -n "${NAME}" \
    -v "${VERSION}" \
    --iteration "${REVISION}" \
    --package "${STAGING_DIR}/" \
    --architecture "${ARCHITECTURE}" \
    --description "${DESC}" \
    --url "${URL}" \
    --license "MIT" \
    "${ARCHITECTURE}/${NAME}"=/usr/bin/${NAME} \
    "${ARCHITECTURE}/LICENSE"=/usr/share/doc/${NAME}/copyright
done

echo
echo "Including both packages in testing repo"
include_testing ${NAME} \
  "${STAGING_DIR}/${NAME}_${VERSION}-${REVISION}_amd64.deb" \
  "${STAGING_DIR}/${NAME}_${VERSION}-${REVISION}_arm64.deb"

upload_testing
