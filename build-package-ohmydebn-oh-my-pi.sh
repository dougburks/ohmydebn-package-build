#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

VERSION="18.3.1"
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
for DOC in LICENSE THIRD-PARTY-NOTICES.txt; do
  wget -q "${URL}/releases/download/v${VERSION}/${DOC}"
  grep " ${DOC}\$" SHA256SUMS.txt | sha256sum --check --quiet -
done

for ARCHITECTURE in amd64 arm64; do
  BINARY="omp-linux-${GH_ARCH[${ARCHITECTURE}]}"

  echo
  echo "Downloading ${ARCHITECTURE} release"
  wget -q "${URL}/releases/download/v${VERSION}/${BINARY}"
  grep " ${BINARY}\$" SHA256SUMS.txt | sha256sum --check -

  mkdir -p "pkgroot${INSTALL_DIR}" "pkgroot/usr/share/doc/${PACKAGE_NAME}"
  install -m 755 "${BINARY}" "pkgroot${INSTALL_DIR}/${NAME}"
  install -m 644 LICENSE THIRD-PARTY-NOTICES.txt "pkgroot/usr/share/doc/${PACKAGE_NAME}/"
  chmod -R u=rwX,go=rX pkgroot

  # A foreign-architecture binary can't run here, so only the native one is
  # smoke-tested.
  if [ "${ARCHITECTURE}" = "$(dpkg --print-architecture)" ]; then
    HOME="${WORK_DIR}" "pkgroot${INSTALL_DIR}/${NAME}" --version | grep -qF "omp/${VERSION}"
  fi

  echo
  echo "Building ${ARCHITECTURE} package"
  fpm -s dir -t deb \
    --maintainer "Doug Burks<doug.burks@example.com>" \
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
