#!/bin/bash

set -e

Help ()
{
	echo "Stm32 U-Boot lab test help "
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

##### Stm32 U-Boot Lab Tests #####

export PATH=$LAB_DIR/x-tools/arm-training-linux-musleabihf/bin:$PATH

cd $LAB_DIR/bootloader

# Clean the lab
sudo rm -rf u-boot trusted-firmware-a

git clone https://gitlab.denx.de/u-boot/u-boot
cd u-boot
git checkout v2023.04

export CROSS_COMPILE=arm-linux-

make -j"$(nproc)" stm32mp15_defconfig

sed -i '/^CONFIG_ENV_IS_/s/=.*/ is not set/g;
        /^CONFIG_ENV_IS_/s/^/# /g' .config

sed -i 's/# CONFIG_ENV_IS_IN_EXT4 is not set/CONFIG_ENV_IS_IN_EXT4=y/g;
        s/# CONFIG_ENV_IS_IN_UBI is not set/CONFIG_ENV_IS_IN_UBI=y/g;
	    /^CONFIG_SYS_REDUNDAND_ENVIRONMENT.*/a CONFIG_ENV_EXT4_INTERFACE="mmc"\nCONFIG_ENV_EXT4_DEVICE_AND_PART="0\:4"\nCONFIG_ENV_EXT4_FILE="\/uboot.env"/' .config

sed -i 's/CONFIG_WDT_STM32MP=y/# CONFIG_WDT_STM32MP is not set/g' .config

yes "" | make oldconfig

sudo apt install -y libssl-dev device-tree-compiler swig \
     python3-distutils python3-dev python3-setuptools

make -j"$(nproc)" DEVICE_TREE=stm32mp157a-dk1

cd ..
git clone https://git.trustedfirmware.org/TF-A/trusted-firmware-a.git
cd trusted-firmware-a/
git checkout v2.9

make ARM_ARCH_MAJOR=7 ARCH=aarch32 PLAT=stm32mp1 AARCH32_SP=sp_min \
DTB_FILE_NAME=stm32mp157a-dk1.dtb BL33=../u-boot/u-boot-nodtb.bin \
BL33_CFG=../u-boot/u-boot.dtb STM32MP_SDMMC=1 fip all -j"$(nproc)"