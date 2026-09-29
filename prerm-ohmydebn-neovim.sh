#!/bin/sh
set -e

# Undo postinst-ohmydebn-neovim.sh when the package is removed (not on an
# upgrade, where the new version's postinst registers the same paths).

if [ "$1" = "remove" ]; then
  update-alternatives --remove vimdiff /usr/libexec/ohmydebn-neovim/vimdiff
  update-alternatives --remove view /usr/libexec/ohmydebn-neovim/view
  update-alternatives --remove vim /usr/bin/nvim
  update-alternatives --remove vi /usr/bin/nvim
  update-alternatives --remove ex /usr/libexec/ohmydebn-neovim/ex
  update-alternatives --remove editor /usr/bin/nvim
fi
