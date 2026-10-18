#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

VERSION="4.32.0"
# Package revision, for a rebuild of the same Aether version. Reset it to 1
# for a new upstream VERSION. 1: rebuilt without group write on its files
# (built before common.sh's umask, they were group-writable once installed).
REVISION="1"
NAME="aether"
AUTHOR="omacom"
DESC="Desktop theming application"
PACKAGE_NAME="ohmydebn-${NAME}"
REPO="${AUTHOR}/${NAME}"
URL="https://github.com/${REPO}"

rm -f "${STAGING_DIR}"/${PACKAGE_NAME}*.deb
enter_work_dir

# The URL handler comes from this checkout, which keeps the checkout's own
# mode (group-writable under a desktop's umask), so it's packaged from a
# copy with the mode it should have.
install -m 0644 "${BUILD_DIR}/li.oever.aether.url-handler.desktop" li.oever.aether.url-handler.desktop

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
    --iteration "${REVISION}" \
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
    li.oever.aether.url-handler.desktop=/usr/share/applications/li.oever.aether.url-handler.desktop \
    ${NAME}-linux-${ARCHITECTURE}=/usr/share/aether/${NAME}

  echo
  echo "Removing ${ARCHITECTURE} temp file"
  rm -f ${NAME}-linux-${ARCHITECTURE}
done

echo
echo "Including both packages in testing repo"
include_testing ${PACKAGE_NAME} \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}-${REVISION}_amd64.deb" \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}-${REVISION}_arm64.deb"

upload_testing
