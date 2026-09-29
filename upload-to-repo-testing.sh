#!/bin/bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

cd "${TESTING_REPO}"

# Deploy to Cloudflare R2
rclone sync . "r2:ohmydebn-packages-testing" \
  --exclude "README.md" \
  --s3-no-check-bucket \
  --s3-no-head \
  --no-update-modtime \
  --ignore-checksum
