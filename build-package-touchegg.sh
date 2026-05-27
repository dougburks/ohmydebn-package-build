#!/usr/bin/env bash

set -euo pipefail

VERSION="2.0.17"
NAME="touchegg"
DESC="Linux multi-touch gesture recognizer"
AUTHOR="JoseExposito"
REPO="${AUTHOR}/${NAME}"

rm -f ${NAME}*.deb

echo
URL="https://github.com/${REPO}/releases/download/${VERSION}/${NAME}_${VERSION}_amd64.deb"
echo "Downloading amd64 package from ${URL}"
wget -q "${URL}"

echo
URL="https://github.com/${REPO}/releases/download/${VERSION}/${NAME}_${VERSION}_arm64.deb"
echo "Downloading arm64 package from ${URL}"
wget -q "${URL}"

echo
echo "Including both packages in testing repo"
cd ohmydebn-packages-testing
reprepro remove trixie ${NAME}
reprepro -b . includedeb trixie ../${NAME}_${VERSION}_amd64.deb
reprepro -b . includedeb trixie ../${NAME}_${VERSION}_arm64.deb
cd - >/dev/null
