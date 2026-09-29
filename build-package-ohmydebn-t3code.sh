#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

VERSION="0.0.42"
# Packaging revision: bump it when only this script's packaging changes
# (so apt sees an upgrade), and reset it to 1 for a new upstream VERSION.
REVISION="3"
PACKAGE_VERSION="${VERSION}-ohmydebn${REVISION}"
NAME="t3code"
AUTHOR="pingdotgg"
DESC="Desktop control surface for local coding agents"
PACKAGE_NAME="ohmydebn-${NAME}"
REPO="${AUTHOR}/${NAME}"
URL="https://github.com/${REPO}"
INSTALL_DIR="/usr/lib/${PACKAGE_NAME}"

rm -f "${STAGING_DIR}"/${PACKAGE_NAME}*.deb
enter_work_dir

# Each release ships a t3-<ver>-linux-<arch>.tar.gz and a
# T3-Code-<ver>-<arch>.AppImage. The tarball is only the headless `t3`
# server (web UI in a browser, self-updates into ~/.local); the AppImage is
# the Electron desktop app, which bundles its own server. We want the
# desktop app, unpacked into ${INSTALL_DIR} the same way the AUR t3code-bin
# package does it, so it runs without FUSE and without self-updating
# (electron-updater only updates when running as an actual AppImage).
#
# The AppImage can't be run to --appimage-extract it for a foreign
# architecture, so instead we unsquashfs its payload directly: the squashfs
# image starts right after the ELF runtime, at e_shoff + e_shentsize * e_shnum.
# Checksums come from the electron-updater latest-linux*.yml files, since
# SHA256SUMS only covers the tarballs.
declare -A GH_ARCH=(
  [amd64]="x86_64"
  [arm64]="arm64"
)
declare -A UPDATER_YML=(
  [amd64]="latest-linux.yml"
  [arm64]="latest-linux-arm64.yml"
)

appimage_offset() {
  python3 - "$1" <<'EOF'
import struct, sys
with open(sys.argv[1], "rb") as f:
    hdr = f.read(64)
assert hdr[:4] == b"\x7fELF" and hdr[4] == 2 and hdr[5] == 1, "not a little-endian ELF64 AppImage"
shoff = struct.unpack_from("<Q", hdr, 0x28)[0]
shentsize, shnum = struct.unpack_from("<HH", hdr, 0x3A)
print(shoff + shentsize * shnum)
EOF
}

for ARCHITECTURE in amd64 arm64; do
  APPIMAGE="T3-Code-${VERSION}-${GH_ARCH[${ARCHITECTURE}]}.AppImage"
  YML="${UPDATER_YML[${ARCHITECTURE}]}"

  echo
  echo "Downloading ${ARCHITECTURE} AppImage"
  wget -q "https://github.com/${REPO}/releases/download/v${VERSION}/${APPIMAGE}"
  wget -q "https://github.com/${REPO}/releases/download/v${VERSION}/${YML}"
  EXPECTED=$(awk -v f="${APPIMAGE}" '$1 == "-" && $2 == "url:" && $3 == f {found = 1; next} found && $1 == "sha512:" {print $2; exit}' "${YML}")
  ACTUAL=$(openssl dgst -sha512 -binary "${APPIMAGE}" | base64 -w0)
  if [ -z "${EXPECTED}" ] || [ "${EXPECTED}" != "${ACTUAL}" ]; then
    echo "SHA512 mismatch for ${APPIMAGE}" >&2
    exit 1
  fi
  echo "${APPIMAGE}: OK"

  echo
  echo "Extracting ${ARCHITECTURE} AppImage"
  OFFSET=$(appimage_offset "${APPIMAGE}")
  unsquashfs -q -o "${OFFSET}" -d squashfs-root "${APPIMAGE}" >/dev/null

  mkdir -p "pkgroot${INSTALL_DIR}" pkgroot/usr/share/applications
  cp -a squashfs-root/. "pkgroot${INSTALL_DIR}/"

  # T3 Code finds each agent by its usual command name on PATH (opencode,
  # codex, grok, claude). OhMyDebn installs OpenCode as opencode-cli and
  # Codex and Grok Build outside PATH, so agent-bin links them under the
  # expected names, and
  # the launcher adds agent-bin to the end of PATH for T3 Code only. T3
  # Code puts the login shell's PATH first and keeps inherited entries
  # after it, so a real opencode/codex elsewhere on PATH still wins. A link
  # to an agent that isn't installed just dangles, and T3 Code reports that
  # agent as missing, as it would without the link.
  mkdir -p "pkgroot${INSTALL_DIR}/agent-bin"
  ln -s /usr/bin/opencode-cli "pkgroot${INSTALL_DIR}/agent-bin/opencode"
  ln -s /usr/lib/ohmydebn-codex-cli/bin/codex "pkgroot${INSTALL_DIR}/agent-bin/codex"
  ln -s /usr/lib/ohmydebn-grok-build/grok "pkgroot${INSTALL_DIR}/agent-bin/grok"
  cat >"pkgroot${INSTALL_DIR}/ohmydebn-t3code-launch" <<EOF
