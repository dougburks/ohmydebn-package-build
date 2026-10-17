#!/bin/bash
set -e

# Migrate existing users from the old GitHub Pages APT repo URL to the new
# Cloudflare R2 URL. This runs after the ohmydebn package is installed or
# upgraded.

SOURCES_FILE="/etc/apt/sources.list.d/ohmydebn.sources"

# Most users are using the stable repo
OLD_URL="https://dougburks.github.io/ohmydebn-packages/"
NEW_URL="https://packages.ohmydebn.org/"
if [ -f "${SOURCES_FILE}" ]; then
  if grep -q "${OLD_URL}" "${SOURCES_FILE}"; then
    sed -i "s|${OLD_URL}|${NEW_URL}|g" "${SOURCES_FILE}"
  fi
fi

# Update testing repo as well
OLD_URL="https://dougburks.github.io/ohmydebn-packages-testing/"
NEW_URL="https://packages-testing.ohmydebn.org/"
if [ -f "${SOURCES_FILE}" ]; then
  if grep -q "${OLD_URL}" "${SOURCES_FILE}"; then
    sed -i "s|${OLD_URL}|${NEW_URL}|g" "${SOURCES_FILE}"
  fi
fi

# Packages built before 4.12.0 had group-writable folders and files (built
# from git checkouts with umask 0002). Upgrading replaces the files with
# the new packages' modes, but dpkg leaves folders that already exist as
# they are, so fix those here, in this package and the ones it depends on.
for DIR in /usr/share/ohmydebn /usr/share/ohmydebn-themes /usr/share/ohmydebn-templates \
  /usr/share/cinnamon/extensions/gTile@OhMyDebn /usr/share/fonts/truetype/ohmydebn-caskaydiamononerdfont; do
  if [ -d "${DIR}" ]; then
    find "${DIR}" -type d -perm /022 -exec chmod go-w {} + 2>/dev/null || true
  fi
done
