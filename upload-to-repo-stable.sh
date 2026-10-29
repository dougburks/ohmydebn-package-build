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

# Each package is replaced in stable as a whole (reprepro remove takes out
# every architecture), so staging must hold every architecture stable has
# for it. A build script writes each architecture to staging as it's
# built, so one that stopped after amd64 left only that, and promoting it
# would have taken arm64 out of stable. Checked for every package before
# anything changes.
MISSING=()
for PACKAGE in $(printf '%s\n' "${!DEBS[@]}" | sort); do
  while read -r ARCH; do
    [ -n "${SEEN[${PACKAGE}_${ARCH}]:-}" ] || MISSING+=("${PACKAGE} (${ARCH})")
  done < <(reprepro -b . --list-format '${architecture}\n' list trixie "${PACKAGE}" | sort -u)
done
if [ "${#MISSING[@]}" -gt 0 ]; then
  echo "Stable has these, but staging doesn't, so promoting would remove them from stable:" >&2
  printf '  %s\n' "${MISSING[@]}" >&2
  echo "Build the missing architectures (or take the package out of staging) and run this again." >&2
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

# Packages OhMyDebn no longer ships, which a later package took over (its
# Replaces/Conflicts remove them from installed systems). Removing them from
# the repo stops apt offering them. Add a package here, with a comment
# naming what replaced it, for the release that retires it; take it out
# again once that release is in stable, since every later run would only
# report "Not removed as not found" for it. (The last ones, the per-theme
# Omarchy packages and the Caskaydia Mono/Propo font packages, were
# retired in 4.12.0 and are in git history.)
RETIRED_PACKAGES=()
for PACKAGE in "${RETIRED_PACKAGES[@]}"; do
  reprepro -b . remove trixie "${PACKAGE}"
done

# Deploy to Cloudflare R2
if [ "${SKIP_UPLOAD}" = "1" ]; then
  echo
  echo "SKIP_UPLOAD=1, not syncing to R2"
  exit 0
fi
# conf/ and db/ are reprepro's own working files (its configuration and
# package database), not part of the apt repo - they used to be published
# along with it.
rclone sync . "r2:ohmydebn-packages" \
  --exclude "README.md" \
  --exclude "conf/**" \
  --exclude "db/**" \
  --s3-no-check-bucket \
  --s3-no-head \
  --no-update-modtime \
  --ignore-checksum

echo
echo "If pushing modified packages, you will need to manually purge Cloudflare cache!"
