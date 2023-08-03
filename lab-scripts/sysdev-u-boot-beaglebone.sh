#!/bin/bash

set -e

Help ()
{
	echo "BeagleBoneBlack U-Boot lab test help "
	echo
	echo "Syntax: $0 [option...]"
	echo "    -d, --lab-dir       Indicates the path of the extracted lab-data"
	echo "                         directory"
	echo
}


## Get inline parameters
while [ $# -gt 0 ]; do
	case $1 in
		(-d|--lab-dir)
			LAB_DIR="$2"
			shift
			shift;;
		(-h|--help)
			Help
			exit 0;;
		(-*)
			echo "Unknown option $1"
			echo
			Help
			exit 1;;
  esac
done

## Testing requirements

# Tests if the script is running as root

if [ "${EUID}" -eq 0 ]
then
    echo "You cannot run this script as root !"
    exit 1
fi

# Tests if LABBOARD and LAB_DIR have been set

if [ -z $LAB_DIR ]
then
	echo "LAB_DIR variable needs to be set"
	echo
	Help
	exit 1
fi

##### BeagleBoneBlack U-Boot Lab Tests #####

export PATH=$LAB_DIR/x-tools/arm-training-linux-musleabihf/bin:$PATH

cd $LAB_DIR/bootloader

# Clean the lab
rm -rf u-boot

git clone https://gitlab.denx.de/u-boot/u-boot
cd u-boot
git checkout v2023.04

export CROSS_COMPILE=arm-linux-

make -j"$(nproc)" am335x_evm_defconfig

sudo apt install -y libssl-dev device-tree-compiler swig \
     python3-distutils python3-dev python3-setuptools

make -j"$(nproc)" DEVICE_TREE=am335x-boneblack-wireless # Add an option to select if wireless or not