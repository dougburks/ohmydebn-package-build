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

VERSION="0.5.1"
# Package revision, for a rebuild of the same ttfx version; reset it to 1
# for a new upstream VERSION.
REVISION="1"
NAME="ttfx"
SOURCE_SHA256="3f10b987b7690aa3caa2fa4f1749d8c7904e177380eff3e000d3422da8eb0134"
AUTHOR="omacom"
DESC="Terminal text effects as a single static binary"
REPO="${AUTHOR}/${NAME}"
URL="https://github.com/${REPO}"

# The shell completions come from running the amd64 binary (below), so this
# runs on amd64 only, as the arm64 cross-build already assumes.
if [ "$(dpkg --print-architecture)" != "amd64" ]; then
  echo "This build runs on amd64 only" >&2
  exit 1
fi

rm -f "${STAGING_DIR}"/${NAME}*.deb
enter_work_dir

echo
echo "Downloading source for v${VERSION}"
wget -q -O ${NAME}-${VERSION}.tar.gz "${URL}/archive/refs/tags/v${VERSION}.tar.gz"
# GitHub publishes no digest for a tag's source tarball, and a tag can be
# moved, so the code built under this VERSION is pinned here: the tarball
# as downloaded on 2026-10-26 (tag v0.5.1 at commit 14ed274). A new VERSION
# needs a new one. Should GitHub ever regenerate its archives byte for
# byte differently, check the tag still points at the same commit before
# updating it.
echo "${SOURCE_SHA256}  ${NAME}-${VERSION}.tar.gz" | sha256sum -c -
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

  # The completions are text, the same for both architectures, and come
  # from running the binary - which only the amd64 one (built first) can do
  # here. Running the arm64 binary for them failed, and `|| true` shipped
  # the arm64 package with empty completion files.
  if [ "${ARCHITECTURE}" = "amd64" ]; then
    echo
    echo "Generating shell completions"
    "${BIN}" --print-completion bash >${NAME}.bash
    "${BIN}" --print-completion zsh >_${NAME}
    if [ ! -s ${NAME}.bash ] || [ ! -s _${NAME} ]; then
      echo "ttfx printed no shell completions" >&2
      exit 1
    fi
  fi

  echo
  echo "Building ${ARCHITECTURE} package"
  fpm -s dir -t deb \
    --maintainer "Doug Burks <https://github.com/dougburks/ohmydebn>" \
    -n "${NAME}" \
    -v "${VERSION}" \
    --iteration "${REVISION}" \
    --package "${STAGING_DIR}/" \
    --architecture ${ARCHITECTURE} \
    --description "${DESC}" \
    --url "${URL}" \
    --license "MIT" \
    ${BIN}=/usr/bin/${NAME} \
    README.md=/usr/share/doc/${NAME}/README.md \
    ${NAME}.bash=/usr/share/bash-completion/completions/${NAME} \
    _${NAME}=/usr/share/zsh/site-functions/_${NAME}
done

rm -f ${NAME}.bash _${NAME}

cd - >/dev/null

echo
echo "Removing temp files"
rm -rf ${NAME}-${VERSION} ${NAME}-${VERSION}.tar.gz

echo
echo "Including both packages in testing repo"
include_testing ${NAME} \
  "${STAGING_DIR}/${NAME}_${VERSION}-${REVISION}_amd64.deb" \
  "${STAGING_DIR}/${NAME}_${VERSION}-${REVISION}_arm64.deb"

upload_testing
