#!/bin/bash

cd ohmydebn-packages-testing

# Deploy to Cloudflare R2
rclone sync . "r2:ohmydebn-packages-testing" \
  --exclude ".git/**" \
  --exclude "README.md" \
  --s3-no-check-bucket \
  --s3-no-head \
  --no-update-modtime \
  --ignore-checksum

cd - >/dev/null
