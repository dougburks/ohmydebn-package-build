#!/bin/bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Omarchy version currently has an alpha tag
#VERSION=$(cat "${GIT_ROOT}/omarchy/version")
# so let's hardcode it for now:
VERSION="4.0.0"
# Bumped whenever what's shipped from the same Omarchy themes changes, so
# apt upgrades existing installs (and removes files no longer shipped).
REVISION="2"
PREFIX="ohmydebn-themes"
OMARCHY_THEMES_DIR="${GIT_ROOT}/omarchy/themes"

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

# Dynamically determine the list of themes from the omarchy themes directory
THEMES=()
for dir in "${OMARCHY_THEMES_DIR}"/*/; do
  THEMES+=("$(basename "$dir")")
done

# Create individual package for each omarchy theme
for THEME in "${THEMES[@]}"; do

  echo "Working on $THEME"
  PACKAGE="${PREFIX}-${THEME}"
  rm -f "${STAGING_DIR}"/${PACKAGE}_*.deb

  mkdir -p "${STAGE}"
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

  fpm -s dir \
    -t deb \
    -n ${PACKAGE} \
    -v ${VERSION} \
    --iteration ${REVISION} \
    --package "${STAGING_DIR}/" \
    -a all \
    --maintainer "Doug Burks<doug.burks@example.com>" \
    --description "${THEME} theme from Omarchy packaged for OhMyDebn" \
    --url "https://ohmydebn.org" \
    "${STAGE}/${THEME}"=/usr/share/ohmydebn-themes/

  echo
  ls -alh "${STAGING_DIR}"/${PACKAGE}_*.deb
  echo
  include_testing ${PACKAGE} "${STAGING_DIR}/${PACKAGE}_${VERSION}-${REVISION}_all.deb"

done

# Create the ohmydebn-themes-omarchy package that just contains the version file
PACKAGE="${PREFIX}-omarchy"
rm -f "${STAGING_DIR}"/${PACKAGE}_*.deb

DEPENDS=()
for THEME in "${THEMES[@]}"; do
  DEPENDS+=(-d "${PREFIX}-${THEME}")
done

fpm -s empty \
  -t deb \
  -n ${PACKAGE} \
  -v ${VERSION} \
  --iteration ${REVISION} \
  --package "${STAGING_DIR}/" \
  -a all \
  --maintainer "Doug Burks<doug.burks@example.com>" \
  --description "Themes from Omarchy packaged for OhMyDebn" \
  --url "https://ohmydebn.org" \
  "${DEPENDS[@]}"

echo
ls -alh "${STAGING_DIR}"/${PACKAGE}_*.deb
echo
include_testing ${PACKAGE} "${STAGING_DIR}/${PACKAGE}_${VERSION}-${REVISION}_all.deb"

upload_testing
