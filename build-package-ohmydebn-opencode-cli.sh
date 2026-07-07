#!/usr/bin/env bash

set -euo pipefail

VERSION="1.17.14"
NAME="opencode"
DESC="The open source AI coding agent"
REPO="anomalyco/${NAME}"
URL="https://github.com/${REPO}"
PACKAGE_NAME="ohmydebn-opencode-cli"

rm -f ${PACKAGE_NAME}*.deb

echo
echo "Downloading amd64 binary"
wget -q https://github.com/anomalyco/opencode/releases/download/v${VERSION}/opencode-linux-x64.tar.gz
tar zxvf opencode-linux-x64.tar.gz

echo
echo "Building amd64 package"
fpm -s dir -t deb \
  -n "${PACKAGE_NAME}" \
  -v "${VERSION}" \
  --architecture amd64 \
  --description "${DESC}" \
  --url "${URL}" \
  --license "MIT" \
  opencode=/usr/bin/opencode-cli

echo
echo "Removing temp files"
rm -f opencode ${NAME}-linux-x64.tar.gz

echo
echo "Downloading arm64 binary"
wget -q https://github.com/anomalyco/opencode/releases/download/v${VERSION}/opencode-linux-arm64.tar.gz
tar zxvf opencode-linux-arm64.tar.gz

echo
echo "Building arm64 package"
fpm -s dir -t deb \
  -n "${PACKAGE_NAME}" \
  -v "${VERSION}" \
  --architecture arm64 \
  --description "${DESC}" \
  --url "${URL}" \
  --license "MIT" \
  opencode=/usr/bin/opencode-cli

echo
echo "Removing temp files"
rm -f opencode ${NAME}-linux-arm64.tar.gz

echo
echo "Including both packages in testing repo"
cd ohmydebn-packages-testing
reprepro remove trixie ${PACKAGE_NAME}
reprepro -b . includedeb trixie ../${PACKAGE_NAME}_${VERSION}_amd64.deb
reprepro -b . includedeb trixie ../${PACKAGE_NAME}_${VERSION}_arm64.deb
cd - >/dev/null
