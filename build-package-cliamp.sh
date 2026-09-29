#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

VERSION="2.3.0"
NAME="cliamp"
DESC="Retro terminal music player inspired by Winamp"
REPO="bjarneo/${NAME}"
URL="https://github.com/${REPO}"

rm -f "${STAGING_DIR}"/${NAME}*.deb
enter_work_dir

echo
echo "Downloading amd64 binary"
download_verified "${REPO}" "v${VERSION}" ${NAME}-linux-amd64
chmod +x ${NAME}-linux-amd64

echo
echo "Downloading arm64 binary"
download_verified "${REPO}" "v${VERSION}" ${NAME}-linux-arm64
chmod +x ${NAME}-linux-arm64

echo
echo "Building amd64 package"
fpm -s dir -t deb \
  --maintainer "Doug Burks<doug.burks@example.com>" \
  -n "${NAME}" \
  -v "${VERSION}" \
  --package "${STAGING_DIR}/" \
  --architecture amd64 \
  --depends libasound2-plugins \
  --depends yt-dlp \
  --deb-recommends ffmpeg \
  --description "${DESC}" \
  --url "${URL}" \
  --license "MIT" \
  cliamp-linux-amd64=/usr/bin/cliamp

echo
echo "Building arm64 package"
fpm -s dir -t deb \
  --maintainer "Doug Burks<doug.burks@example.com>" \
  -n "${NAME}" \
  -v "${VERSION}" \
  --package "${STAGING_DIR}/" \
  --architecture arm64 \
  --depends libasound2-plugins \
  --depends yt-dlp \
  --deb-recommends ffmpeg \
  --description "${DESC}" \
  --url "${URL}" \
  --license "MIT" \
  cliamp-linux-arm64=/usr/bin/cliamp

echo
echo "Removing temp files"
rm -f ${NAME}-linux-amd64 ${NAME}-linux-arm64

echo
echo "Including both packages in testing repo"
include_testing ${NAME} \
  "${STAGING_DIR}/${NAME}_${VERSION}_amd64.deb" \
  "${STAGING_DIR}/${NAME}_${VERSION}_arm64.deb"

upload_testing
