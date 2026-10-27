#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# velo: a terminal speed test (latency, download, upload and bufferbloat)
# against the nearest speedtest.net servers, counting only its own test
# traffic. Offered beside OhMyDebn's own fast.com speed test.
VERSION="0.1.0"
# Package revision, for a rebuild of the same velo version. Reset it to 1
# for a new upstream VERSION.
REVISION="1"
NAME="velo"
DESC="Terminal speed test: latency, download, upload and bufferbloat"
REPO="bjarneo/${NAME}"
URL="https://github.com/${REPO}"
# v0.1.0 came out before the repository had a license, so its archives
# carry none. bjarneo added the MIT license afterwards; the package ships
# it from that commit, checked against its hash. A release whose archives
# include a LICENSE can ship that one instead.
LICENSE_COMMIT="0d745dfb4c468ef4d87415534f0a1a871ed9b29f"
LICENSE_SHA256="e484a1edfdc2082d6aec6e6ad2abb5bc786d9d3435063766b34df8861c108566"

rm -f "${STAGING_DIR}"/${NAME}_*.deb
enter_work_dir

wget -q -O LICENSE "https://raw.githubusercontent.com/${REPO}/${LICENSE_COMMIT}/LICENSE"
echo "${LICENSE_SHA256}  LICENSE" | sha256sum -c -

for ARCHITECTURE in amd64 arm64; do
  TARBALL="${NAME}_${VERSION}_linux_${ARCHITECTURE}.tar.gz"
  echo
  echo "Downloading ${ARCHITECTURE} release"
  download_verified "${REPO}" "v${VERSION}" "${TARBALL}"
  mkdir -p "${ARCHITECTURE}"
  tar -C "${ARCHITECTURE}" -xzf "${TARBALL}" "${NAME}"
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
    LICENSE=/usr/share/doc/${NAME}/copyright
done

echo
echo "Including both packages in testing repo"
include_testing ${NAME} \
  "${STAGING_DIR}/${NAME}_${VERSION}-${REVISION}_amd64.deb" \
  "${STAGING_DIR}/${NAME}_${VERSION}-${REVISION}_arm64.deb"

upload_testing
