#!/usr/bin/env bash
set -euo pipefail

VERSION="1.16.0"
NAME="cliamp"
DESC="Retro terminal music player inspired by Winamp"
URL="https://github.com/bjarneo/cliamp"

# Remove any previous packages
rm -f cliamp*.deb

echo
echo "Downloading amd64 binary from github releases"
curl -LO "https://github.com/bjarneo/cliamp/releases/download/v${VERSION}/cliamp-linux-amd64"
chmod +x cliamp-linux-amd64

echo
echo "Building amd64 package"
fpm -s dir -t deb \
  -n "${NAME}" \
  -v "${VERSION}" \
  --architecture amd64 \
  --depends yt-dlp \
  --deb-recommends ffmpeg \
  --description "${DESC}" \
  --url "${URL}" \
  --license "MIT" \
  cliamp-linux-amd64=/usr/bin/cliamp

echo
echo "Downloading arm64 binary from github releases"
curl -LO "https://github.com/bjarneo/cliamp/releases/download/v${VERSION}/cliamp-linux-arm64"
chmod +x cliamp-linux-arm64

echo
echo "Building arm64 package"
fpm -s dir -t deb \
  -n "${NAME}" \
  -v "${VERSION}" \
  --architecture arm64 \
  --depends yt-dlp \
  --deb-recommends ffmpeg \
  --description "${DESC}" \
  --url "${URL}" \
  --license "MIT" \
  cliamp-linux-arm64=/usr/bin/cliamp

# Clean up
rm -f cliamp-linux-*

echo
echo "Including both packages in testing repo"
cd ohmydebn-packages-testing
reprepro remove trixie ${NAME}
reprepro -b . includedeb trixie ../${NAME}_${VERSION}_amd64.deb
reprepro -b . includedeb trixie ../${NAME}_${VERSION}_arm64.deb
cd - >/dev/null
