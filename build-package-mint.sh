#!/bin/bash

cd ohmydebn-packages-testing
reprepro -b . includedeb trixie ../mint-themes_2.1.6_all.deb
reprepro -b . includedeb trixie ../mint-x-icons_1.6.5_all.deb
reprepro -b . includedeb trixie ../mint-y-icons_1.7.2_all.deb
git add -A
git commit -m "update ${PACKAGE} package"
git push
cd - >/dev/null
