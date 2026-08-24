#!/usr/bin/env bash

set -euo pipefail

VERSION="0.84.3"
NAME="pi"
AUTHOR="earendil-works"
DESC="Coding agent CLI with read, bash, edit, write tools and session management"
PACKAGE_NAME="ohmydebn-pi-coding-agent"
REPO="${AUTHOR}/${NAME}"
URL="https://github.com/${REPO}"

rm -f ${PACKAGE_NAME}*.deb

declare -A GH_ARCH=(
  [amd64]="x64"
  [arm64]="arm64"
)

for ARCHITECTURE in amd64 arm64; do
  GHARCH="${GH_ARCH[${ARCHITECTURE}]}"

  echo
  echo "Downloading ${ARCHITECTURE} release"
  wget -q "https://github.com/${REPO}/releases/download/v${VERSION}/${NAME}-linux-${GHARCH}.tar.gz"
  tar zxf ${NAME}-linux-${GHARCH}.tar.gz

  echo
  echo "Building ${ARCHITECTURE} package"
  fpm -s dir -t deb \
    -n "${PACKAGE_NAME}" \
    -v "${VERSION}" \
    --architecture ${ARCHITECTURE} \
    --description "${DESC}" \
    --url "${URL}" \
    --license "MIT" \
    ${NAME}/=/usr/lib/${PACKAGE_NAME}/

  echo
  echo "Removing ${ARCHITECTURE} temp files"
  rm -rf ${NAME} ${NAME}-linux-${GHARCH}.tar.gz
done

echo
echo "Including both packages in testing repo"
cd ohmydebn-packages-testing
reprepro remove trixie ${PACKAGE_NAME}
reprepro -b . includedeb trixie ../${PACKAGE_NAME}_${VERSION}_amd64.deb
reprepro -b . includedeb trixie ../${PACKAGE_NAME}_${VERSION}_arm64.deb
cd - >/dev/null
