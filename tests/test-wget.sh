#!/bin/bash
#
# Tests for the wget wrapper in common.sh, which every build script's
# downloads go through. The scripts call wget -q, so a download that still
# failed after the wrapper's retries ended the build under set -e with no
# word of why, and a GitHub outage on the second of two downloads looked
# like a hang. A stand-in wget on PATH exits with MOCK_WGET_STATUS and logs
# its arguments; STAGING_DIR points into scratch space so sourcing
# common.sh touches nothing real.
# Usage: tests/test-wget.sh

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "${SCRATCH}"' EXIT
PASS=0
FAIL=0

mkdir -p "${SCRATCH}/bin"
cat >"${SCRATCH}/bin/wget" <<'EOF'
#!/bin/bash
echo "$*" >>"${MOCK_WGET_LOG}"
exit "${MOCK_WGET_STATUS:-0}"
EOF
chmod +x "${SCRATCH}/bin/wget"

# Runs the given wget arguments in a fresh set -e shell, as a build script
# does, and prints the error output, whether the script went on past the
# call, and the exit status.
check() {
  : >"${SCRATCH}/wget.log"
  PATH="${SCRATCH}/bin:${PATH}" MOCK_WGET_LOG="${SCRATCH}/wget.log" STAGING_DIR="${SCRATCH}/staging" \
    bash -c '
    set -euo pipefail
    source "$1/../common.sh"
    shift
    wget "$@"
    echo "carried on"
  ' _ "${TESTS_DIR}" "$@" 2>&1
  echo "exit $?"
}

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

reject() {
  local name="$1" unwanted="$2" got="$3"
  if [[ "${got}" != *"${unwanted}"* ]]; then
    echo "  ok - ${name}"
    PASS=$((PASS + 1))
  else
    echo "  FAIL - ${name}"
    sed 's/^/      /' <<<"${got}"
    FAIL=$((FAIL + 1))
  fi
}

URL="https://github.com/example/tool/releases/download/v1.0/tool-linux-arm64"

GOT=$(MOCK_WGET_STATUS=0 check -q "${URL}")
expect "success: the build carries on" "carried on" "${GOT}"
reject "success: says nothing" "Download failed" "${GOT}"
expect "success: still times out and retries" "--timeout=30 --tries=3 -q ${URL}" "$(cat "${SCRATCH}/wget.log")"

GOT=$(MOCK_WGET_STATUS=4 check -q "${URL}")
expect "failure: names the download and wget's status" "Download failed (wget exit 4): ${URL}" "${GOT}"
reject "failure: the build stops" "carried on" "${GOT}"
expect "failure: with wget's status" "exit 4" "${GOT}"

GOT=$(MOCK_WGET_STATUS=8 check -q -O - "${URL}")
expect "failure with -O -: names the URL, not the options" "Download failed (wget exit 8): ${URL}" "${GOT}"

GOT=$(MOCK_WGET_STATUS=8 check -q -O notices.txt "${URL}")
expect "failure with -O <file>: names the URL" "Download failed (wget exit 8): ${URL}" "${GOT}"

echo
echo "${PASS}/$((PASS + FAIL)) passed"
[[ ${FAIL} -eq 0 ]]
