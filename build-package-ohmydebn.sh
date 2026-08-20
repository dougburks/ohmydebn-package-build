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
  # Matches every real caller of menu_tree_flatten() (ohmydebn-menu-picker,
  # tests/consistency.sh) - MT_SKIP_LABELS is baked into whatever gets
  # cached at compute time, so this has to agree with them or Apps would
  # leak back into search results once this shipped cache is in play.
  MT_SKIP_LABELS=(Apps)
  _mt_flatten_uncached ohmydebn/bin/ohmydebn-menu
) >ohmydebn/cache/menu-tree-flatten.tsv

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
