#!/bin/bash
#
# Tests for require_omarchy_checkout in common.sh, which both Omarchy theme
# build scripts run before packaging anything from the omarchy checkout:
# it must be at OMARCHY_THEMES_TAG with nothing in themes/ changed or added.
# Without it, a `git pull` there was quietly packaged. Each case is a
# scratch git repository standing in for the checkout; STAGING_DIR points
# into scratch space so sourcing common.sh touches nothing real.
# Usage: tests/test-require-omarchy-checkout.sh

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "${SCRATCH}"' EXIT
PASS=0
FAIL=0

# Prints the check's exit status and its error output, from a fresh shell
# each time (it exits on failure, and common.sh sets its own traps).
check() {
  STAGING_DIR="${SCRATCH}/staging" bash -c '
    source "$1/../common.sh"
    require_omarchy_checkout "$2"
  ' _ "${TESTS_DIR}" "$1" 2>&1
  echo "exit $?"
}

expect() {
  local name="$1" want_exit="$2" want_text="$3" got="$4"
  if [[ "${got}" == *"exit ${want_exit}"* && "${got}" == *"${want_text}"* ]]; then
    echo "  ok - ${name}"
    PASS=$((PASS + 1))
  else
    echo "  FAIL - ${name}"
    sed 's/^/      /' <<<"${got}"
    FAIL=$((FAIL + 1))
  fi
}

TAG=$(STAGING_DIR="${SCRATCH}/staging" bash -c 'source "$1/../common.sh"; echo "${OMARCHY_THEMES_TAG}"' _ "${TESTS_DIR}")

# A checkout with the release tagged, then one more commit after it.
REPO="${SCRATCH}/omarchy"
git init -q "${REPO}"
git -C "${REPO}" config user.email test@example.com
git -C "${REPO}" config user.name test
# Whatever the maintainer's own git config asks for, a signed tag would
# need a key and a message.
git -C "${REPO}" config tag.gpgSign false
git -C "${REPO}" config commit.gpgSign false
mkdir -p "${REPO}/themes/nord/backgrounds"
echo one >"${REPO}/themes/nord/backgrounds/1-city.png"
git -C "${REPO}" add -A
git -C "${REPO}" commit -qm release
git -C "${REPO}" tag "${TAG}"
echo two >"${REPO}/themes/nord/backgrounds/1-city.webp"
git -C "${REPO}" add -A
git -C "${REPO}" commit -qm later

echo "=== require_omarchy_checkout (${TAG}) ==="

expect "past the tag (a git pull): stops, naming where it is" 1 "not ${TAG}" "$(check "${REPO}")"

git -C "${REPO}" checkout -q "${TAG}"
expect "at the tag: passes" 0 "" "$(check "${REPO}")"

echo edited >"${REPO}/themes/nord/backgrounds/1-city.png"
expect "a theme file changed: stops, listing it" 1 "themes/nord/backgrounds/1-city.png" "$(check "${REPO}")"
git -C "${REPO}" checkout -q -- themes

echo new >"${REPO}/themes/nord/backgrounds/2-extra.webp"
expect "a file added under themes/: stops, listing it" 1 "2-extra.webp" "$(check "${REPO}")"
rm "${REPO}/themes/nord/backgrounds/2-extra.webp"

echo notes >"${REPO}/NOTES.txt"
expect "a change outside themes/: passes" 0 "" "$(check "${REPO}")"
rm "${REPO}/NOTES.txt"

git -C "${REPO}" tag -d "${TAG}" >/dev/null
expect "the tag not fetched: stops, saying to fetch" 1 "fetch --tags" "$(check "${REPO}")"

echo
echo "${PASS}/$((PASS + FAIL)) passed"
[[ ${FAIL} -eq 0 ]]
