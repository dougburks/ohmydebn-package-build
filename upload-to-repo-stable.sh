#!/bin/bash

cd ohmydebn-packages

for PACKAGE in mint-themes \
  mint-x-icons \
  ohmydebn-aether \
  ohmydebn-caskaydiamononerdfont \
  ohmydebn-caskaydiamononerdfontmono \
  ohmydebn-caskaydiamononerdfontpropo \
  ohmydebn-gtile \
  ohmydebn-templates \
  ohmydebn-themes-catppuccin-latte \
  ohmydebn-themes-catppuccin \
  ohmydebn-themes-ethereal \
  ohmydebn-themes-everforest \
  ohmydebn-themes-flexoki-light \
  ohmydebn-themes-gruvbox \
  ohmydebn-themes-hackerman \
  ohmydebn-themes-kanagawa \
  ohmydebn-themes-matte-black \
  ohmydebn-themes-miasma \
  ohmydebn-themes-nord \
  ohmydebn-themes-omarchy \
  ohmydebn-themes-osaka-jade \
  ohmydebn-themes-ristretto \
  ohmydebn-themes-rose-pine \
  ohmydebn-themes-tokyo-night \
  ohmydebn-themes-vantablack \
  ohmydebn-themes-white \
  ohmydebn-themes \
  ohmydebn; do
  reprepro remove trixie ${PACKAGE}
  reprepro -b . includedeb trixie ../${PACKAGE}_*
done

git add -A
git commit -m "update packages"
git push

cd - >/dev/null
