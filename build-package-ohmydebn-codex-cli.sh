#!/usr/bin/env bash

set -euo pipefail

VERSION="0.155.1"
NAME="codex"
AUTHOR="openai"
DESC="Lightweight coding agent that runs in your terminal"
PACKAGE_NAME="ohmydebn-codex-cli"
REPO="${AUTHOR}/${NAME}"
URL="https://github.com/${REPO}"
# Codex tags releases as rust-vX.Y.Z (the old TypeScript CLI used plain vX.Y.Z).
TAG="rust-v${VERSION}"

rm -f ${PACKAGE_NAME}*.deb

# Each release ships a bare codex-<triple>.tar.gz (single binary) and a
# codex-package-<triple>.tar.gz. We want the latter: it's the layout the
# official standalone installer (chatgpt.com/codex/install.sh) unpacks,
# with bin/codex, bin/codex-code-mode-host, codex-path/rg and
# codex-resources/{bwrap,zsh}. Codex locates those helpers relative to its
# own resolved executable path, so the directory must be installed intact
# (as with Pi, under /usr/lib/${PACKAGE_NAME}/) rather than as a lone
# binary in /usr/bin like OpenCode. Shipping the bundled bwrap also means
# no Depends on Debian's bubblewrap - Codex only falls back to a system
# bwrap on PATH when the bundled one is missing.
declare -A GH_ARCH=(
  [amd64]="x86_64"
  [arm64]="aarch64"
)

for ARCHITECTURE in amd64 arm64; do
  TRIPLE="${GH_ARCH[${ARCHITECTURE}]}-unknown-linux-musl"
  TARBALL="${NAME}-package-${TRIPLE}.tar.gz"

  echo
  echo "Downloading ${ARCHITECTURE} release"
  wget -q "https://github.com/${REPO}/releases/download/${TAG}/${TARBALL}"
  wget -q "https://github.com/${REPO}/releases/download/${TAG}/codex-package_SHA256SUMS"
  sha256sum --check --ignore-missing codex-package_SHA256SUMS
  mkdir -p ${NAME}
  tar zxf ${TARBALL} -C ${NAME}

  echo
  echo "Building ${ARCHITECTURE} package"
  fpm -s dir -t deb \
    -n "${PACKAGE_NAME}" \
    -v "${VERSION}" \
    --architecture ${ARCHITECTURE} \
    --description "${DESC}" \
    --url "${URL}" \
    --license "Apache-2.0" \
    ${NAME}/=/usr/lib/${PACKAGE_NAME}/

  echo
  echo "Removing ${ARCHITECTURE} temp files"
  rm -rf ${NAME} ${TARBALL} codex-package_SHA256SUMS
done

echo
echo "Including both packages in testing repo"
cd ohmydebn-packages-testing
reprepro remove trixie ${PACKAGE_NAME}
reprepro -b . includedeb trixie ../${PACKAGE_NAME}_${VERSION}_amd64.deb
reprepro -b . includedeb trixie ../${PACKAGE_NAME}_${VERSION}_arm64.deb
cd - >/dev/null
