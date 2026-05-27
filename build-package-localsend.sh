#!/usr/bin/env bash

set -euo pipefail

VERSION="1.17.0"
AUTHOR="localsend"
NAME="localsend"
REPO="${AUTHOR}/${NAME}"
DESC="An open-source cross-platform alternative to AirDrop"

rm -f LocalSend*.deb

echo
URL="https://github.com/${REPO}/releases/download/v${VERSION}/LocalSend-${VERSION}-linux-x86-64.deb"
echo "Downloading amd64 package from ${URL}"
wget -q "${URL}"

echo
URL="https://github.com/${REPO}/releases/download/v${VERSION}/LocalSend-${VERSION}-linux-arm-64.deb"
echo "Downloading arm64 package from ${URL}"
wget -q "${URL}"

echo
echo "Including both packages in testing repo"
cd ohmydebn-packages-testing
reprepro remove trixie ${NAME}
reprepro -b . includedeb trixie ../LocalSend-${VERSION}-linux-x86-64.deb
reprepro -b . includedeb trixie ../LocalSend-${VERSION}-linux-arm-64.deb
cd - >/dev/null
