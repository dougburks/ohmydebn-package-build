#!/usr/bin/env bash

set -euo pipefail

VERSION="1.27.8"
NAME="cliamp"
DESC="Retro terminal music player inspired by Winamp"
REPO="bjarneo/${NAME}"
URL="https://github.com/${REPO}"

rm -f ${NAME}*.deb

echo
echo "Downloading amd64 binary"
wget -q -O ${NAME}-linux-amd64 "https://github.com/${REPO}/releases/download/v${VERSION}/${NAME}-linux-amd64"
chmod +x ${NAME}-linux-amd64

echo
echo "Downloading arm64 binary"
wget -q -O ${NAME}-linux-arm64 "https://github.com/${REPO}/releases/download/v${VERSION}/${NAME}-linux-arm64"
chmod +x ${NAME}-linux-arm64

echo
echo "Building amd64 package"
fpm -s dir -t deb \
  -n "${NAME}" \
  -v "${VERSION}" \
  --architecture amd64 \
  --depends libasound2-plugins \
  --depends yt-dlp \
  --deb-recommends ffmpeg \
  --description "${DESC}" \
  --url "${URL}" \
  --license "MIT" \
  cliamp-linux-amd64=/usr/bin/cliamp

echo
echo "Building arm64 package"
fpm -s dir -t deb \
  -n "${NAME}" \
  -v "${VERSION}" \
  --architecture arm64 \
  --depends libasound2-plugins \
  --depends yt-dlp \
  --deb-recommends ffmpeg \
  --description "${DESC}" \
  --url "${URL}" \
  --license "MIT" \
  cliamp-linux-arm64=/usr/bin/cliamp

echo
echo "Removing temp files"
rm -f ${NAME}-linux-amd64 ${NAME}-linux-arm64

echo
echo "Including both packages in testing repo"
cd ohmydebn-packages-testing
reprepro remove trixie ${NAME}
reprepro -b . includedeb trixie ../${NAME}_${VERSION}_amd64.deb
reprepro -b . includedeb trixie ../${NAME}_${VERSION}_arm64.deb
cd - >/dev/null
