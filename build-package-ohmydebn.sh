#!/bin/bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

PACKAGE="ohmydebn"
VERSION=$(cat "${GIT_ROOT}/ohmydebn/VERSION")
rm -f "${STAGING_DIR}"/${PACKAGE}_*.deb

# Pre-build the menu search cache so even the very first launch after
# install is fast, not just subsequent ones (ohmydebn-menu-tree's
# _mt_cached_raw() unconditionally prefers this shipped file over
# computing it on the fly, for the real installed path - see its own
# comment there). Regenerated fresh on every build directly from the exact
# ohmydebn-menu about to be packaged, so it can never ship stale relative
# to its own source. The target strings this produces (e.g.
# /usr/share/ohmydebn/bin/ohmydebn-gimp) are already deploy-path-correct
# regardless of which copy of the file we parse them from - ohmydebn-menu
# hardcodes those paths as literal text, so this local checkout and the
# not-yet-installed deployed copy are byte-for-byte identical once fpm
# copies the file across below.
mkdir -p "${GIT_ROOT}/ohmydebn/cache"
rm -f "${GIT_ROOT}/ohmydebn/cache/menu-tree-flatten.tsv"
(
  source "${GIT_ROOT}/ohmydebn/bin/ohmydebn-menu-tree"
  _mt_flatten_uncached "${GIT_ROOT}/ohmydebn/bin/ohmydebn-menu"
# "WARN: no block for show_other_apps_menu" on stderr here is expected,
# not a build failure - show_other_apps_menu deliberately has no static
# menu() call (Other Apps is a live .desktop scan, not something this
# bash-source parser can enumerate - see its own comment in
# ohmydebn-menu), and this is exactly the tool correctly detecting that
# and skipping it rather than silently guessing wrong. Filtered out here
# by exact message text, not by discarding stderr wholesale, so a
# genuinely new problem (e.g. a future menu edit breaking some other
# function's own menu() block) still surfaces instead of going silent too.
) >"${GIT_ROOT}/ohmydebn/cache/menu-tree-flatten.tsv" 2> >(grep -vF 'WARN: no block for show_other_apps_menu' >&2)

# Packaged from a copy without group write (see stage_checkout), taken
# after the cache above so it ships too.
stage_checkout "${GIT_ROOT}/ohmydebn" ohmydebn

fpm -s dir \
  --output-type deb \
  --name ${PACKAGE} \
  --version ${VERSION} \
  --package "${STAGING_DIR}/" \
  --architecture all \
  --maintainer "Doug Burks <https://github.com/dougburks/ohmydebn>" \
  --description "Debonair Debian + Cinnamon desktop for power users" \
  --url "https://ohmydebn.org" \
  --after-install "${BUILD_DIR}/postinst-ohmydebn.sh" \
  --exclude usr/share/ohmydebn/.git \
  --exclude usr/share/ohmydebn/themes \
  --exclude usr/share/ohmydebn/tests \
  --exclude usr/share/ohmydebn/.claude \
  --exclude usr/share/ohmydebn/bin/__pycache__ \
  --exclude usr/share/ohmydebn/.github \
  --exclude usr/share/ohmydebn/.gitignore \
  --exclude usr/share/ohmydebn/AGENTS.md \
  --exclude usr/share/ohmydebn/CLAUDE.md \
  --exclude usr/share/ohmydebn/CONTRIBUTING.md \
  --depends curl \
  --depends git \
  --depends mint-cursor-themes \
  --depends mint-themes \
  --depends mint-x-icons \
  --depends mint-y-icons \
  --depends ohmydebn-aether \
  --depends "ohmydebn-caskaydiamononerdfont (>= 3.5.1)" \
  --depends ohmydebn-gtile \
  --depends ohmydebn-templates \
  --depends ohmydebn-themes \
  --depends "ohmydebn-themes-omarchy (>= 4.0.0-4)" \
  --depends toilet \
  --depends toilet-fonts \
  --depends ttfx \
  --depends xdotool \
  "${STAGED_DIR}/"=/usr/share/${PACKAGE} \
  "${STAGED_DIR}/bin/omarchy-theme-set"=/usr/bin/omarchy-theme-set \
  "${STAGED_DIR}/config/icons/ohmydebn-menu-symbolic.svg"=/usr/share/icons/hicolor/scalable/apps/ohmydebn-menu-symbolic.svg \
  "${STAGED_DIR}/config/icons/ohmydebn-menu-outline-symbolic.svg"=/usr/share/icons/hicolor/scalable/apps/ohmydebn-menu-outline-symbolic.svg \
  "${STAGED_DIR}/config/icons/ohmydebn.svg"=/usr/share/icons/hicolor/scalable/apps/ohmydebn.svg

echo
ls -alh "${STAGING_DIR}"/${PACKAGE}_*.deb
echo
include_testing ${PACKAGE} "${STAGING_DIR}/${PACKAGE}_${VERSION}_all.deb"

upload_testing
