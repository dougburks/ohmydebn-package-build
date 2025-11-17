#!/bin/bash

cd ohmydebn-packages-testing
git add -A
git commit -m "update packages"
git push
cd - >/dev/null
