#!/usr/bin/env bash

# Unlike the other build-package-*.sh scripts, upstream does not publish
# release binaries (GitHub release assets are empty) and there is no
# crates.io package, so this builds from source with cargo instead of
# wget-ing a prebuilt binary.
#
# Prerequisites on the build machine:
#   rustup target add x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu
#   apt install gcc-aarch64-linux-gnu
#   (aarch64-linux-gnu-gcc must be on PATH as the arm64 linker)

set -euo pipefail

VERSION="0.3.1"
NAME="ttfx"
AUTHOR="omacom-io"
DESC="Terminal text effects as a single static binary"
REPO="${AUTHOR}/${NAME}"
URL="https://github.com/${REPO}"

rm -f ${NAME}*.deb
rm -rf ${NAME}-${VERSION}

echo
echo "Downloading source for v${VERSION}"
wget -q -O ${NAME}-${VERSION}.tar.gz "${URL}/archive/refs/tags/v${VERSION}.tar.gz"
tar zxf ${NAME}-${VERSION}.tar.gz
cd ${NAME}-${VERSION}

declare -A RUST_TARGET=(
  [amd64]="x86_64-unknown-linux-gnu"
  [arm64]="aarch64-unknown-linux-gnu"
)

for ARCHITECTURE in amd64 arm64; do
  TARGET="${RUST_TARGET[${ARCHITECTURE}]}"

  echo
  echo "Building ${ARCHITECTURE} binary (${TARGET})"
  if [ "${ARCHITECTURE}" = "arm64" ]; then
    export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc
  fi
  cargo build --release --locked --target "${TARGET}"

  BIN="target/${TARGET}/release/${NAME}"

  echo
  echo "Generating shell completions"
  "${BIN}" --print-completion bash >${NAME}.bash 2>/dev/null || true
  "${BIN}" --print-completion zsh >_${NAME} 2>/dev/null || true

  echo
  echo "Building ${ARCHITECTURE} package"
  fpm -s dir -t deb \
    -n "${NAME}" \
    -v "${VERSION}" \
    --architecture ${ARCHITECTURE} \
    --description "${DESC}" \
    --url "${URL}" \
    --license "MIT" \
    ${BIN}=/usr/bin/${NAME} \
    README.md=/usr/share/doc/${NAME}/README.md \
    ${NAME}.bash=/usr/share/bash-completion/completions/${NAME} \
    _${NAME}=/usr/share/zsh/site-functions/_${NAME}

  rm -f ${NAME}.bash _${NAME}
  mv ${NAME}_${VERSION}_${ARCHITECTURE}.deb ../
done

cd - >/dev/null

echo
echo "Removing temp files"
rm -rf ${NAME}-${VERSION} ${NAME}-${VERSION}.tar.gz

echo
echo "Including both packages in testing repo"
cd ohmydebn-packages-testing
reprepro remove trixie ${NAME}
reprepro -b . includedeb trixie ../${NAME}_${VERSION}_amd64.deb
reprepro -b . includedeb trixie ../${NAME}_${VERSION}_arm64.deb
cd - >/dev/null
