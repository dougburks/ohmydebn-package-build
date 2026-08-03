#!/bin/bash

PACKAGE="ohmydebn"
VERSION=$(cat ohmydebn/VERSION)
rm -f ${PACKAGE}_*.deb

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
  --depends alacritty \
  --depends bat \
  --depends binutils \
  --depends btop \
  --depends cava \
  --depends chromium \
  --depends chrony \
  --depends cinnamon-desktop-environment \
  --depends curl \
  --depends duf \
  --depends ethtool \
  --depends eza \
  --depends ffmpeg \
  --depends fzf \
  --depends galculator \
  --depends gcc \
  --depends gcolor3 \
  --depends gir1.2-gtk4layershell-1.0 \
  --depends git \
  --depends gimp \
  --depends grc \
  --depends gufw \
  --depends gum \
  --depends gvfs-backends \
  --depends htop \
  --depends imagemagick \
  --depends iperf3 \
  --depends jq \
  --depends keepassxc \
  --depends lazygit \
  --depends libadwaita-1-dev \
  --depends libglib2.0-bin \
  --depends libgtk-4-dev \
  --depends libgtk4-layer-shell0 \
  --depends libnotify-bin \
  --depends libspa-0.2-bluetooth \
  --depends lshw \
  --depends mint-cursor-themes \
  --depends mint-themes \
  --depends mint-x-icons \
  --depends mint-y-icons \
  --depends neovim \
  --depends ohmydebn-aether \
  --depends ohmydebn-caskaydiamononerdfont \
  --depends ohmydebn-caskaydiamononerdfontmono \
  --depends ohmydebn-caskaydiamononerdfontpropo \
  --depends ohmydebn-gtile \
  --depends ohmydebn-templates \
  --depends ohmydebn-themes \
  --depends ohmydebn-themes-omarchy \
  --depends pdftk-java \
  --depends pipx \
  --depends pkg-config \
  --depends python-is-python3 \
  --depends python3-terminaltexteffects \
  --depends ripgrep \
  --depends ristretto \
  --depends rofi \
  --depends rclone \
  --depends rsync \
  --depends screenfetch \
  --depends shellcheck \
  --depends starship \
  --depends toilet \
  --depends toilet-fonts \
  --depends traceroute \
  --depends ufw \
  --depends vim \
  --depends wget \
  --depends xdotool \
  --depends xournalpp \
  --depends yaru-theme-gtk \
  --depends yaru-theme-icon \
  --depends yq \
  --depends zip \
  --depends zoxide \
  --depends zsh \
  --depends zsh-autosuggestions \
  --depends zsh-syntax-highlighting \
  ~/git/ohmydebn/=/usr/share/${PACKAGE} \
  ~/git/ohmydebn/bin/omarchy-theme-set=/usr/bin/omarchy-theme-set

echo
ls -alh ${PACKAGE}_*.deb
echo
cd ohmydebn-packages-testing
reprepro remove trixie ${PACKAGE}
reprepro -b . includedeb trixie ../${PACKAGE}_${VERSION}_all.deb
cd - >/dev/null
