#!/bin/bash

# This assumes that we've previously downloaded the packages into the ~/git/ directory
# wget http://deb.debian.org/debian/pool/main/s/spice-vdagent/spice-vdagent_0.22.1-4.1_amd64.deb
# wget http://deb.debian.org/debian/pool/main/s/spice-vdagent/spice-vdagent_0.22.1-4.1_arm64.deb

cd ohmydebn-packages-testing
reprepro remove trixie spice-vdagent
reprepro -b . includedeb trixie ../spice-vdagent_0.22.1-4.1_arm64.deb
reprepro -b . includedeb trixie ../spice-vdagent_0.22.1-4.1_amd64.deb
cd - >/dev/null
