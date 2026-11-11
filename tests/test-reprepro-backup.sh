#!/bin/bash
#
# Tests for the reprepro backup in upload-to-repo-testing.sh (the stable
# upload runs the same two calls). Each upload copies the repo's conf/ and
# db/, which the public buckets leave out, to the private backup bucket,
# and the rclone config password is asked once for both rclone runs. A
# stand-in rclone on PATH logs its arguments and the password it was given,
# and answers `rclone config file` with a scratch config; the repo is a
# scratch directory, so nothing real is read or uploaded.
# Usage: tests/test-reprepro-backup.sh

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "${SCRATCH}"' EXIT
PASS=0
FAIL=0

mkdir -p "${SCRATCH}/bin" "${SCRATCH}/repo/conf" "${SCRATCH}/repo/db" "${SCRATCH}/repo/dists"
cat >"${SCRATCH}/bin/rclone" <<'EOF'
#!/bin/bash
if [ "$1 $2" = "config file" ]; then
  printf 'Configuration file is stored at:\n%s\n' "${MOCK_RCLONE_CONF}"
  exit 0
fi
echo "pass=${RCLONE_CONFIG_PASS:-} $*" >>"${MOCK_RCLONE_LOG}"
EOF
chmod +x "${SCRATCH}/bin/rclone"

# Runs the testing upload with the given config file contents, answering
# its password question with "secret", and prints the stand-in's log.
upload() {
  printf '%s\n' "$1" >"${SCRATCH}/rclone.conf"
  : >"${SCRATCH}/rclone.log"
  echo secret | PATH="${SCRATCH}/bin:${PATH}" MOCK_RCLONE_CONF="${SCRATCH}/rclone.conf" \
    MOCK_RCLONE_LOG="${SCRATCH}/rclone.log" STAGING_DIR="${SCRATCH}/staging" TESTING_REPO="${SCRATCH}/repo" \
    RCLONE_CONFIG_PASS="${2:-}" RCLONE_PASSWORD_COMMAND="${3:-}" bash "${TESTS_DIR}/../upload-to-repo-testing.sh" >/dev/null 2>&1
  echo "exit $?"
  cat "${SCRATCH}/rclone.log"
}

expect() {
  local name="$1" pattern="$2" got="$3"
  if grep -qE -- "${pattern}" <<<"${got}"; then
    echo "  ok - ${name}"
    PASS=$((PASS + 1))
  else
    echo "  FAIL - ${name}"
    sed 's/^/      /' <<<"${got}"
    FAIL=$((FAIL + 1))
  fi
}

GOT=$(upload "# Encrypted rclone configuration File")
expect "encrypted config: the upload succeeds" "^exit 0$" "${GOT}"
expect "encrypted config: the public sync gets the password" "^pass=secret sync \. r2:ohmydebn-packages-testing " "${GOT}"
expect "public sync: still leaves conf/ out" "sync .* --exclude conf/\*\* " "${GOT}"
expect "public sync: still leaves db/ out" "sync .* --exclude db/\*\* " "${GOT}"
expect "backup: gets the same password, without asking again" "^pass=secret copy " "${GOT}"
expect "backup: to the private bucket, in a dated folder" \
  "copy \. r2:ohmydebn-reprepro-backup/testing/[0-9]{8}T[0-9]{6}Z " "${GOT}"
expect "backup: conf/ and db/ only" "copy .* --include /conf/\*\* --include /db/\*\* " "${GOT}"
expect "backup: after the public sync" "^sync copy $" "$(grep -oE '^pass=[^ ]* (sync|copy)' <<<"${GOT}" | awk '{print $2}' | tr '\n' ' ')"

GOT=$(upload "[r2]")
expect "plain config: no password asked or passed" "^pass= sync " "${GOT}"

GOT=$(upload "# Encrypted rclone configuration File" "already-set")
expect "password already in the environment: used as it is" "^pass=already-set copy " "${GOT}"

GOT=$(upload "# Encrypted rclone configuration File" "" "pass show rclone")
expect "RCLONE_PASSWORD_COMMAND set: not asked (rclone runs the command)" "^pass= copy " "${GOT}"

echo
echo "${PASS}/$((PASS + FAIL)) passed"
[[ ${FAIL} -eq 0 ]]
