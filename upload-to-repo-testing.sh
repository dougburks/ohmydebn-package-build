#!/bin/bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

cd "${TESTING_REPO}"

# Deploy to Cloudflare R2
# conf/ and db/ are reprepro's own working files (its configuration and
# package database), not part of the apt repo - they used to be published
# along with it.
rclone sync . "r2:ohmydebn-packages-testing" \
  --exclude "README.md" \
  --exclude "conf/**" \
  --exclude "db/**" \
  --s3-no-check-bucket \
  --s3-no-head \
  --no-update-modtime \
  --ignore-checksum
