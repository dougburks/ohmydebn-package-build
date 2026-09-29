#!/bin/bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ohmydebn previously depended on bibata-cursor-theme
# which conflicts with the newer mint-cursor-themes
# so we need to build a new mint-cursor-themes package
# that has the --conflicts and --replaces flags like this:
#
# fpm -s deb -t deb \
#  -n mint-cursor-themes \
#  -v 1.0.2-ohmydebn2 \
#  --conflicts bibata-cursor-theme \
#  --replaces bibata-cursor-theme \
#  --deb-compression xz \
#  --deb-compression-level 9 \
#  mint-cursor-themes_1.0.2_all.deb
#
# Also note that the --deb-compression flags are required to
# keep the package size from becoming much bigger.
#
# The resulting .deb files are expected to already be in STAGING_DIR.

include_testing mint-cursor-themes "${STAGING_DIR}/mint-cursor-themes_1.0.2-ohmydebn2_all.deb"
include_testing mint-themes "${STAGING_DIR}/mint-themes_2.3.8_all.deb"
include_testing mint-x-icons "${STAGING_DIR}/mint-x-icons_1.7.5_all.deb"
include_testing mint-y-icons "${STAGING_DIR}/mint-y-icons_1.9.1_all.deb"

upload_testing
