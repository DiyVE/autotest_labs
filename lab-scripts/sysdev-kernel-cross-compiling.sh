#!/bin/bash

set -e

Help ()
{
	echo "Kernel cross-compiling lab test help "
	echo
	echo "Syntax: $0 [option...]"
	echo "    -d, --lab-dir           Indicates the path of the extracted lab-data"
	echo "                             directory"
	echo
	echo "    -k, --kernel-version    Indicates the stable kernel version to fetch"
	echo
	echo "    -b, --board        Indicates the board used for the test:"
	echo "                       Possible values: (stm32, beaglebone,"
	echo "                         beagleplay, qemu)"
	echo
}


## Get inline parameters
while [ $# -gt 0 ]; do
	case $1 in
		(-b|--board)
			LABBOARD="$2"
			shift
			shift;;
		(-k|--kernel-version)
			LAB_KERNEL_VERSION="$2"
			shift
			shift;;
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

if [ -z $LAB_KERNEL_VERSION ] || [ -z $LAB_DIR ] || [ -z $LABBOARD ]
then
	echo "LAB_KERNEL_VERSION, LAB_DIR and LABBOARD variables need to be set"
	echo
	Help
	exit 1
fi


##### Kernel Cross-Compiling Lab Test #####

cd $LAB_DIR/kernel/linux

# Clean the lab
make distclean

git checkout stable/linux-$LAB_KERNEL_VERSION.y

if [ $LABBOARD == "beagleplay" ]
then
	export PATH=$HOME/x-tools/aarch64-training-linux-musl/bin:$PATH
	export ARCH=arm64 # The Linux kernel doesn't uses aarch64 to describe ARM 64 bits arch 
	export CROSS_COMPILE=aarch64-linux-
else
	export PATH=$HOME/x-tools/arm-training-linux-musleabihf/bin:$PATH
	export ARCH=arm
	export CROSS_COMPILE=arm-linux-
fi

# Load the defconfig file according to the board
case $LABBOARD in
	("beagleplay")
		make defconfig;;
	("qemu")
		make vexpress_defconfig;;
	("beaglebone")
		make omap2plus_defconfig;;
	("stm32")
		make multi_v7_defconfig;;
	(*)
		echo "This Board isn't supported yet :("
		exit 1;;
esac

## Tweak the configuration file using scripts/config
./scripts/config -d CONFIG_GCC_PLUGINS

case $LABBOARD in
	("beagleplay")
		sed -i '/# Platform selection/,/# end of Platform selection/s/=.*/ is not set/g;
				/# Platform selection/,/# end of Platform selection/{/^CONFIG/s/^/# /g}' .config
		
		./scripts/config --set-val CONFIG_ARCH_K3 y

		./scripts/config -d CONFIG_DRM;;
	("qemu")
		./scripts/config --set-val CONFIG_DEVTMPFS_MOUNT y;;
	("beaglebone")
		./scripts/config --set-val CONFIG_USB y
		./scripts/config --set-val CONFIG_USB_GADGET y
		./scripts/config --set-val CONFIG_USB_MUSB_HDRC y
		./scripts/config --set-val CONFIG_USB_MUSB_DSPS y
		./scripts/config --set-val CONFIG_USB_MUSB_DUAL_ROLE y
		./scripts/config --set-val CONFIG_NOP_USB_XCEIV y
		./scripts/config --set-val CONFIG_AM335X_PHY_USB y
		./scripts/config --set-val CONFIG_USB_ETH y

		./scripts/config -d CONFIG_DRM
		./scripts/config --set-val CONFIG_INPUT_EVDEV y;;
	("stm32")
		sed -i '/# end of Platform selection/,/# Processor Type/s/=.*/ is not set/g;
				/# end of Platform selection/,/# Processor Type/{/^CONFIG/s/^/# /g}' .config
		
		./scripts/config --set-val CONFIG_ARCH_STM32 y
		./scripts/config --set-val CONFIG_MACH_STM32MP157 y
		./scripts/config --set-val CONFIG_MACH_STM32MP13 y

		./scripts/config -d CONFIG_DRM;;
	(*)
		echo "This Board isn't supported yet :("
		exit 1;;
esac

yes "" | make oldconfig

make -j"$(nproc)"
