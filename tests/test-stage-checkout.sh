#!/bin/bash
#
# Tests for stage_checkout in common.sh, which the ohmydebn, themes,
# templates and gtile build scripts package from. It copies the working
# tree, so it must stop when the checkout has uncommitted or untracked
# files, which would otherwise ship. Each case is a scratch git repository
# standing in for the checkout; STAGING_DIR points into scratch space so
# sourcing common.sh touches nothing real.
# Usage: tests/test-stage-checkout.sh

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "${SCRATCH}"' EXIT
PASS=0
FAIL=0

# Prints what the staged copy holds (its files, sorted, with "mode path"),
# the error output and the exit status, from a fresh shell each time (it
# exits on failure, and common.sh sets its own traps).
check() {
  STAGING_DIR="${SCRATCH}/staging" bash -c '
    source "$1/../common.sh"
    stage_checkout "$2" test
    cd "${STAGED_DIR}" && find . -type f -printf "%m %P\n" | sort
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

REPO="${SCRATCH}/ohmydebn"
git init -q "${REPO}"
git -C "${REPO}" config user.email test@example.com
git -C "${REPO}" config user.name test
git -C "${REPO}" config commit.gpgSign false
mkdir -p "${REPO}/bin" "${REPO}/themes/nord"
echo tool >"${REPO}/bin/tool"
chmod 775 "${REPO}/bin/tool"
echo colors >"${REPO}/themes/nord/colors.toml"
printf '/cache/\n' >"${REPO}/.gitignore"
git -C "${REPO}" add -A
git -C "${REPO}" commit -qm initial

echo "=== stage_checkout ==="

got=$(check "${REPO}")
expect "clean: passes" 0 "bin/tool" "${got}"
expect "clean: the copy loses group write" 0 "755 bin/tool" "${got}"
if [[ "${got}" != *".git/"* ]]; then
  echo "  ok - clean: .git isn't copied"
  PASS=$((PASS + 1))
else
  echo "  FAIL - clean: .git isn't copied"
  FAIL=$((FAIL + 1))
fi

echo edited >"${REPO}/bin/tool"
expect "a committed file changed: stops, listing it" 1 "bin/tool" "$(check "${REPO}")"
git -C "${REPO}" checkout -q -- bin

echo scratch >"${REPO}/bin/notes.txt"
expect "an untracked file: stops, listing it" 1 "bin/notes.txt" "$(check "${REPO}")"
rm "${REPO}/bin/notes.txt"

mkdir -p "${REPO}/scratch/deep"
echo scratch >"${REPO}/scratch/deep/file"
expect "an untracked file in a new directory: stops, listing the file" 1 "scratch/deep/file" "$(check "${REPO}")"
rm -r "${REPO}/scratch"

echo staged >"${REPO}/bin/new"
git -C "${REPO}" add bin/new
expect "a staged but uncommitted file: stops" 1 "bin/new" "$(check "${REPO}")"
git -C "${REPO}" rm -q --cached bin/new
rm "${REPO}/bin/new"

mkdir -p "${REPO}/cache"
echo built >"${REPO}/cache/menu.tsv"
expect "an ignored file (the build's cache/): passes and is copied" 0 "cache/menu.tsv" "$(check "${REPO}")"
rm -r "${REPO}/cache"

echo edited >"${REPO}/bin/tool"
expect "a subdirectory checks only itself: a change elsewhere passes" 0 "nord/colors.toml" "$(check "${REPO}/themes")"
git -C "${REPO}" checkout -q -- bin

echo new >"${REPO}/themes/nord/extra.toml"
expect "a subdirectory: a change inside it stops" 1 "extra.toml" "$(check "${REPO}/themes")"
rm "${REPO}/themes/nord/extra.toml"

mkdir -p "${SCRATCH}/plain"
echo file >"${SCRATCH}/plain/file"
expect "not a git checkout: stops" 1 "isn't a git checkout" "$(GIT_CEILING_DIRECTORIES="${SCRATCH}" check "${SCRATCH}/plain")"

echo
echo "${PASS}/$((PASS + FAIL)) passed"
[[ ${FAIL} -eq 0 ]]
