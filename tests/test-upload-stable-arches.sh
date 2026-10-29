#!/bin/bash
#
# Tests for upload-to-repo-stable.sh's architecture check. It replaces each
# staged package in stable as a whole, so a build that stopped after its
# first architecture (leaving only amd64 in staging) would have taken arm64
# out of stable. Now it stops, before changing anything, when staging lacks
# an architecture stable has for a package. Each case is a scratch reprepro
# repo (unsigned) standing in for stable, with tiny stand-in debs, and
# SKIP_UPLOAD=1, so nothing real is touched or uploaded.
# Usage: tests/test-upload-stable-arches.sh

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "${SCRATCH}"' EXIT
PASS=0
FAIL=0

expect() {
  local name="$1" want="$2" got="$3"
  if [[ "${got}" == *"${want}"* ]]; then
    echo "  ok - ${name}"
    PASS=$((PASS + 1))
  else
    echo "  FAIL - ${name}"
    sed 's/^/      /' <<<"${got}"
    FAIL=$((FAIL + 1))
  fi
}

# deb <package> <version> <arch>: a minimal deb in ${SCRATCH}/debs.
deb() {
  local root="${SCRATCH}/root-$1-$3"
  mkdir -p "${root}/DEBIAN" "${SCRATCH}/debs"
  printf 'Package: %s\nVersion: %s\nArchitecture: %s\nSection: misc\nPriority: optional\nMaintainer: test <test@example.com>\nDescription: test\n' \
    "$1" "$2" "$3" >"${root}/DEBIAN/control"
  dpkg-deb --root-owner-group -b "${root}" "${SCRATCH}/debs/$1_$2_$3.deb" >/dev/null
  rm -rf "${root}"
  echo "${SCRATCH}/debs/$1_$2_$3.deb"
}

# A stable repo holding tool 1.0 (amd64, arm64) and data 1.0 (all), and an
# empty staging directory.
setup() {
  rm -rf "${SCRATCH}/stable" "${SCRATCH}/staging" "${SCRATCH}/debs"
  mkdir -p "${SCRATCH}/stable/conf" "${SCRATCH}/staging"
  printf 'Codename: trixie\nArchitectures: amd64 arm64 armhf\nComponents: main\n' \
    >"${SCRATCH}/stable/conf/distributions"
  for arch in amd64 arm64; do
    reprepro -b "${SCRATCH}/stable" includedeb trixie "$(deb tool 1.0 "${arch}")" >/dev/null 2>&1
  done
  reprepro -b "${SCRATCH}/stable" includedeb trixie "$(deb data 1.0 all)" >/dev/null 2>&1
}

stable() {
  reprepro -b "${SCRATCH}/stable" list trixie 2>/dev/null | sort | tr '\n' ' '
}

run() {
  STAGING_DIR="${SCRATCH}/staging" STABLE_REPO="${SCRATCH}/stable" SKIP_UPLOAD=1 \
    bash "${TESTS_DIR}/../upload-to-repo-stable.sh" </dev/null 2>&1
  echo "exit $?"
}

echo "=== upload-to-repo-stable.sh: architectures ==="

setup
BEFORE=$(stable)
cp "$(deb tool 2.0 amd64)" "${SCRATCH}/staging/"
cp "$(deb data 2.0 all)" "${SCRATCH}/staging/"
OUT=$(run)
expect "only amd64 staged: stops" "exit 1" "${OUT}"
expect "only amd64 staged: names what's missing" "tool (arm64)" "${OUT}"
expect "only amd64 staged: stable unchanged, other packages too" "${BEFORE}" "$(stable)"

setup
for arch in amd64 arm64; do cp "$(deb tool 2.0 "${arch}")" "${SCRATCH}/staging/"; done
cp "$(deb data 2.0 all)" "${SCRATCH}/staging/"
OUT=$(run)
expect "every architecture staged: promoted" "exit 0" "${OUT}"
expect "every architecture staged: stable has amd64" "trixie|main|amd64: tool 2.0" "$(stable)"
expect "every architecture staged: stable has arm64" "trixie|main|arm64: tool 2.0" "$(stable)"
expect "every architecture staged: the all package too" "trixie|main|amd64: data 2.0" "$(stable)"

setup
cp "$(deb newtool 1.0 amd64)" "${SCRATCH}/staging/"
OUT=$(run)
expect "a package new to stable, amd64 only: promoted" "exit 0" "${OUT}"
expect "a package new to stable: in stable" "trixie|main|amd64: newtool 1.0" "$(stable)"

echo
echo "${PASS}/$((PASS + FAIL)) passed"
[[ ${FAIL} -eq 0 ]]
