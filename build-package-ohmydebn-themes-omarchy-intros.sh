#!/bin/bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Theme intros: the short silent clips Omarchy 4.5 added to its themes, one
# per background that has one (backgrounds/intros/<background name>.mp4).
# ohmydebn-theme-intro plays one full screen when a theme is switched to
# and at login, fading into the still background it ends on (a background
# without a clip gets the light intro, drawn live from the image, so
# without this package the themes still have intros). Packaged
# separately from ohmydebn-themes-omarchy because it's the one part worth
# leaving out (install/packaging/theme-intros.sh skips it on a Raspberry
# Pi, where intros don't play), and because ohmydebn-themes-omarchy still
# comes from Omarchy 4.0.0: the clips are named after backgrounds that
# 4.0.0 already ships, so they work with it as they are.
#
# The clips come from one commit of Omarchy's repository (git checks every
# object against its hash, so the commit pins the content), and are
# re-encoded to VP9 at no more than 1440 lines: about a quarter of the
# original download, and played by GStreamer's standard plugins rather than
# the separate H.264 decoder.
OMARCHY_TAG="v4.5.0-rc1"
OMARCHY_COMMIT="03ff1eff3812933f7088484533784d2f63eaf19a"
# The Omarchy version the clips come from, with ~ so 4.5.0~rc1 sorts below
# a later 4.5.0.
VERSION="4.5.0~rc1"
# Bumped whenever the same clips are rebuilt with changes (the encoding,
# the list below), so apt upgrades existing installs. 2: the login entry
# moved to the ohmydebn package, now that every background has an intro.
REVISION="2"
PACKAGE="ohmydebn-themes-omarchy-intros"
# The backgrounds ohmydebn-themes-omarchy is built from: a clip is shipped
# only if the background it belongs to is. Checked to be at the release
# that package is built from, as it is.
OMARCHY_THEMES_DIR="${GIT_ROOT}/omarchy/themes"
require_omarchy_checkout "${GIT_ROOT}/omarchy"
# Intros showing the OMARCHY wordmark, which would confuse OhMyDebn users.
# Every clip was checked frame by frame on 2026-10-20; only this one does,
# and its background isn't shipped either (EXCLUDED_BACKGROUNDS in
# build-package-ohmydebn-themes-omarchy.sh). A new or changed clip needs
# the same check.
EXCLUDED_INTROS=(
  "lumon/backgrounds/intros/02-opinions-equally.mp4" # "OMARCHY - Enjoy Each Opinion Equally"
)

rm -f "${STAGING_DIR}"/${PACKAGE}_*.deb
enter_work_dir

git clone -q --depth 1 --branch "${OMARCHY_TAG}" --filter=blob:none --no-checkout \
  https://github.com/omacom/omarchy.git omarchy
git -C omarchy sparse-checkout set --no-cone '/themes/*/backgrounds/intros/*'
git -C omarchy checkout -q
if [[ "$(git -C omarchy rev-parse HEAD)" != "${OMARCHY_COMMIT}" ]]; then
  echo "${OMARCHY_TAG} is no longer ${OMARCHY_COMMIT}; check what changed before updating OMARCHY_COMMIT" >&2
  exit 1
fi

STAGE="${WORK_DIR}/stage"
mkdir -p "${STAGE}"
cd omarchy/themes
for clip in */backgrounds/intros/*.mp4; do
  theme="${clip%%/*}"
  stem="$(basename "${clip}" .mp4)"
  excluded=false
  for e in "${EXCLUDED_INTROS[@]}"; do
    [[ "${clip}" == "${e}" ]] && excluded=true
  done
  if [[ "${excluded}" == true || "${stem,,}" == *omarchy* ]]; then
    echo "  not shipped: ${clip}"
    continue
  fi
  if ! compgen -G "${OMARCHY_THEMES_DIR}/${theme}/backgrounds/${stem}.*" >/dev/null; then
    echo "${clip} has no matching background in ${OMARCHY_THEMES_DIR}/${theme}" >&2
    exit 1
  fi
  echo "Encoding ${clip}"
  mkdir -p "${STAGE}/${theme}/backgrounds/intros"
  # -an: intros are silent, and a stray audio track would only be dropped
  # by the player anyway.
  ffmpeg -nostdin -v error -i "${clip}" -an -vf "scale=-2:'min(1440,ih)'" \
    -c:v libvpx-vp9 -crf 32 -b:v 0 -row-mt 1 -deadline good -cpu-used 2 -pix_fmt yuv420p \
    "${STAGE}/${theme}/backgrounds/intros/${stem}.webm"
done
cd "${WORK_DIR}"
chmod -R go-w "${STAGE}"

# The player (ohmydebn-theme-intro-play, in the ohmydebn package) needs
# GStreamer's playbin and videoconvert (plugins-base), the VP9 decoder and
# aspectratiocrop (plugins-good) and gtksink (gtk3), driven from Python.
fpm -s dir \
  -t deb \
  -n ${PACKAGE} \
  -v "${VERSION}" \
  --iteration ${REVISION} \
  --package "${STAGING_DIR}/" \
  -a all \
  --maintainer "Doug Burks <https://github.com/dougburks/ohmydebn>" \
  --description "Theme intros from Omarchy packaged for OhMyDebn" \
  --url "https://ohmydebn.org" \
  --depends "ohmydebn (>= 4.13.0)" \
  --depends ohmydebn-themes-omarchy \
  --depends python3-gi \
  --depends gir1.2-gtk-3.0 \
  --depends gir1.2-gstreamer-1.0 \
  --depends gstreamer1.0-plugins-base \
  --depends gstreamer1.0-plugins-good \
  --depends gstreamer1.0-gtk3 \
  "${STAGE}/"=/usr/share/ohmydebn-themes

echo
ls -alh "${STAGING_DIR}"/${PACKAGE}_*.deb
echo
include_testing ${PACKAGE} "${STAGING_DIR}/${PACKAGE}_${VERSION}-${REVISION}_all.deb"

upload_testing
