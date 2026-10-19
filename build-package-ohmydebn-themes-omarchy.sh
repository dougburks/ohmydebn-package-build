#!/bin/bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Omarchy version currently has an alpha tag
#VERSION=$(cat "${GIT_ROOT}/omarchy/version")
# so let's hardcode it for now:
VERSION="4.0.0"
# Bumped whenever what's shipped from the same Omarchy themes changes, so
# apt upgrades existing installs (and removes files no longer shipped).
# 3: files no longer group-writable. 4: one package for all the themes.
REVISION="4"
PACKAGE="ohmydebn-themes-omarchy"
OMARCHY_THEMES_DIR="${GIT_ROOT}/omarchy/themes"

# Up to 4.0.0-3 each theme was its own package (to keep files small for
# GitHub Pages), with ohmydebn-themes-omarchy an empty package depending on
# them all. Now it holds every theme itself and takes over those packages
# (Replaces moves their files, Conflicts makes apt remove them). A theme
# Omarchy drops later then disappears with the next update, instead of
# staying behind in a package nothing depends on. Themes added since never
# had a package, so this list stays as it is.
OLD_PACKAGES=(
  ohmydebn-themes-catppuccin ohmydebn-themes-catppuccin-latte ohmydebn-themes-ethereal
  ohmydebn-themes-everforest ohmydebn-themes-flexoki-light ohmydebn-themes-gruvbox
  ohmydebn-themes-hackerman ohmydebn-themes-kanagawa ohmydebn-themes-last-horizon
  ohmydebn-themes-lumon ohmydebn-themes-lupine ohmydebn-themes-matte-black
  ohmydebn-themes-miasma ohmydebn-themes-nord ohmydebn-themes-osaka-jade
  ohmydebn-themes-retro-82 ohmydebn-themes-ristretto ohmydebn-themes-rose-pine
  ohmydebn-themes-solitude ohmydebn-themes-tokyo-night ohmydebn-themes-vantablack
  ohmydebn-themes-white
)

# Images that say "Omarchy", which would confuse OhMyDebn users, aren't
# shipped: the backgrounds showing the OMARCHY wordmark (all named
# *omarchy*, plus the ones listed below, which aren't) and the lock-screen
# images (unlock.png, preview-unlock.png), which OhMyDebn never displays and
# which nearly all show it. Each theme keeps at least one background. A new
# Omarchy theme's wordmark background that isn't named *omarchy* has to be
# added to the list - check the "not shipped" lines this prints.
EXCLUDED_BACKGROUNDS=(
  "lumon/backgrounds/02-opinions-equally.jpg" # "OMARCHY - Enjoy Each Opinion Equally"
)
STAGE="${WORK_DIR}/themes"

rm -f "${STAGING_DIR}"/${PACKAGE}_*.deb
# The old theme packages' debs too, so promoting staging to stable doesn't
# bring them back.
for OLD in "${OLD_PACKAGES[@]}"; do
  rm -f "${STAGING_DIR}"/${OLD}_*.deb
done

mkdir -p "${STAGE}"
for dir in "${OMARCHY_THEMES_DIR}"/*/; do
  THEME="$(basename "$dir")"
  echo "Working on $THEME"
  cp -a "${OMARCHY_THEMES_DIR}/${THEME}" "${STAGE}/"
  {
    find "${STAGE}/${THEME}/backgrounds" -type f -iname '*omarchy*' 2>/dev/null
    find "${STAGE}/${THEME}" -maxdepth 1 -type f \( -name unlock.png -o -name preview-unlock.png \)
    for f in "${EXCLUDED_BACKGROUNDS[@]}"; do
      if [[ $f == "${THEME}/"* && -f "${STAGE}/$f" ]]; then echo "${STAGE}/$f"; fi
    done
  } | sort -u | while IFS= read -r f; do
    echo "  not shipped: ${f#"${STAGE}"/}"
    rm "$f"
  done
  if [ -d "${STAGE}/${THEME}/backgrounds" ] && [ -z "$(ls -A "${STAGE}/${THEME}/backgrounds")" ]; then
    echo "${THEME} would ship no backgrounds" >&2
    exit 1
  fi
done
# Without group write, which the checkout has under a desktop umask (fpm
# keeps each file's mode).
chmod -R go-w "${STAGE}"

TAKEOVER=()
for OLD in "${OLD_PACKAGES[@]}"; do
  TAKEOVER+=(--replaces "${OLD}" --conflicts "${OLD}")
done

fpm -s dir \
  -t deb \
  -n ${PACKAGE} \
  -v ${VERSION} \
  --iteration ${REVISION} \
  --package "${STAGING_DIR}/" \
  -a all \
  --maintainer "Doug Burks <https://github.com/dougburks/ohmydebn>" \
  --description "Themes from Omarchy packaged for OhMyDebn" \
  --url "https://ohmydebn.org" \
  "${TAKEOVER[@]}" \
  "${STAGE}/"=/usr/share/ohmydebn-themes

echo
ls -alh "${STAGING_DIR}"/${PACKAGE}_*.deb
echo
include_testing ${PACKAGE} "${STAGING_DIR}/${PACKAGE}_${VERSION}-${REVISION}_all.deb"
# The packages this one took over, so the repo stops offering them.
for OLD in "${OLD_PACKAGES[@]}"; do
  reprepro -b "${TESTING_REPO}" remove trixie "${OLD}"
done

upload_testing
