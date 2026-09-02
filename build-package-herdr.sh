#!/usr/bin/env bash
set -euo pipefail

VERSION="0.8.2"
NAME="herdr"
DESC="The runtime your coding agents live on"
REPO="herdrdev/herdr"
URL="https://github.com/${REPO}"
PACKAGE_NAME="herdr"

rm -f ${PACKAGE_NAME}_*.deb

echo
echo "Downloading amd64 binary"
wget -q https://github.com/${REPO}/releases/download/v${VERSION}/herdr-linux-x86_64 -O herdr
chmod +x herdr

echo
echo "Building amd64 package"
fpm -s dir -t deb \
  -n "${PACKAGE_NAME}" \
  -v "${VERSION}" \
  --architecture amd64 \
  --description "${DESC}" \
  --url "${URL}" \
  --license "Apache-2.0" \
  herdr=/usr/bin/herdr

echo
echo "Removing temp files"
rm -f herdr

echo
echo "Downloading arm64 binary"
wget -q https://github.com/${REPO}/releases/download/v${VERSION}/herdr-linux-aarch64 -O herdr
chmod +x herdr

echo
echo "Building arm64 package"
fpm -s dir -t deb \
  -n "${PACKAGE_NAME}" \
  -v "${VERSION}" \
  --architecture arm64 \
  --description "${DESC}" \
  --url "${URL}" \
  --license "Apache-2.0" \
  herdr=/usr/bin/herdr

echo
echo "Removing temp files"
rm -f herdr

echo
echo "Including both packages in testing repo"
cd ohmydebn-packages-testing
reprepro remove trixie ${PACKAGE_NAME}
reprepro -b . includedeb trixie ../${PACKAGE_NAME}_${VERSION}_amd64.deb
reprepro -b . includedeb trixie ../${PACKAGE_NAME}_${VERSION}_arm64.deb
cd - >/dev/null
