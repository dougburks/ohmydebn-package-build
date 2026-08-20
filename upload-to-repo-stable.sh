#!/bin/bash

cd ohmydebn-packages

OMARCHY_THEMES_DIR=~/git/omarchy/themes

# Dynamically determine the list of omarchy theme packages
THEME_PACKAGES=()
for dir in "${OMARCHY_THEMES_DIR}"/*/; do
  THEME_PACKAGES+=("ohmydebn-themes-$(basename "$dir")")
done

# Include packages that have standard naming conventions
for PACKAGE in \
  cliamp \
  mint-cursor-themes \
  mint-themes \
  mint-x-icons \
  mint-y-icons \
  ohmydebn-aether \
  ohmydebn-caskaydiamononerdfont \
  ohmydebn-caskaydiamononerdfontmono \
  ohmydebn-caskaydiamononerdfontpropo \
  ohmydebn-gtile \
  ohmydebn-opencode-cli \
  ohmydebn-templates \
  "${THEME_PACKAGES[@]}" \
  ohmydebn-themes-omarchy \
  ohmydebn-themes \
  ohmydebn \
  spice-vdagent \
  touchegg \
  ttfx; do
  echo
  echo "Package: $PACKAGE"
  reprepro remove trixie ${PACKAGE}
  reprepro -b . includedeb trixie ../${PACKAGE}_*
done

# Include packages with non-standard naming conventions
echo
echo "Package: localsend"
reprepro remove trixie localsend
reprepro -b . includedeb trixie ../LocalSend-*

# Deploy to Cloudflare R2
rclone sync . "r2:ohmydebn-packages" \
  --exclude ".git/**" \
  --exclude "README.md" \
  --s3-no-check-bucket \
  --s3-no-head \
  --no-update-modtime \
  --ignore-checksum

cd - >/dev/null

echo
echo "If pushing modified packages, you will need to manually purge Cloudflare cache!"
