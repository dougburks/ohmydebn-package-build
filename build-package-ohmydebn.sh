#!/bin/bash

PACKAGE="ohmydebn"
VERSION=$(cat ohmydebn/VERSION)
rm -f ${PACKAGE}_*.deb

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
mkdir -p ohmydebn/cache
rm -f ohmydebn/cache/menu-tree-flatten.tsv
(
  source ohmydebn/bin/ohmydebn-menu-tree
  # No explicit MT_SKIP_LABELS set here on purpose, deliberately relying
  # on ohmydebn-menu-tree's own MT_DEFAULT_SKIP_LABELS ("Other Apps")
  # instead of hand-repeating that literal a third time (alongside
  # ohmydebn-menu-picker's load_leaves() and tests/consistency.sh). That
  # repetition is exactly what once let this copy drift to a stale
  # "Apps" for a long time with no effect (nothing was ever named exactly
  # "Apps", so it skipped nothing) - until a real top-level "Apps"
  # category was added and the mismatch started excluding its entire
  # subtree from the shipped cache instead, confirmed live as the cause
  # of Apps and everything under it missing their submenu "›" marker in
  # an otherwise fully up-to-date installed build. A single default in
  # the sourced ohmydebn-menu-tree can't drift out of sync with itself.
  _mt_flatten_uncached ohmydebn/bin/ohmydebn-menu
# "WARN: no block for show_other_apps_menu" on stderr here is expected,
# not a build failure - show_other_apps_menu deliberately has no static
# menu() call (Other Apps is a live .desktop scan, not something this
# bash-source parser can enumerate - see its own comment in
# ohmydebn-menu), and this is exactly the tool correctly detecting that
# and skipping it rather than silently guessing wrong. Filtered out here
# by exact message text, not by discarding stderr wholesale, so a
# genuinely new problem (e.g. a future menu edit breaking some other
# function's own menu() block) still surfaces instead of going silent too.
) >ohmydebn/cache/menu-tree-flatten.tsv 2> >(grep -vF 'WARN: no block for show_other_apps_menu' >&2)

fpm -s dir \
  --output-type deb \
  --name ${PACKAGE} \
  --version ${VERSION} \
  --architecture all \
  --maintainer "Doug Burks<doug.burks@example.com>" \
  --description "Debonaire Debian + Cinnamon desktop for power users" \
  --url "https://ohmydebn.org" \
  --after-install ohmydebn-package-build/postinst-ohmydebn.sh \
  --exclude usr/share/ohmydebn/.git \
  --exclude usr/share/ohmydebn/themes \
  --exclude usr/share/ohmydebn/tests \
  --depends curl \
  --depends git \
  --depends mint-cursor-themes \
  --depends mint-themes \
  --depends mint-x-icons \
  --depends mint-y-icons \
  --depends ohmydebn-aether \
  --depends ohmydebn-caskaydiamononerdfont \
  --depends ohmydebn-caskaydiamononerdfontmono \
  --depends ohmydebn-caskaydiamononerdfontpropo \
  --depends ohmydebn-gtile \
  --depends ohmydebn-templates \
  --depends ohmydebn-themes \
  --depends ohmydebn-themes-omarchy \
  --depends toilet \
  --depends toilet-fonts \
  --depends ttfx \
  --depends xdotool \
  ~/git/ohmydebn/=/usr/share/${PACKAGE} \
  ~/git/ohmydebn/bin/omarchy-theme-set=/usr/bin/omarchy-theme-set

echo
ls -alh ${PACKAGE}_*.deb
echo
cd ohmydebn-packages-testing
reprepro remove trixie ${PACKAGE}
reprepro -b . includedeb trixie ../${PACKAGE}_${VERSION}_all.deb
cd - >/dev/null
