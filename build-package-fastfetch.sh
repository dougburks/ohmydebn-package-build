#!/usr/bin/env bash
set -euo pipefail

VERSION="2.67.1"
PACKAGE_NAME="fastfetch"
REPO="fastfetch-cli/fastfetch"

rm -f ${PACKAGE_NAME}_*.deb

echo
echo "Downloading amd64 .deb"
wget -q "https://github.com/${REPO}/releases/download/${VERSION}/fastfetch-linux-amd64.deb" \
  -O ${PACKAGE_NAME}_${VERSION}_amd64.deb

echo
echo "Downloading arm64 .deb"
wget -q "https://github.com/${REPO}/releases/download/${VERSION}/fastfetch-linux-aarch64.deb" \
  -O ${PACKAGE_NAME}_${VERSION}_arm64.deb

echo
echo "Including both packages in testing repo"
cd ohmydebn-packages-testing
reprepro remove trixie ${PACKAGE_NAME}
reprepro -b . includedeb trixie ../${PACKAGE_NAME}_${VERSION}_amd64.deb
reprepro -b . includedeb trixie ../${PACKAGE_NAME}_${VERSION}_arm64.deb
cd - >/dev/null
