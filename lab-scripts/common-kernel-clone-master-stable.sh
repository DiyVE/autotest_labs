#!/bin/bash

set -e

# Clone the Torvalds Linux repo
git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux
cd linux

# Add the stable remote and fetch
git remote add stable https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux
git fetch stable
