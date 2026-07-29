#!/bin/bash

PACKAGE="ohmydebn"
VERSION=$(cat ohmydebn/VERSION)
rm -f ${PACKAGE}_*.deb

fpm -s dir \
  -t deb \
  -n ${PACKAGE} \
  -v ${VERSION} \
  -a all \
  --maintainer "Doug Burks<doug.burks@example.com>" \
  --description "Debonaire Debian + Cinnamon desktop for power users" \
  --url "https://ohmydebn.org" \
  --after-install ohmydebn-package-build/postinst-ohmydebn.sh \
  -x usr/share/ohmydebn/.git \
  -x usr/share/ohmydebn/themes \
  -d alacritty \
  -d bat \
  -d bibata-cursor-theme \
  -d binutils \
  -d btop \
  -d cava \
  -d chromium \
  -d chrony \
  -d cinnamon-desktop-environment \
  -d curl \
  -d duf \
  -d ethtool \
  -d eza \
  -d ffmpeg \
  -d fzf \
  -d galculator \
  -d gcc \
  -d gcolor3 \
  -d gir1.2-gtk4layershell-1.0 \
  -d git \
  -d gimp \
  -d grc \
  -d gufw \
  -d gum \
  -d gvfs-backends \
  -d htop \
  -d imagemagick \
  -d iperf3 \
  -d jq \
  -d keepassxc \
  -d lazygit \
  -d libadwaita-1-dev \
  -d libglib2.0-bin \
  -d libgtk-4-dev \
  -d libgtk4-layer-shell0 \
  -d libnotify-bin \
  -d libspa-0.2-bluetooth \
  -d lshw \
  -d mint-themes \
  -d mint-x-icons \
  -d mint-y-icons \
  -d neovim \
  -d ohmydebn-aether \
  -d ohmydebn-caskaydiamononerdfont \
  -d ohmydebn-caskaydiamononerdfontmono \
  -d ohmydebn-caskaydiamononerdfontpropo \
  -d ohmydebn-gtile \
  -d ohmydebn-templates \
  -d ohmydebn-themes \
  -d ohmydebn-themes-omarchy \
  -d pdftk-java \
  -d pipx \
  -d pkg-config \
  -d python-is-python3 \
  -d python3-terminaltexteffects \
  -d ripgrep \
  -d ristretto \
  -d rofi \
  -d rclone \
  -d rsync \
  -d screenfetch \
  -d shellcheck \
  -d starship \
  -d toilet \
  -d toilet-fonts \
  -d traceroute \
  -d ufw \
  -d vim \
  -d wget \
  -d xdotool \
  -d xournalpp \
  -d yaru-theme-gtk \
  -d yaru-theme-icon \
  -d yq \
  -d zip \
  -d zoxide \
  -d zsh \
  -d zsh-autosuggestions \
  -d zsh-syntax-highlighting \
  ~/git/ohmydebn/=/usr/share/${PACKAGE} \
  ~/git/ohmydebn/bin/omarchy-theme-set=/usr/bin/omarchy-theme-set

echo
ls -alh ${PACKAGE}_*.deb
echo
cd ohmydebn-packages-testing
reprepro remove trixie ${PACKAGE}
reprepro -b . includedeb trixie ../${PACKAGE}_${VERSION}_all.deb
cd - >/dev/null
