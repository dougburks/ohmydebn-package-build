#!/usr/bin/env bash

set -euo pipefail

VERSION="4.8.2"
NAME="aether"
AUTHOR="bjarneo"
DESC="Desktop theming application"
PACKAGE_NAME="ohmydebn-${NAME}"
REPO="${AUTHOR}/${NAME}"
URL="https://github.com/${REPO}"

rm -f ${PACKAGE_NAME}*.deb

for ARCHITECTURE in amd64 arm64; do
  echo
  echo "Downloading ${ARCHITECTURE} binary"
  wget -q -O ${NAME}-linux-${ARCHITECTURE} "https://github.com/${REPO}/releases/download/v${VERSION}/${NAME}-linux-${ARCHITECTURE}"
  chmod +x ${NAME}-linux-${ARCHITECTURE}

  echo
  echo "Building ${ARCHITECTURE} package"
  fpm -s dir -t deb \
    -n "${PACKAGE_NAME}" \
    -v "${VERSION}" \
    --architecture ${ARCHITECTURE} \
    --description "${DESC}" \
    --url "${URL}" \
    --license "MIT" \
    -d libwebkit2gtk-4.1-0 \
    -d libgtk-3-0 \
    -d libgtk-layer-shell0 \
    -d gstreamer1.0-plugins-good \
    -d ffmpeg \
    ${NAME}-linux-${ARCHITECTURE}=/usr/share/aether/${NAME}

  echo
  echo "Removing ${ARCHITECTURE} temp file"
  rm -f ${NAME}-linux-${ARCHITECTURE}
done

echo
echo "Including both packages in testing repo"
cd ohmydebn-packages-testing
reprepro remove trixie ${PACKAGE_NAME}
reprepro -b . includedeb trixie ../${PACKAGE_NAME}_${VERSION}_amd64.deb
reprepro -b . includedeb trixie ../${PACKAGE_NAME}_${VERSION}_arm64.deb
cd - >/dev/null
