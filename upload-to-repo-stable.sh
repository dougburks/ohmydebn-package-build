#!/bin/bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Set SKIP_UPLOAD=1 to update the local repo without syncing it to R2
: "${SKIP_UPLOAD:=0}"

cd "${STABLE_REPO}"

# Promote every package in the staging directory. The list comes from the
# debs themselves (their Package field) rather than a hand-kept list, which
# left newly added packages out of stable; it also covers debs whose file
# name doesn't start with the package name (LocalSend-*.deb is localsend).
declare -A DEBS=() SEEN=()
shopt -s nullglob
for DEB in "${STAGING_DIR}"/*.deb; do
  read -r PACKAGE ARCH < <(dpkg-deb --showformat='${Package} ${Architecture}\n' -W "${DEB}")
  # Two versions of one package would both be included, and whichever came
  # last would win; stop instead, since staging should hold one build.
  if [ -n "${SEEN[${PACKAGE}_${ARCH}]:-}" ]; then
    echo "Staging has more than one ${PACKAGE} (${ARCH}) deb:" >&2
    echo "  ${SEEN[${PACKAGE}_${ARCH}]}" >&2
    echo "  ${DEB}" >&2
    exit 1
  fi
  SEEN[${PACKAGE}_${ARCH}]="${DEB}"
  DEBS[${PACKAGE}]+="${DEB}"$'\n'
done

if [ "${#DEBS[@]}" -eq 0 ]; then
  echo "No debs in ${STAGING_DIR}" >&2
  exit 1
fi

for PACKAGE in $(printf '%s\n' "${!DEBS[@]}" | sort); do
  echo
  echo "Package: $PACKAGE"
  reprepro -b . remove trixie "${PACKAGE}"
  mapfile -t PACKAGE_DEBS <<<"${DEBS[${PACKAGE}]%$'\n'}"
  for DEB in "${PACKAGE_DEBS[@]}"; do
    reprepro -b . includedeb trixie "${DEB}"
  done
done

# Deploy to Cloudflare R2
if [ "${SKIP_UPLOAD}" = "1" ]; then
  echo
  echo "SKIP_UPLOAD=1, not syncing to R2"
  exit 0
fi
rclone sync . "r2:ohmydebn-packages" \
  --exclude "README.md" \
  --s3-no-check-bucket \
  --s3-no-head \
  --no-update-modtime \
  --ignore-checksum

echo
echo "If pushing modified packages, you will need to manually purge Cloudflare cache!"
