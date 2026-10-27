#!/bin/bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Oh My Zsh, the Zsh framework OhMyDebn's ~/.zshrc loads, installed once
# for the whole machine in /usr/share/oh-my-zsh. It used to be downloaded
# into each user's ~/.oh-my-zsh by its own installer, from whatever its
# master branch held that day, and from then on it updated itself from
# master every couple of weeks. Packaged, every install runs the one
# commit below, and it changes only when OhMyDebn ships a new one: Oh My
# Zsh skips its own update check when its directory isn't the user's to
# write, and writes its cache to ~/.cache/oh-my-zsh instead.
#
# Oh My Zsh publishes no releases, so it's pinned by commit (git checks
# every object against its hash, so the commit pins the content). To
# update: pick a newer master commit, try it, and change OMZ_COMMIT and
# OMZ_DATE (the commit's date, which the version is made from).
OMZ_COMMIT="d2b7f557cceaddb16ba89bbf8200d8a8df35c4d8"
OMZ_DATE="20261025"
VERSION="0+git${OMZ_DATE}.${OMZ_COMMIT:0:7}"
# Bumped whenever the same commit is rebuilt with changes, so apt upgrades
# existing installs.
REVISION="1"
PACKAGE="ohmydebn-ohmyzsh"

rm -f "${STAGING_DIR}"/${PACKAGE}_*.deb
enter_work_dir

git init -q ohmyzsh
git -C ohmyzsh fetch -q --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "${OMZ_COMMIT}"
git -C ohmyzsh checkout -q FETCH_HEAD
if [[ "$(git -C ohmyzsh rev-parse HEAD)" != "${OMZ_COMMIT}" ]]; then
  echo "Fetched $(git -C ohmyzsh rev-parse HEAD), not ${OMZ_COMMIT}" >&2
  exit 1
fi
if [[ "$(git -C ohmyzsh log -1 --format=%cd --date=format:%Y%m%d)" != "${OMZ_DATE}" ]]; then
  echo "${OMZ_COMMIT} isn't from ${OMZ_DATE}; set OMZ_DATE to its date" >&2
  exit 1
fi

# The tracked files only (no .git), with group and other write removed:
# fpm keeps each file's mode.
STAGE="${WORK_DIR}/stage"
mkdir -p "${STAGE}"
git -C ohmyzsh archive HEAD | tar -C "${STAGE}" -xf -
chmod -R go-w "${STAGE}"

fpm -s dir \
  -t deb \
  -n ${PACKAGE} \
  -v "${VERSION}" \
  --iteration ${REVISION} \
  --package "${STAGING_DIR}/" \
  -a all \
  --license MIT \
  --maintainer "Doug Burks <https://github.com/dougburks/ohmydebn>" \
  --description "Oh My Zsh framework for Zsh, packaged for OhMyDebn (commit ${OMZ_COMMIT:0:7})" \
  --url "https://ohmyz.sh" \
  --depends zsh \
  --depends git \
  "${STAGE}/"=/usr/share/oh-my-zsh \
  "${STAGE}/LICENSE.txt"=/usr/share/doc/${PACKAGE}/copyright

echo
ls -alh "${STAGING_DIR}"/${PACKAGE}_*.deb
echo
include_testing ${PACKAGE} "${STAGING_DIR}/${PACKAGE}_${VERSION}-${REVISION}_all.deb"

upload_testing
