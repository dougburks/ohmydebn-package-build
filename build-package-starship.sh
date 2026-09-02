#!/usr/bin/env bash

set -euo pipefail

VERSION="1.26.0"
NAME="starship"
DESC="The minimal, blazing-fast, and infinitely customizable prompt for any shell"
REPO="starship/starship"
URL="https://github.com/${REPO}"
PACKAGE_NAME="starship"

rm -f ${PACKAGE_NAME}*.deb

echo
echo "Downloading amd64 binary"
wget -q https://github.com/${REPO}/releases/download/v${VERSION}/starship-x86_64-unknown-linux-gnu.tar.gz
tar zxvf starship-x86_64-unknown-linux-gnu.tar.gz

echo
echo "Building amd64 package"
fpm -s dir -t deb \
  -n "${PACKAGE_NAME}" \
  -v "${VERSION}" \
  --architecture amd64 \
  --description "${DESC}" \
  --url "${URL}" \
  --license "ISC" \
  starship=/usr/bin/starship

echo
echo "Removing temp files"
rm -f starship starship-x86_64-unknown-linux-gnu.tar.gz

# No linux-gnu build is published for arm64 - only a musl one. That's fine to
# ship on a glibc system: musl builds are statically linked against musl
# itself, so they don't depend on the host's glibc at all.
echo
echo "Downloading arm64 binary"
wget -q https://github.com/${REPO}/releases/download/v${VERSION}/starship-aarch64-unknown-linux-musl.tar.gz
tar zxvf starship-aarch64-unknown-linux-musl.tar.gz

echo
echo "Building arm64 package"
fpm -s dir -t deb \
  -n "${PACKAGE_NAME}" \
  -v "${VERSION}" \
  --architecture arm64 \
  --description "${DESC}" \
  --url "${URL}" \
  --license "ISC" \
  starship=/usr/bin/starship

echo
echo "Removing temp files"
rm -f starship starship-aarch64-unknown-linux-musl.tar.gz

echo
echo "Including both packages in testing repo"
cd ohmydebn-packages-testing
reprepro remove trixie ${PACKAGE_NAME}
reprepro -b . includedeb trixie ../${PACKAGE_NAME}_${VERSION}_amd64.deb
reprepro -b . includedeb trixie ../${PACKAGE_NAME}_${VERSION}_arm64.deb
cd - >/dev/null