#!/bin/sh
PATH="\${PATH}:${INSTALL_DIR}/agent-bin"
# Packaged agents are updated by apt, never by themselves.
GROK_DISABLE_AUTOUPDATER=1
export PATH GROK_DISABLE_AUTOUPDATER
exec ${INSTALL_DIR}/AppRun "\$@"
EOF
  chmod 755 "pkgroot${INSTALL_DIR}/ohmydebn-t3code-launch"

  for ICON in squashfs-root/usr/share/icons/hicolor/*/apps/t3code.png; do
    SIZE_DIR="${ICON%/apps/t3code.png}"
    install -Dm644 "${ICON}" "pkgroot/usr/share/icons/hicolor/${SIZE_DIR##*/}/apps/t3code.png"
  done

  # StartupWMClass is the window's real WM_CLASS class (checked with xprop),
  # so the panel groups the running window with this launcher. Upstream's
  # own .desktop says "t3code", which matches neither WM_CLASS string.
  cat >pkgroot/usr/share/applications/t3code.desktop <<EOF
[Desktop Entry]
Name=T3 Code
Comment=${DESC}
Exec=${INSTALL_DIR}/ohmydebn-t3code-launch %U
TryExec=${INSTALL_DIR}/ohmydebn-t3code-launch
Terminal=false
Type=Application
Icon=t3code
StartupWMClass=com.t3tools.T3Code
Categories=Development;
MimeType=x-scheme-handler/t3code;
EOF

  # The AppImage payload is 0700 and new files follow the caller's umask,
  # so normalize everything, then restore the setuid Chromium sandbox.
  chmod -R u=rwX,go=rX pkgroot
  chmod 4755 "pkgroot${INSTALL_DIR}/chrome-sandbox"

  echo
  echo "Building ${ARCHITECTURE} package"
  fpm -s dir -t deb \
    --maintainer "Doug Burks<doug.burks@example.com>" \
    -n "${PACKAGE_NAME}" \
    -v "${PACKAGE_VERSION}" \
    --package "${STAGING_DIR}/" \
    --architecture ${ARCHITECTURE} \
    --description "${DESC}" \
    --url "${URL}" \
    --license "MIT" \
    -d libasound2t64 \
    -d libgbm1 \
    -d libgtk-3-0t64 \
    -d libnss3 \
    -d libsecret-1-0 \
    -d libxkbcommon0 \
    -d xdg-utils \
    -C pkgroot \
    .

  echo
  echo "Removing ${ARCHITECTURE} temp files"
  rm -rf pkgroot squashfs-root "${APPIMAGE}" "${YML}"
done

echo
echo "Including both packages in testing repo"
include_testing ${PACKAGE_NAME} \
  "${STAGING_DIR}/${PACKAGE_NAME}_${PACKAGE_VERSION}_amd64.deb" \
  "${STAGING_DIR}/${PACKAGE_NAME}_${PACKAGE_VERSION}_arm64.deb"

upload_testing
