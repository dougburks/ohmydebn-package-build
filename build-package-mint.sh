#!/bin/bash

cd ohmydebn-packages-testing
reprepro remove trixie mint-themes
reprepro -b . includedeb trixie ../mint-themes_2.1.6_all.deb
reprepro remove trixie mint-x-icons
reprepro -b . includedeb trixie ../mint-x-icons_1.6.5_all.deb
cd - >/dev/null
