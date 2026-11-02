#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

VERSION="18.15.0"
NAME="omp"
AUTHOR="can1357"
DESC="Coding agent with the IDE wired in (Stencil Labs' fork of Pi)"
PACKAGE_NAME="ohmydebn-oh-my-pi"
REPO="${AUTHOR}/oh-my-pi"
URL="https://github.com/${REPO}"
INSTALL_DIR="/usr/lib/${PACKAGE_NAME}"

rm -f "${STAGING_DIR}"/${PACKAGE_NAME}*.deb
enter_work_dir

# Each release ships a single self-contained binary per platform (only glibc
# is linked dynamically) plus a SHA256SUMS.txt covering every asset, so each
# download is checked against it. `omp update` never replaces this copy:
# it updates through whichever installer owns the running binary, and a
# root-owned file under /usr/lib is apt's.
declare -A GH_ARCH=(
  [amd64]="x64"
  [arm64]="arm64"
)

wget -q "${URL}/releases/download/v${VERSION}/SHA256SUMS.txt"
wget -q "${URL}/releases/download/v${VERSION}/LICENSE"
grep " LICENSE\$" SHA256SUMS.txt | sha256sum --check --quiet -
# From 18.14.0 the third-party notices are no longer a release asset (so
# not in SHA256SUMS.txt): they're two files in the source, the CLI's and
# the native addon's, which `omp --license` prints. Both are taken from
# the release tag. Up to 18.13.3 the asset was the same file as the
# source's at its tag, byte for byte.
RAW="https://raw.githubusercontent.com/${REPO}/v${VERSION}/packages"
wget -q -O THIRD-PARTY-NOTICES.txt "${RAW}/coding-agent/THIRD-PARTY-NOTICES.txt"
wget -q -O THIRD-PARTY-NOTICES-natives.txt "${RAW}/natives/THIRD-PARTY-NOTICES.txt"

for ARCHITECTURE in amd64 arm64; do
  BINARY="omp-linux-${GH_ARCH[${ARCHITECTURE}]}"

  echo
  echo "Downloading ${ARCHITECTURE} release"
  wget -q "${URL}/releases/download/v${VERSION}/${BINARY}"
  grep " ${BINARY}\$" SHA256SUMS.txt | sha256sum --check -

  mkdir -p "pkgroot${INSTALL_DIR}" "pkgroot/usr/share/doc/${PACKAGE_NAME}"
  install -m 755 "${BINARY}" "pkgroot${INSTALL_DIR}/${NAME}"
  install -m 644 LICENSE THIRD-PARTY-NOTICES.txt THIRD-PARTY-NOTICES-natives.txt "pkgroot/usr/share/doc/${PACKAGE_NAME}/"
  chmod -R u=rwX,go=rX pkgroot

  # A foreign-architecture binary can't run here, so only the native one is
  # smoke-tested.
  if [ "${ARCHITECTURE}" = "$(dpkg --print-architecture)" ]; then
    HOME="${WORK_DIR}" "pkgroot${INSTALL_DIR}/${NAME}" --version | grep -qF "omp/${VERSION}"
  fi

  echo
  echo "Building ${ARCHITECTURE} package"
  fpm -s dir -t deb \
    --maintainer "Doug Burks <https://github.com/dougburks/ohmydebn>" \
    -n "${PACKAGE_NAME}" \
    -v "${VERSION}" \
    --package "${STAGING_DIR}/" \
    --architecture ${ARCHITECTURE} \
    --description "${DESC}" \
    --url "${URL}" \
    --license "MIT" \
    -C pkgroot \
    .

  echo
  echo "Removing ${ARCHITECTURE} temp files"
  rm -rf pkgroot "${BINARY}"
done

echo
echo "Including both packages in testing repo"
include_testing ${PACKAGE_NAME} \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_amd64.deb" \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_arm64.deb"

upload_testing
