#!/bin/bash

set -e

Help ()
{
	echo "BeagleBoneBlack U-Boot lab test help "
	echo
	echo "Syntax: $0 [option...]"
	echo "    -d, --lab-dir       Indicates the path of the extracted lab-data"
	echo "                         directory"
	echo "    -w, --wireless      Indicates that the selected board is the wireless one"
	echo
}


## Get inline parameters
while [ $# -gt 0 ]; do
	case $1 in
		(-d|--lab-dir)
			LAB_DIR="$2"
			shift
			shift;;
		(-w|--wireless)
			BBB_WIRELESS=true
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

# Test if the script is running as root

if [ "${EUID}" -eq 0 ]
then
    echo "You cannot run this script as root !"
    exit 1
fi

# Test if BBB_WIRELESS and LAB_DIR have been set

if [ -z $LAB_DIR ] || [ -z $BBB_WIRELESS ]
then
	echo "LAB_DIR and BBB_WIRELESS variables need to be set"
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

if [ "$BBB_WIRELESS" ]
then
	make -j"$(nproc)" DEVICE_TREE=am335x-boneblack-wireless
else
	make -j"$(nproc)" DEVICE_TREE=am335x-boneblack
fi