# shellcheck shell=bash
# Sourced by build-package-*.sh and upload-to-repo-*.sh.
#
# All paths are derived from this file's location rather than the caller's
# working directory, so the scripts can be run from anywhere. Built and
# downloaded .deb files go to STAGING_DIR instead of cluttering ~/git.
# STAGING_DIR and the repo paths can be overridden from the environment
# (e.g. to test upload-to-repo-stable.sh against a copy of the repo).

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_ROOT="$(dirname "${BUILD_DIR}")"
: "${STAGING_DIR:=${GIT_ROOT}/ohmydebn-packages-staging}"
: "${TESTING_REPO:=${GIT_ROOT}/ohmydebn-packages-testing}"
: "${STABLE_REPO:=${GIT_ROOT}/ohmydebn-packages}"
# Files a build creates (downloaded, extracted, compiled) are packaged
# with the mode they get here, and fpm keeps it: with a desktop's usual
# umask 0002 they were group-writable in the installed system. Files
# from a git checkout keep the checkout's own modes, so they're packaged
# from a copy instead (stage_checkout below).
umask 022

mkdir -p "${STAGING_DIR}"

# Throwaway directory, removed when the script exits (even on failure).
# TMPDIR points into it because fpm leaves empty studtmp-* dirs behind.
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT
export TMPDIR="${WORK_DIR}"

# Every build script's downloads go through this. A stalled connection
# otherwise waits out wget's 15-minute default read timeout (with no connect
# timeout at all) in silence, since the scripts use -q; time out and retry
# instead.
wget() {
  command wget --timeout=30 --tries=3 "$@"
}

# Download a GitHub release asset into the current directory and check it
# against the sha256 digest GitHub publishes for it.
# Usage: download_verified <owner/repo> <tag> <asset>
download_verified() {
  local repo="$1" tag="$2" asset="$3" digest
  digest=$(wget -q -O - "https://api.github.com/repos/${repo}/releases/tags/${tag}" |
    jq -r --arg name "${asset}" '.assets[] | select(.name == $name) | .digest')
  if [[ ! "${digest}" =~ ^sha256:[0-9a-f]{64}$ ]]; then
    echo "No sha256 digest published for ${repo} ${tag} ${asset}" >&2
    exit 1
  fi
  wget -q "https://github.com/${repo}/releases/download/${tag}/${asset}"
  echo "${digest#sha256:}  ${asset}" | sha256sum -c -
}

# Copy a git checkout (without its .git) into WORK_DIR, with group and
# other write removed, and set STAGED_DIR to the copy. Packages are built
# from the copy because fpm keeps each file's mode, and a checkout made
# under a desktop's umask 0002 is group-writable throughout.
# The copy is of the working tree, so it stops unless the checkout (just
# the given directory, for one inside a larger repo like ohmydebn/themes)
# matches its commit: uncommitted edits and untracked scratch files would
# otherwise ship in the package. Ignored files don't count, which lets
# ohmydebn's build-time cache/ through.
# Usage: stage_checkout <checkout dir> <name>
stage_checkout() {
  local status
  if ! status=$(git -C "$1" status --porcelain --untracked-files=all -- .); then
    echo "$1 isn't a git checkout" >&2
    exit 1
  fi
  if [[ -n "${status}" ]]; then
    echo "$1 has changes that aren't committed; commit or remove them first:" >&2
    git -C "$1" status --short --untracked-files=all -- . >&2
    exit 1
  fi
  STAGED_DIR="${WORK_DIR}/checkout/$2"
  mkdir -p "${STAGED_DIR}"
  tar -C "$1" --exclude=./.git -cf - . | tar -C "${STAGED_DIR}" -xf -
  chmod -R go-w "${STAGED_DIR}"
}

# The Omarchy release the Omarchy themes are packaged from. The themes come
# from the omarchy checkout next to this repo as it stands, so without this
# a `git pull` there quietly packaged whatever its branch had reached (a
# release candidate's renamed backgrounds and replaced themes, say). The
# intros package checks it too: it ships a clip only for a background this
# release has. To move to a new release, check out its tag in the omarchy
# checkout and change this.
OMARCHY_THEMES_TAG="v4.0.0"

# Stop unless the omarchy checkout is at OMARCHY_THEMES_TAG, with nothing in
# themes/ changed or added since.
# Usage: require_omarchy_checkout <omarchy checkout dir>
require_omarchy_checkout() {
  local dir="$1" tag_commit
  if ! tag_commit=$(git -C "${dir}" rev-parse -q --verify "refs/tags/${OMARCHY_THEMES_TAG}^{commit}"); then
    echo "${dir} has no tag ${OMARCHY_THEMES_TAG}; run: git -C ${dir} fetch --tags" >&2
    exit 1
  fi
  if [[ "$(git -C "${dir}" rev-parse HEAD)" != "${tag_commit}" ]]; then
    echo "${dir} is at $(git -C "${dir}" describe --tags --always HEAD), not ${OMARCHY_THEMES_TAG}" >&2
    echo "Run: git -C ${dir} checkout ${OMARCHY_THEMES_TAG} (or change OMARCHY_THEMES_TAG in common.sh)" >&2
    exit 1
  fi
  if [[ -n "$(git -C "${dir}" status --porcelain --untracked-files=all -- themes)" ]]; then
    echo "${dir}/themes has changes not in ${OMARCHY_THEMES_TAG}:" >&2
    git -C "${dir}" status --short --untracked-files=all -- themes >&2
    exit 1
  fi
}

# Switch to WORK_DIR for downloads and extracted files.
enter_work_dir() {
  cd "${WORK_DIR}" || exit 1
}

# Replace a package in the testing repo with the given .deb file(s).
# Usage: include_testing <package> <deb>...
include_testing() {
  local pkg="$1" deb
  shift
  reprepro -b "${TESTING_REPO}" remove trixie "${pkg}"
  for deb in "$@"; do
    reprepro -b "${TESTING_REPO}" includedeb trixie "${deb}"
  done
}

# Sync the testing repo to R2 unless SKIP_UPLOAD=1.
# Called once at the end of each build-package-*.sh.
upload_testing() {
  if [ "${SKIP_UPLOAD:-0}" = "1" ]; then
    echo
    echo "SKIP_UPLOAD=1, not syncing testing repo to R2"
    return
  fi
  echo
  echo "Uploading testing repo"
  "${BUILD_DIR}/upload-to-repo-testing.sh"
}
