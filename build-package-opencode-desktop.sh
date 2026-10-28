#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# OpenCode Desktop, OpenCode's GUI app: OpenCode's own .debs from the
# GitHub release, checked against the digests GitHub publishes for them,
# with one change. The app carries its own copy of OpenCode, which shares
# its data with ohmydebn-opencode-cli, so the two must stay on the same
# release: VERSION is that script's, never set here.
#
# The change: without it, the app can download and install newer .debs
# from opencode.ai itself, leaving apt's copy and ohmydebn-opencode-cli
# behind. Its updater (electron-updater) picks its Linux mode from
# resources/package-type, which the app reads for nothing else; without
# that file it falls back to the AppImage updater, which is inactive
# outside an AppImage, so "Check for updates" finds nothing and asks no
# server. The package keeps its name, opencode, so it upgrades OpenCode's
# own .deb if one is installed, and the version gets +ohmydebn<REVISION>,
# which still sorts below OpenCode's next release.
VERSION=$(sed -n 's/^VERSION="\(.*\)"$/\1/p' "$(dirname "${BASH_SOURCE[0]}")/build-package-ohmydebn-opencode-cli.sh")
# Package revision, for a rebuild of the same OpenCode version.
REVISION="1"
PACKAGE_NAME="opencode"
REPO="anomalyco/opencode"

if [[ ! "${VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Couldn't read OpenCode's VERSION from build-package-ohmydebn-opencode-cli.sh" >&2
  exit 1
fi

rm -f "${STAGING_DIR}"/${PACKAGE_NAME}_*.deb
enter_work_dir

for ARCHITECTURE in amd64 arm64; do
  ASSET="opencode-desktop-linux-${ARCHITECTURE}.deb"
  OUT="${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}+ohmydebn${REVISION}_${ARCHITECTURE}.deb"

  echo
  echo "Downloading ${ARCHITECTURE} .deb"
  download_verified "${REPO}" "v${VERSION}" "${ASSET}"

  echo
  echo "Repacking ${ARCHITECTURE} .deb without the updater's package-type"
  rm -rf root
  dpkg-deb -R "${ASSET}" root
  if [ "$(dpkg-deb -f "${ASSET}" Package Version)" != "Package: ${PACKAGE_NAME}
Version: ${VERSION}" ] || [ ! -f root/opt/OpenCode/resources/package-type ]; then
    echo "${ASSET} isn't the opencode ${VERSION} package laid out as expected" >&2
    exit 1
  fi
  rm root/opt/OpenCode/resources/package-type
  sed -i '\#  opt/OpenCode/resources/package-type$#d' root/DEBIAN/md5sums
  sed -i "s/^Version: ${VERSION}\$/Version: ${VERSION}+ohmydebn${REVISION}/" root/DEBIAN/control
  # dpkg-deb refuses a control directory a desktop umask (0002) made group-
  # writable.
  chmod -R go-w root/DEBIAN
  dpkg-deb --root-owner-group -Zxz -b root "${OUT}"
  rm -rf root "${ASSET}"
done

echo
echo "Including both packages in testing repo"
include_testing ${PACKAGE_NAME} \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}+ohmydebn${REVISION}_amd64.deb" \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}+ohmydebn${REVISION}_arm64.deb"

upload_testing
