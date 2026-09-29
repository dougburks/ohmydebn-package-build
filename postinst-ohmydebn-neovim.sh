#!/bin/sh
set -e

# Register nvim for the same alternatives, at the same priority, as Debian's
# neovim package, which ohmydebn-neovim replaces: vi, vim, editor (and so
# sudoedit and git's default editor), ex, view and vimdiff keep working the
# way they did.

if [ "$1" = "configure" ] || [ "$1" = "abort-upgrade" ] || [ "$1" = "abort-deconfigure" ] || [ "$1" = "abort-remove" ]; then
  update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 30 \
    --slave /usr/share/man/man1/editor.1.gz editor.1.gz /usr/share/man/man1/nvim.1.gz
  update-alternatives --install /usr/bin/ex ex /usr/libexec/ohmydebn-neovim/ex 30
  update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 30
  update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 30
  update-alternatives --install /usr/bin/view view /usr/libexec/ohmydebn-neovim/view 30
  update-alternatives --install /usr/bin/vimdiff vimdiff /usr/libexec/ohmydebn-neovim/vimdiff 30
fi
