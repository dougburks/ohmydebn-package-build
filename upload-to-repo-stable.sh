#!/bin/bash

cd ohmydebn-packages

# Include packages that have standard naming conventions
for PACKAGE in cliamp \
  mint-themes \
  mint-x-icons \
  ohmydebn-aether \
  ohmydebn-caskaydiamononerdfont \
  ohmydebn-caskaydiamononerdfontmono \
  ohmydebn-caskaydiamononerdfontpropo \
  ohmydebn-gtile \
  ohmydebn-opencode-cli \
  ohmydebn-templates \
  ohmydebn-themes-catppuccin-latte \
  ohmydebn-themes-catppuccin \
  ohmydebn-themes-ethereal \
  ohmydebn-themes-everforest \
  ohmydebn-themes-flexoki-light \
  ohmydebn-themes-gruvbox \
  ohmydebn-themes-hackerman \
  ohmydebn-themes-kanagawa \
  ohmydebn-themes-lumon \
  ohmydebn-themes-matte-black \
  ohmydebn-themes-miasma \
  ohmydebn-themes-nord \
  ohmydebn-themes-omarchy \
  ohmydebn-themes-osaka-jade \
  ohmydebn-themes-retro-82 \
  ohmydebn-themes-ristretto \
  ohmydebn-themes-rose-pine \
  ohmydebn-themes-tokyo-night \
  ohmydebn-themes-vantablack \
  ohmydebn-themes-white \
  ohmydebn-themes \
  ohmydebn \
  touchegg; do
  reprepro remove trixie ${PACKAGE}
  reprepro -b . includedeb trixie ../${PACKAGE}_*
done

# Include packages with non-standard naming conventions
reprepro remove trixie localsend
reprepro -b . includedeb trixie ../LocalSend-*

git add -A
git commit -m "update packages"
git push

cd - >/dev/null
