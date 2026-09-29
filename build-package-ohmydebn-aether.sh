#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

VERSION="4.31.1"
NAME="aether"
AUTHOR="omacom"
DESC="Desktop theming application"
PACKAGE_NAME="ohmydebn-${NAME}"
REPO="${AUTHOR}/${NAME}"
URL="https://github.com/${REPO}"

rm -f "${STAGING_DIR}"/${PACKAGE_NAME}*.deb
enter_work_dir

for ARCHITECTURE in amd64 arm64; do
  echo
  echo "Downloading ${ARCHITECTURE} binary"
  download_verified "${REPO}" "v${VERSION}" ${NAME}-linux-${ARCHITECTURE}
  chmod +x ${NAME}-linux-${ARCHITECTURE}

  echo
  echo "Building ${ARCHITECTURE} package"
  fpm -s dir -t deb \
    --maintainer "Doug Burks<doug.burks@example.com>" \
    -n "${PACKAGE_NAME}" \
    -v "${VERSION}" \
    --package "${STAGING_DIR}/" \
    --architecture ${ARCHITECTURE} \
    --description "${DESC}" \
    --url "${URL}" \
    --license "MIT" \
    -d libwebkit2gtk-4.1-0 \
    -d libgtk-3-0 \
    -d libgtk-layer-shell0 \
    -d gstreamer1.0-plugins-good \
    -d ffmpeg \
    "${BUILD_DIR}/li.oever.aether.url-handler.desktop"=/usr/share/applications/li.oever.aether.url-handler.desktop \
    ${NAME}-linux-${ARCHITECTURE}=/usr/share/aether/${NAME}

  echo
  echo "Removing ${ARCHITECTURE} temp file"
  rm -f ${NAME}-linux-${ARCHITECTURE}
done

echo
echo "Including both packages in testing repo"
include_testing ${PACKAGE_NAME} \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_amd64.deb" \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_arm64.deb"

upload_testing
