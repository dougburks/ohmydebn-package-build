#!/usr/bin/env bash

# Unlike the other build-package-*.sh scripts, upstream does not publish
# release binaries (GitHub release assets are empty) and there is no
# crates.io package, so this builds from source with cargo instead of
# wget-ing a prebuilt binary.
#
# Prerequisites on the build machine - Debian's newer Rust (rustc-web, 1.96
# in Debian 13; the one Debian builds Firefox and Chromium with), with the
# arm64 standard library for cross-compiling. 0.5.0 needs Rust >= 1.89 for
# its AVX-512 code, newer than Debian's default rustc (1.85), which
# rustc-web/cargo-web replace:
#   sudo dpkg --add-architecture arm64 && sudo apt update
#   sudo apt install rustc-web cargo-web libstd-rust-web-dev:arm64 gcc-aarch64-linux-gnu
# (aarch64-linux-gnu-gcc is the arm64 linker.) If a later ttfx needs a newer
# Rust still, cargo stops with "requires rustc X"; rustup's toolchain
# (rustup target add x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu)
# works with this script unchanged.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

VERSION="0.5.0"
NAME="ttfx"
AUTHOR="omacom-io"
DESC="Terminal text effects as a single static binary"
REPO="${AUTHOR}/${NAME}"
URL="https://github.com/${REPO}"

rm -f "${STAGING_DIR}"/${NAME}*.deb
enter_work_dir

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
  # 0.5.0's engine picks its SIMD path at run time (AVX-512 or AVX2 on
  # x86-64 when the CPU has them, NEON on arm64, plain Rust otherwise), so
  # one build runs on any CPU of the architecture.
  cargo build --release --locked --target "${TARGET}"

  BIN="target/${TARGET}/release/${NAME}"

  echo
  echo "Generating shell completions"
  "${BIN}" --print-completion bash >${NAME}.bash 2>/dev/null || true
  "${BIN}" --print-completion zsh >_${NAME} 2>/dev/null || true

  echo
  echo "Building ${ARCHITECTURE} package"
  fpm -s dir -t deb \
    --maintainer "Doug Burks<doug.burks@example.com>" \
    -n "${NAME}" \
    -v "${VERSION}" \
    --package "${STAGING_DIR}/" \
    --architecture ${ARCHITECTURE} \
    --description "${DESC}" \
    --url "${URL}" \
    --license "MIT" \
    ${BIN}=/usr/bin/${NAME} \
    README.md=/usr/share/doc/${NAME}/README.md \
    ${NAME}.bash=/usr/share/bash-completion/completions/${NAME} \
    _${NAME}=/usr/share/zsh/site-functions/_${NAME}

  rm -f ${NAME}.bash _${NAME}
done

cd - >/dev/null

echo
echo "Removing temp files"
rm -rf ${NAME}-${VERSION} ${NAME}-${VERSION}.tar.gz

echo
echo "Including both packages in testing repo"
include_testing ${NAME} \
  "${STAGING_DIR}/${NAME}_${VERSION}_amd64.deb" \
  "${STAGING_DIR}/${NAME}_${VERSION}_arm64.deb"

upload_testing
