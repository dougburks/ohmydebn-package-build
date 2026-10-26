#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

VERSION="2.0.17"
NAME="touchegg"
AUTHOR="JoseExposito"
REPO="${AUTHOR}/${NAME}"
# Upstream's own .debs are shipped as they are, and GitHub publishes no
# digests for 2.0.17's assets (so download_verified can't be used): these
# are the sha256s of the files as downloaded on 2026-10-26, identical to
# the ones OhMyDebn has shipped since. A new VERSION needs new ones.
declare -A SHA256=(
  [amd64]="ef1873155eafefedbbc9a6911ff34c57511c49b43cbb37f5c6f8b795a04a0ecc"
  [arm64]="d08d03e49194c03796953e7739d46f4311513c7656571aa44724693398d51651"
)

rm -f "${STAGING_DIR}"/${NAME}*.deb
enter_work_dir

for ARCHITECTURE in amd64 arm64; do
  DEB="${NAME}_${VERSION}_${ARCHITECTURE}.deb"
  URL="https://github.com/${REPO}/releases/download/${VERSION}/${DEB}"
  echo
  echo "Downloading ${ARCHITECTURE} package from ${URL}"
  wget -q "${URL}"
  # Checked before it's anywhere near the staging directory, which
  # upload-to-repo-stable.sh publishes as it is.
  echo "${SHA256[${ARCHITECTURE}]}  ${DEB}" | sha256sum -c -
  mv "${DEB}" "${STAGING_DIR}/"
done

echo
echo "Including both packages in testing repo"
include_testing ${NAME} \
  "${STAGING_DIR}/${NAME}_${VERSION}_amd64.deb" \
  "${STAGING_DIR}/${NAME}_${VERSION}_arm64.deb"

upload_testing
