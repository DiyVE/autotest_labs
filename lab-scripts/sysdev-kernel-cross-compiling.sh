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
	echo "                       Possible values: (stm32mp1, beaglebone,"
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
		(-*|--*)
                        echo "Unknown option $i\n"
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
	echo "LAB_KERNEL_VERSION, LAB_DIR and LABBOARD variables need to be set\n"
	Help
	exit 1
fi


##### Kernel Cross-Compiling Lab Test #####

mkdir -p $LAB_DIR/kernel/linux

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
	("stm32mp1")
		make multi_v7_defconfig;;
	(*)
		echo "This Board isn't supported yet :("
		exit 1;;
esac

## Tweak the configuration file using scripts/config
./script/config --set-val CONFIG_GCC_PLUGIN n
./script/config --set-val CONFIG_INPUT_EVDEV y

case $LABBOARD in
	("beagleplay")
		./script/config --set-val CONFIG_DRM n
	("qemu")
		./script/config --set-val CONFIG_DEVTMPFS_MOUNT y
	("beaglebone")
		./script/config --set-val CONFIG_DRM n
		./script/config --set-val CONFIG_USB y
		./script/config --set-val CONFIG_USB_GADGET y
		./script/config --set-val CONFIG_USB_MUSB_HDRC y
		./script/config --set-val CONFIG_USB_MUSB_DSPS y
		./script/config --set-val CONFIG_USB_MUSB_DUAL_ROLE y
		./script/config --set-val CONFIG_NOP_USB_XCEIV y
		./script/config --set-val CONFIG_AM335X_PHY_USB y
		./script/config --set-val CONFIG_USB_ETH y;;
	("stm32mp1")
		./script/config --set-val 
		./script/config --set-val CONFIG_DRM n
	(*)
		echo "This Board isn't supported yet :("
		exit 1;;
esac

sed -i '' 
