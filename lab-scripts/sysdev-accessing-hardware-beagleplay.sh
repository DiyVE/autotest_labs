#!/bin/bash

set -e

Help ()
{
	echo "Accessing Hardware BeaglePlay lab test help "
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

#####Accessing Hardware BeaglePlay Lab Tests #####


export PATH=$LAB_DIR/x-tools/aarch64-training-linux-musl/bin:$PATH
export ARCH=arm64 # The Linux kernel doesn't uses aarch64 to describe ARM 64 bits arch 
export CROSS_COMPILE=aarch64-linux-

cd $LAB_DIR/kernel/linux

## Customizing the kernel conf

# Support for GPIO control
./scripts/config -e CONFIG_EXPERT
./scripts/config -e CONFIG_GPIO_SYSFS
./scripts/config -e CONFIG_DEBUG_FS
./scripts/config -e CONFIG_DEBUG_FS_ALLOW_ALL

yes "" | make -j"$(nproc)"

# Support for leds
./scripts/config -e CONFIG_LEDS_CLASS
./scripts/config -e CONFIG_LEDS_GPIO
./scripts/config -e CONFIG_LEDS_TRIGGER_TIMER

yes "" | make -j"$(nproc)"

# Enable in tree kernel modules
./scripts/config -m CONFIG_SND_USB_AUDIO

yes "" | make -j"$(nproc)"

## Customizing the Device tree and declaring an I2C device
echo "/dts-v1/;
#include \"k3-am625-beagleplay.dts\"

&wkup_i2c0 {
    status = \"okay\";
};

&main_i2c3 {
    status = \"okay\";
    clock-frequency = <100000>;
    nunchuk: joystick@52 {
        compatible = \"nintendo,nunchuk\";
        reg = <0x52>;
    };
};" > $LAB_DIR/kernel/linux/arch/arm64/boot/dts/ti/k3-am625-beagleplay-custom.dts

sed -i '/k3-am625-beagleplay.dtb/a dtb-$(CONFIG_ARCH_K3) += k3-am625-beagleplay-custom.dtb' $LAB_DIR/kernel/linux/arch/arm64/boot/dts/ti/Makefile

# Committing kernel tree changes
git config --global user.email "tux@bootlin.com"
git config --global user.name "Tux Tux"

git checkout -b bootlin-labs
git add arch/arm64/boot/dts/ti/k3-am625-beagleplay-custom.dts
git commit -as -m "Custom DTS for Bootlin lab"

git format-patch stable/linux-6.4.y

# Compiling and installing an in-tree kernel module
make modules -j"$(nproc)"
make INSTALL_MOD_PATH=$LAB_DIR/tinysystem/nfsroot modules_install

# Compiling and installing an out-of-tree kernel module
cd $LAB_DIR/hardware/data/nunchuk/

make -C $LAB_DIR/kernel/linux M=$PWD

make -C $LAB_DIR/kernel/linux \
    M=$PWD \
    INSTALL_MOD_PATH=$LAB_DIR/tinysystem/nfsroot \
    modules_install

cd $LAB_DIR/kernel/linux

make dtbs
make Image.gz