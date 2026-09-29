#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

VERSION="1.0.41"
NAME="grok"
DESC="SpaceXAI's terminal-based AI coding agent"
PACKAGE_NAME="ohmydebn-grok-build"
URL="https://x.ai/cli"
INSTALL_DIR="/usr/lib/${PACKAGE_NAME}"

rm -f "${STAGING_DIR}"/${PACKAGE_NAME}*.deb
enter_work_dir

# xAI's own installer (x.ai/cli/install.sh) downloads a bare binary from
# x.ai/cli with no checksum or signature to check it against. The same
# binary - byte for byte, checked for 1.0.41 - is also published to npm as
# @xai-official/grok-linux-<arch>, brotli-compressed as package/bin/grok.br,
# and npm publishes a sha512 integrity hash for every tarball. So we
# download from npm and verify that hash first.
#
# Always fetch the exact VERSION: the platform packages' "latest" dist-tag
# is stale (it pointed at 0.1.220 while 1.0.41 was current); the top-level
# @xai-official/grok package pins its platform packages to the real
# release.
#
# The binary is static-pie, so the package has no library dependencies. It
# doesn't update itself from here: Grok only self-updates the copy that
# ~/.grok/bin/grok points to (its own installer's layout), and OhMyDebn's
# launchers also set GROK_DISABLE_AUTOUPDATER=1.
declare -A NPM_ARCH=(
  [amd64]="x64"
  [arm64]="arm64"
)

for ARCHITECTURE in amd64 arm64; do
  NPM_PACKAGE="@xai-official/grok-linux-${NPM_ARCH[${ARCHITECTURE}]}"

  echo
  echo "Downloading ${ARCHITECTURE} release"
  METADATA=$(wget -q -O - "https://registry.npmjs.org/${NPM_PACKAGE/\//%2f}/${VERSION}")
  TARBALL_URL=$(jq -r '.dist.tarball' <<<"${METADATA}")
  INTEGRITY=$(jq -r '.dist.integrity' <<<"${METADATA}")
  wget -q -O grok.tgz "${TARBALL_URL}"
  if [ "sha512-$(openssl dgst -sha512 -binary grok.tgz | base64 -w0)" != "${INTEGRITY}" ]; then
    echo "sha512 integrity mismatch for ${TARBALL_URL}" >&2
    exit 1
  fi
  echo "${NPM_PACKAGE}@${VERSION}: OK"

  mkdir -p npm pkgroot"${INSTALL_DIR}" pkgroot/usr/share/doc/${PACKAGE_NAME}
  tar xzf grok.tgz -C npm
  brotli -d -f -o "pkgroot${INSTALL_DIR}/${NAME}" npm/package/bin/grok.br
  cp npm/package/THIRD_PARTY_NOTICES.md "pkgroot/usr/share/doc/${PACKAGE_NAME}/"
  chmod -R u=rwX,go=rX pkgroot
  chmod 755 "pkgroot${INSTALL_DIR}/${NAME}"

  # A foreign-architecture binary can't run here, so only the native one is
  # smoke-tested.
  if [ "${ARCHITECTURE}" = "$(dpkg --print-architecture)" ]; then
    HOME="${WORK_DIR}" "pkgroot${INSTALL_DIR}/${NAME}" --version | grep -qF "grok ${VERSION}"
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
    --license "Apache-2.0" \
    -C pkgroot \
    .

  echo
  echo "Removing ${ARCHITECTURE} temp files"
  rm -rf npm pkgroot grok.tgz
done

echo
echo "Including both packages in testing repo"
include_testing ${PACKAGE_NAME} \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_amd64.deb" \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_arm64.deb"

upload_testing
