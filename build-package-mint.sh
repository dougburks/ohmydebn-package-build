#!/bin/bash

# ohmydebn previously depended on bibata-cursor-theme
# which conflicts with the newer mint-cursor-themes
# so we need to build a new mint-cursor-themes package
# that has the --conflicts and --replaces flags like this:
# fpm -s deb -t deb \
#  -n mint-cursor-themes \
#  -v 1.0.2-ohmydebn1 \
#  --conflicts bibata-cursor-theme \
#  --replaces bibata-cursor-theme \
#  mint-cursor-themes_1.0.2_all.deb

cd ohmydebn-packages-testing
reprepro remove trixie mint-cursor-themes
reprepro -b . includedeb trixie ../mint-cursor-themes_1.0.2-ohmydebn1_all.deb
reprepro remove trixie mint-themes
reprepro -b . includedeb trixie ../mint-themes_2.3.8_all.deb
reprepro remove trixie mint-x-icons
reprepro -b . includedeb trixie ../mint-x-icons_1.7.5_all.deb
reprepro remove trixie mint-y-icons
reprepro -b . includedeb trixie ../mint-y-icons_1.9.1_all.deb
cd - >/dev/null
