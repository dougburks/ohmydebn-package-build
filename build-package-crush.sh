#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Crush, Charm's terminal coding agent: Charm's own .debs from the GitHub
# release, as gum's are, checked against the digests GitHub publishes for
# them. Packaged here rather than installed from Charm's apt repository so
# users get a version that went through testing, and no third-party repo,
# key or pin.
VERSION="0.98.2"
PACKAGE_NAME="crush"
REPO="charmbracelet/crush"

rm -f "${STAGING_DIR}"/${PACKAGE_NAME}_*.deb
enter_work_dir

echo
echo "Downloading amd64 .deb"
download_verified "${REPO}" "v${VERSION}" ${PACKAGE_NAME}_${VERSION}_amd64.deb
mv ${PACKAGE_NAME}_${VERSION}_amd64.deb "${STAGING_DIR}/"

echo
echo "Downloading arm64 .deb"
download_verified "${REPO}" "v${VERSION}" ${PACKAGE_NAME}_${VERSION}_arm64.deb
mv ${PACKAGE_NAME}_${VERSION}_arm64.deb "${STAGING_DIR}/"

echo
echo "Including both packages in testing repo"
include_testing ${PACKAGE_NAME} \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_amd64.deb" \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_arm64.deb"

upload_testing
