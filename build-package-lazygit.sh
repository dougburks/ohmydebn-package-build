#!/usr/bin/env bash
set -euo pipefail

VERSION="0.64.1"
NAME="lazygit"
DESC="A simple terminal UI for git commands"
REPO="jesseduffield/lazygit"
URL="https://github.com/${REPO}"
PACKAGE_NAME="lazygit"

rm -f ${PACKAGE_NAME}_*.deb

echo
echo "Downloading amd64 binary"
wget -q https://github.com/${REPO}/releases/download/v${VERSION}/lazygit_${VERSION}_linux_x86_64.tar.gz
tar zxvf lazygit_${VERSION}_linux_x86_64.tar.gz lazygit

echo
echo "Building amd64 package"
fpm -s dir -t deb \
  -n "${PACKAGE_NAME}" \
  -v "${VERSION}" \
  --architecture amd64 \
  --description "${DESC}" \
  --url "${URL}" \
  --license "MIT" \
  lazygit=/usr/bin/lazygit

echo
echo "Removing temp files"
rm -f lazygit lazygit_${VERSION}_linux_x86_64.tar.gz

echo
echo "Downloading arm64 binary"
wget -q https://github.com/${REPO}/releases/download/v${VERSION}/lazygit_${VERSION}_linux_arm64.tar.gz
tar zxvf lazygit_${VERSION}_linux_arm64.tar.gz lazygit

echo
echo "Building arm64 package"
fpm -s dir -t deb \
  -n "${PACKAGE_NAME}" \
  -v "${VERSION}" \
  --architecture arm64 \
  --description "${DESC}" \
  --url "${URL}" \
  --license "MIT" \
  lazygit=/usr/bin/lazygit

echo
echo "Removing temp files"
rm -f lazygit lazygit_${VERSION}_linux_arm64.tar.gz

echo
echo "Including both packages in testing repo"
cd ohmydebn-packages-testing
reprepro remove trixie ${PACKAGE_NAME}
reprepro -b . includedeb trixie ../${PACKAGE_NAME}_${VERSION}_amd64.deb
reprepro -b . includedeb trixie ../${PACKAGE_NAME}_${VERSION}_arm64.deb
cd - >/dev/null
