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
