#!/bin/bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# This assumes that we've previously downloaded the packages into STAGING_DIR
# (~/git/ohmydebn-packages-staging by default)
# wget -P ~/git/ohmydebn-packages-staging http://deb.debian.org/debian/pool/main/s/spice-vdagent/spice-vdagent_0.22.1-4.1_amd64.deb
# wget -P ~/git/ohmydebn-packages-staging http://deb.debian.org/debian/pool/main/s/spice-vdagent/spice-vdagent_0.22.1-4.1_arm64.deb

include_testing spice-vdagent \
  "${STAGING_DIR}/spice-vdagent_0.22.1-4.1_arm64.deb" \
  "${STAGING_DIR}/spice-vdagent_0.22.1-4.1_amd64.deb"

upload_testing
