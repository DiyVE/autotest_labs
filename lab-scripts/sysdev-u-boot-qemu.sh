#!/bin/bash

set -e

Help ()
{
	echo "Qemu U-Boot lab test help "
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

##### Qemu U-Boot Lab Tests #####

export PATH=$HOME/x-tools/arm-training-linux-musleabihf/bin:$PATH

cd $LAB_DIR/bootloader

# Clean the lab
sudo rm -rf u-boot

git clone https://gitlab.denx.de/u-boot/u-boot
cd u-boot
git checkout v2023.04

export CROSS_COMPILE=arm-linux-

make -j"$(nproc)" vexpress_ca9x4_defconfig

sed -i '/^CONFIG_ENV_IS_/s/=.*/ is not set/g;
        /^CONFIG_ENV_IS_/s/^/# /g' .config

sed -i 's/# CONFIG_ENV_IS_IN_FAT is not set/CONFIG_ENV_IS_IN_FAT=y/g;
	    /^CONFIG_SYS_REDUNDAND_ENVIRONMENT.*/a CONFIG_ENV_FAT_INTERFACE="mmc"\nCONFIG_ENV_FAT_FILE="\/uboot.env"/' .config

sed -i 's/# CONFIG_CMD_BOOTD is not set/CONFIG_CMD_BOOTD=y/g;
		s/# CONFIG_CMD_EDITENV is not set/CONFIG_CMD_EDITENV=y/g' .config

make oldconfig

sed -i 's/CONFIG_ENV_FAT_DEVICE_AND_PART=.*/CONFIG_ENV_FAT_DEVICE_AND_PART="0\:1"/g' .config

sudo apt install -y libssl-dev device-tree-compiler swig \
     python3-distutils python3-dev python3-setuptools

make -j"$(nproc)"
