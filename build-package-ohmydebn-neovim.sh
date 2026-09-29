#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

VERSION="0.12.5"
TREE_SITTER_VERSION="0.27.0"
DESC="Neovim, a Vim-based text editor (upstream release)"
PACKAGE_NAME="ohmydebn-neovim"
URL="https://neovim.io"
INSTALL_DIR="/usr/lib/${PACKAGE_NAME}"
LIBEXEC_DIR="/usr/libexec/${PACKAGE_NAME}"

rm -f "${STAGING_DIR}"/${PACKAGE_NAME}_*.deb
enter_work_dir

# Debian and Ubuntu ship Neovim versions years apart (0.10 in Debian 13, 0.9
# in Ubuntu 24.04), and LazyVim's plugins follow current Neovim, so OhMyDebn
# ships one tested version everywhere: upstream's own release build, which
# needs only glibc >= 2.34, libm and libgcc.
#
# The package takes over from Debian's neovim and neovim-runtime (Provides,
# Conflicts, Replaces) and registers the same alternatives at the same
# priority (postinst-ohmydebn-neovim.sh). It's named ohmydebn-neovim rather
# than neovim so that a distro shipping a higher neovim version can never
# replace it silently under OhMyDebn's tested plugin set.
#
# It also ships the tree-sitter CLI: nvim-treesitter needs it to install a
# parser, and Debian 13's tree-sitter-cli (0.22) is too old for it.
declare -A NVIM_ARCH=(
  [amd64]="x86_64"
  [arm64]="arm64"
)
declare -A TREE_SITTER_ARCH=(
  [amd64]="x64"
  [arm64]="arm64"
)

for ARCHITECTURE in amd64 arm64; do
  NVIM_TARBALL="nvim-linux-${NVIM_ARCH[${ARCHITECTURE}]}.tar.gz"
  TREE_SITTER_GZ="tree-sitter-linux-${TREE_SITTER_ARCH[${ARCHITECTURE}]}.gz"

  echo
  echo "Downloading ${ARCHITECTURE} release"
  download_verified neovim/neovim "v${VERSION}" "${NVIM_TARBALL}"
  download_verified tree-sitter/tree-sitter "v${TREE_SITTER_VERSION}" "${TREE_SITTER_GZ}"

  # Upstream's tree stays whole under INSTALL_DIR: nvim finds its runtime
  # files relative to its own (symlink-resolved) path.
  mkdir -p pkgroot"${INSTALL_DIR}" pkgroot/usr/bin pkgroot"${LIBEXEC_DIR}" \
    pkgroot/usr/share/man/man1 pkgroot/usr/share/applications \
    pkgroot/usr/share/icons/hicolor/128x128/apps pkgroot/usr/share/doc/${PACKAGE_NAME}
  tar xzf "${NVIM_TARBALL}" -C pkgroot"${INSTALL_DIR}" --strip-components=1
  ln -s "../lib/${PACKAGE_NAME}/bin/nvim" pkgroot/usr/bin/nvim
  gunzip -c "${TREE_SITTER_GZ}" >pkgroot/usr/bin/tree-sitter

  # The same small wrappers Debian ships for the ex, view and vimdiff
  # alternatives.
  printf '#!/bin/sh\nexec /usr/bin/nvim -e "$@"\n' >pkgroot"${LIBEXEC_DIR}"/ex
  printf '#!/bin/sh\nexec /usr/bin/nvim -R "$@"\n' >pkgroot"${LIBEXEC_DIR}"/view
  printf '#!/bin/sh\nexec /usr/bin/nvim -d "$@"\n' >pkgroot"${LIBEXEC_DIR}"/vimdiff

  # The man page (also the editor alternative's man page), desktop entry and
  # icon go where the system looks for them.
  gzip -9n -c pkgroot"${INSTALL_DIR}"/share/man/man1/nvim.1 >pkgroot/usr/share/man/man1/nvim.1.gz
  mv pkgroot"${INSTALL_DIR}"/share/applications/nvim.desktop pkgroot/usr/share/applications/
  mv pkgroot"${INSTALL_DIR}"/share/icons/hicolor/128x128/apps/nvim.png pkgroot/usr/share/icons/hicolor/128x128/apps/
  rm -rf pkgroot"${INSTALL_DIR}"/share/{man,applications,icons}
  wget -q -O pkgroot/usr/share/doc/${PACKAGE_NAME}/LICENSE.txt "https://raw.githubusercontent.com/neovim/neovim/v${VERSION}/LICENSE.txt"

  chmod -R u=rwX,go=rX pkgroot
  chmod 755 pkgroot"${INSTALL_DIR}"/bin/nvim pkgroot/usr/bin/tree-sitter pkgroot"${LIBEXEC_DIR}"/*

  # A foreign-architecture binary can't run here, so only the native one is
  # smoke-tested - through the /usr/bin symlink, so that finding the runtime
  # files from a symlinked binary is checked too.
  if [ "${ARCHITECTURE}" = "$(dpkg --print-architecture)" ]; then
    pkgroot/usr/bin/nvim --version | grep -qF "NVIM v${VERSION}"
    RUNTIME=$(HOME="${WORK_DIR}" pkgroot/usr/bin/nvim --clean --headless -c 'lua io.write(vim.env.VIMRUNTIME)' -c qa)
    [ "${RUNTIME}" = "$(realpath pkgroot"${INSTALL_DIR}")/share/nvim/runtime" ]
    pkgroot/usr/bin/tree-sitter --version | grep -qF "tree-sitter ${TREE_SITTER_VERSION}"
  fi

  echo
  echo "Building ${ARCHITECTURE} package"
  fpm -s dir -t deb \
    -n "${PACKAGE_NAME}" \
    -v "${VERSION}" \
    --package "${STAGING_DIR}/" \
    --architecture ${ARCHITECTURE} \
    --description "${DESC}" \
    --url "${URL}" \
    --maintainer "Doug Burks<doug.burks@example.com>" \
    --license "Apache-2.0 and Vim" \
    --depends "libc6 (>= 2.39)" \
    --depends "libgcc-s1" \
    --depends "xclip | xsel | wl-clipboard" \
    --deb-recommends "xxd" \
    --deb-recommends "python3-pynvim" \
    --provides "editor" \
    --provides "neovim (= ${VERSION})" \
    --provides "neovim-runtime (= ${VERSION})" \
    --provides "tree-sitter-cli (= ${TREE_SITTER_VERSION})" \
    --conflicts "neovim" \
    --conflicts "neovim-runtime" \
    --conflicts "tree-sitter-cli" \
    --replaces "neovim" \
    --replaces "neovim-runtime" \
    --replaces "tree-sitter-cli" \
    --after-install "${BUILD_DIR}/postinst-ohmydebn-neovim.sh" \
    --before-remove "${BUILD_DIR}/prerm-ohmydebn-neovim.sh" \
    -C pkgroot \
    .

  echo
  echo "Removing ${ARCHITECTURE} temp files"
  rm -rf pkgroot "${NVIM_TARBALL}" "${TREE_SITTER_GZ}"
done

echo
echo "Including both packages in testing repo"
include_testing ${PACKAGE_NAME} \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_amd64.deb" \
  "${STAGING_DIR}/${PACKAGE_NAME}_${VERSION}_arm64.deb"

upload_testing
