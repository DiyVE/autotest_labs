#!/bin/bash

set -e

Help ()
{
	echo "Beagleplay U-Boot lab test help "
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
		(-*|--*)
                        echo "Unknown option $i"
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

##### Beagleplay U-Boot Lab Tests #####

export PATH=$HOME/x-tools/aarch64-training-linux-musl/bin:$PATH

cd $LAB_DIR/bootloader

##Get and install the 32 bits toolchain

wget -O /tmp/arm-gnu-toolchain-12.2.rel1-x86_64-arm-none-eabi.tar.xz https://\
developer.arm.com/-/media/Files/downloads/gnu/12.2.rel1/binrel/\
arm-gnu-toolchain-12.2.rel1-x86_64-arm-none-eabi.tar.xz

tar vxJf /tmp/arm-gnu-toolchain-12.2.rel1-x86_64-arm-none-eabi.tar.xz -C $HOME/\
x-tools

export PATH=$HOME/x-tools/arm-gnu-toolchain-12.2.rel1-x86_64-arm-none-eabi/bin/:$PATH

git clone https://git.beagleboard.org/beagleplay/u-boot.git
cd u-boot/
git checkout f036fbdc25941d7585182d2552c767edb9b04114

mkdir -p ../build_uboot/r5

export CROSS_COMPILE=arm-none-eabi-
export ARCH=arm

make am62x_evm_r5_defconfig O=../build_uboot/r5/

## Tweak U-Boot configuration file

# Autoboot options

sed -i 's/# CONFIG_USE_BOOTCOMMAND is not set/CONFIG_USE_BOOTCOMMAND=y\nCONFIG_BOOTCOMMAND="echo '\''No bootcmd yet'\''"/g' ../build_uboot/r5/.config

# SPL options

sed -i 's/# CONFIG_SPL_FS_EXT4 is not set/CONFIG_SPL_FS_EXT4=y/g;
	s/CONFIG_SPL_ENV_IS_IN_MMC=y/CONFIG_SPL_ENV_IS_IN_EXT4=y/g' ../build_uboot/r5/.config
# Environement options

sed -i '/^CONFIG_ENV_IS_IN_/s/=.*/ is not set/g;
        /^CONFIG_ENV_IS_IN_/s/^/# /g' ../build_uboot/r5/.config

sed -i 's/# CONFIG_ENV_IS_IN_EXT4 is not set/CONFIG_ENV_IS_IN_EXT4=y/g;
	s/# CONFIG_SYS_REDUNDAND_ENVIRONMENT is not set/CONFIG_ENV_EXT4_INTERFACE="mmc"\nCONFIG_ENV_EXT4_DEVICE_AND_PART="1\:2"\nCONFIG_ENV_EXT4_FILE="\/uboot.env"/g' ../build_uboot/r5/.config

# Filesystem options

sed -i 's/# CONFIG_FS_EXT4 is not set/CONFIG_FS_EXT4=y\nCONFIG_EXT4_WRITE=y/g' ../build_uboot/r5/.config

yes "" | make oldconfig O=../build_uboot/r5/

sudo apt install -y libssl-dev device-tree-compiler swig \
	python3-distutils python3-dev

make DEVICE_TREE=k3-am625-r5-beagleplay O=../build_uboot/r5/

## Get the TI firmware and create tiboot3.bin image

cd $LAB_DIR/bootloader
git clone git://git.ti.com/processor-firmware/ti-linux-firmware.git
cd ti-linux-firmware
git checkout c126d3864b9faf725ff40e620049ab5d56dedc5b

cd ..
git clone git://git.ti.com/k3-image-gen/k3-image-gen.git
cd k3-image-gen/
git checkout 150f1956b4bdcba36e7dffc78a4342df602f8d6e

make SOC=am62x SBL=../build_uboot/r5/spl/u-boot-spl.bin SYSFW_PATH=../\
ti-linux-firmware/ti-sysfw/ti-fs-firmware-am62x-gp.bin

## Get and compile the TF-A

export ARCH=aarch64
export CROSS_COMPILE=aarch64-linux-

cd ..
git clone https://github.com/ARM-software/arm-trusted-firmware.git
cd arm-trusted-firmware/
git checkout v2.9

make PLAT=k3 TARGET_BOARD=lite

## Configure U-boot for A53 Processor

cd $LAB_DIR/bootloader
mkdir build_uboot/a53/

make am62x_evm_a53_defconfig O=../build_uboot/a53/

## Tweak U-Boot configuration file

# Autoboot options

sed -i 's/# CONFIG_USE_BOOTCOMMAND is not set/CONFIG_USE_BOOTCOMMAND=y\nCONFIG_BOOTCOMMAND="echo '\''No bootcmd yet'\''"/g' ../build_uboot/a53/.config

# SPL options

sed -i 's/# CONFIG_SPL_FS_EXT4 is not set/CONFIG_SPL_FS_EXT4=y/g;
        s/CONFIG_SPL_ENV_IS_IN_MMC=y/CONFIG_SPL_ENV_IS_IN_EXT4=y/g' ../build_uboot/a53/.config
# Environement options

sed -i '/^CONFIG_ENV_IS_IN_/s/=.*/ is not set/g;
        /^CONFIG_ENV_IS_IN_/s/^/# /g' ../build_uboot/a53/.config

sed -i 's/# CONFIG_ENV_IS_IN_EXT4 is not set/CONFIG_ENV_IS_IN_EXT4=y/g;
        s/# CONFIG_SYS_REDUNDAND_ENVIRONMENT is not set/CONFIG_ENV_EXT4_INTERFACE="mmc"\nCONFIG_ENV_EXT4_DEVICE_AND_PART="1\:2"\nCONFIG_ENV_EXT4_FILE="\/uboot.env"/g' ../build_uboot/a53/.config

# Filesystem options

sed -i 's/# CONFIG_FS_EXT4 is not set/CONFIG_FS_EXT4=y\nCONFIG_EXT4_WRITE=y/g' ../build_uboot/a53/.config

yes "" | make oldconfig O=../build_uboot/a53/

make ATF=$HOME/embedded-linux-beagleplay-labs/bootloader/\
arm-trusted-firmware/build/k3/lite/release/bl31.bin DM=$HOME/\
embedded-linux-beagleplay-labs/bootloader/ti-linux-firmware/ti-dm/am62xx\
/ipc_echo_testb_mcu1_0_release_strip.xer5f O=../build_uboot/a53


