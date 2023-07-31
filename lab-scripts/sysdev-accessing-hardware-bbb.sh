#!/bin/bash

set -e

Help ()
{
	echo "Accessing Hardware Stm32 lab test help "
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

#####Accessing Hardware Stm32 Lab Tests #####

export PATH=$HOME/x-tools/arm-training-linux-musleabihf/bin:$PATH
export ARCH=arm
export CROSS_COMPILE=arm-linux-

cd $LAB_DIR/kernel/linux

## Customizing the kernel conf

# Support for GPIO control
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
#include \"am335x-boneblack.dts\"

&am33xx_pinmux {
	i2c1_pins: pinmux_i2c1_pins {
		pinctrl-single,pins = <
			AM33XX_PADCONF(AM335X_PIN_SPI0_CS0, PIN_INPUT_PULLUP, MUX_MODE2) /* spi0_cs0.i2c1_scl */
			AM33XX_PADCONF(AM335X_PIN_SPI0_D1, PIN_INPUT_PULLUP, MUX_MODE2) /* spi0_d1.i2c1_sda */
		>;
	};
};

&i2c1 {
    status = \"okay\";
    clock-frequency = <100000>;
    nunchuk: joystick@52 {
        compatible = \"nintendo,nunchuk\";
        reg = <0x52>;
    };
};" > $LAB_DIR/kernel/linux/arch/arm/boot/dts/am335x-boneblack-custom.dts

sed -i '/am335x-boneblack.dtb/a am335x-boneblack-custom.dtb \\' $LAB_DIR/kernel/linux/arch/arm/boot/dts/Makefile

# Committing kernel tree changes
git config  user.email "tux@bootlin.com"
git config  user.name "Tux Tux"

git checkout -b bootlin-labs
git add arch/arm/boot/dts/am335x-boneblack-custom.dts
git commit -as -m "Custom DTS for Bootlin lab"

git format-patch stable/linux-6.1.y

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
make zImage