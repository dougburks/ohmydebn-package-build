#!/bin/bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# The Omarchy release the themes come from (OMARCHY_THEMES_TAG, in
# common.sh), checked against the omarchy checkout below. A pre-release's
# - becomes ~ (4.5.0-rc3 -> 4.5.0~rc3), so it sorts below the final 4.5.0
# (with a -, it would sort above it).
VERSION="${OMARCHY_THEMES_TAG#v}"
VERSION="${VERSION/-/\~}"
# Bumped whenever what's shipped from the same Omarchy themes changes, so
# apt upgrades existing installs (and removes files no longer shipped).
# Back to 1 for each new Omarchy release. Under 4.0.0: 3, files no longer
# group-writable; 4, one package for all the themes. Under 4.5.0~rc3: 2,
# without Omarchy's original intro clips; 3, without Tokyo Night's Liftoff.
REVISION="3"
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

# What isn't shipped - backgrounds showing the OMARCHY wordmark, the
# lock-screen images, and the images OhMyDebn can't redistribute - is
# described with EXCLUDED_BACKGROUNDS and EXCLUDED_THEMES in common.sh,
# which the intros package applies too.
STAGE="${WORK_DIR}/themes"

require_omarchy_checkout "${GIT_ROOT}/omarchy"

rm -f "${STAGING_DIR}"/${PACKAGE}_*.deb
# The old theme packages' debs too, so promoting staging to stable doesn't
# bring them back.
for OLD in "${OLD_PACKAGES[@]}"; do
  rm -f "${STAGING_DIR}"/${OLD}_*.deb
done

mkdir -p "${STAGE}"
for dir in "${OMARCHY_THEMES_DIR}"/*/; do
  THEME="$(basename "$dir")"
  if [[ " ${EXCLUDED_THEMES[*]} " == *" ${THEME} "* ]]; then
    echo "  not shipped: ${THEME} (the whole theme)"
    continue
  fi
  echo "Working on $THEME"
  cp -a "${OMARCHY_THEMES_DIR}/${THEME}" "${STAGE}/"
  # Omarchy 4.5 keeps its intro clips in the themes (backgrounds/intros),
  # as H.264 .mp4 files. They ship re-encoded, and checked for the
  # wordmark, in ohmydebn-themes-omarchy-intros, so not here as well.
  rm -rf "${STAGE}/${THEME}/backgrounds/intros"
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
