#!/bin/bash

set -e

Help ()
{
	echo "System Integration lab test help "
	echo
	echo "Syntax: $0 [option...]"
	echo "    -d, --lab-dir       Indicates the path of the extracted lab-data"
	echo "                         directory"
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

if [ -z $LABBOARD ] || [ -z $LAB_DIR ]
then
	echo "LABBOARD and LAB_DIR variables need to be set"
	echo
	Help
	exit 1
fi

#####  System Integration Lab Tests  #####
mkdir -p $LAB_DIR/integration
cd integration

git clone $LAB_DIR/buildroot/buildroot
cd buildroot
git checkout bootlin-labs

rm -r board/bootlin/training/rootfs-overlay/etc/init.d/

yes "" | make oldconfig

if [ $LABBOARD == "beagleplay" ]
then
    sed -i 's/# BR2_aarch64 is not set/BR2_aarch64=y/g;
            s/BR2_i386=y/# BR2_i386 is not set/g;
            /BR2_USE_MMU=y/a BR2_ARCH_IS_64=y' .config
    
    yes "" | make oldconfig
else
    sed -i 's/BR2_i386=y/# BR2_i386 is not set/g;
            s/# BR2_arm is not set/BR2_arm=y/g' .config

    yes "" | make oldconfig

    sed -i 's/BR2_arm926t=y/# BR2_arm926t is not set/g' .config
fi

case $LABBOARD in
	("beagleplay")
        sed -i 's/BR2_GCC_TARGET_CPU=.*/BR2_GCC_TARGET_CPU="cortex-A53"/g' .config;;
	("beaglebone")
		sed -i 's/BR2_GCC_TARGET_CPU=.*/BR2_GCC_TARGET_CPU="cortex-a8"/g;
                s/# BR2_cortex_a8 is not set/BR2_cortex_a8=y/g;
                s/BR2_ARM_EABI=y/# BR2_ARM_EABI is not set/g;
                s/# BR2_ARM_EABIHF is not set/BR2_ARM_EABIHF=y/g' .config;;
	("stm32mp1")
		sed -i 's/BR2_GCC_TARGET_CPU=.*/BR2_GCC_TARGET_CPU="cortex-a7"/g;
                s/# BR2_cortex_a7 is not set/BR2_cortex_a7=y/g' .config
        yes "" | make oldconfig
        sed -i 's/BR2_ARM_EABI=y/# BR2_ARM_EABI is not set/g;
                s/# BR2_ARM_EABIHF is not set/BR2_ARM_EABIHF=y/g;
                s/BR2_ARM_FPU_VFPV4D16=y/# BR2_ARM_FPU_VFPV4D16 is not set/g;
                s/# BR2_ARM_FPU_VFPV4 is not set/BR2_ARM_FPU_VFPV4=y/g' .config;;
	(*)
		echo "This Board isn't supported yet :("
		exit 1;;
esac

yes "" | make oldconfig

# Toolchain options
sed -i 's/BR2_TOOLCHAIN_BUILDROOT=y/# BR2_TOOLCHAIN_BUILDROOT is not set/g;
        s/# BR2_TOOLCHAIN_EXTERNAL is not set/BR2_TOOLCHAIN_EXTERNAL=y/g' .config
yes "" | make oldconfig
sed -i 's/BR2_TOOLCHAIN_EXTERNAL_ARM_ARM=y/# BR2_TOOLCHAIN_EXTERNAL_ARM_ARM is not set/g;
        s/# BR2_TOOLCHAIN_EXTERNAL_BOOTLIN is not set/BR2_TOOLCHAIN_EXTERNAL_BOOTLIN=y/g' .config

yes "" | make oldconfig

sed -i 's/# BR2_TOOLCHAIN_EXTERNAL_GDB_SERVER_COPY is not set/BR2_TOOLCHAIN_EXTERNAL_GDB_SERVER_COPY=y/g' .config

#System configuration options

sed -i 's/BR2_INIT_BUSYBOX=y/# BR2_INIT_BUSYBOX is not set/g;
        s/# BR2_INIT_SYSTEMD is not set/BR2_INIT_SYSTEMD=y/g;
        s/BR2_ROOTFS_OVERLAY=.*/BR2_ROOTFS_OVERLAY="board\/bootlin\/training\/rootfs-overlay"/g' .config
yes "" | make oldconfig
#Kernel options
sed -i 's/# BR2_LINUX_KERNEL is not set/BR2_LINUX_KERNEL=y/g' .config
yes "" | make oldconfig

if [ $LABBOARD == "beagleplay" ]
then
	sed -i 's/# BR2_LINUX_KERNEL_CUSTOM_VERSION is not set/BR2_LINUX_KERNEL_CUSTOM_VERSION=y/g;
			s/BR2_LINUX_KERNEL_LATEST_VERSION=y/# BR2_LINUX_KERNEL_LATEST_VERSION is not set/g;
			s/BR2_LINUX_KERNEL_VERSION=.*/BR2_LINUX_KERNEL_VERSION="6.4"\nBR2_LINUX_KERNEL_CUSTOM_VERSION_VALUE="6.4"/g;
			s/BR2_LINUX_KERNEL_IMAGE=y/# BR2_LINUX_KERNEL_IMAGE is not set/g;
			s/# BR2_LINUX_KERNEL_IMAGEGZ is not set/BR2_LINUX_KERNEL_IMAGEGZ=y/g' .config
else
	sed -i 's/BR2_LINUX_KERNEL_VERSION=.*/BR2_LINUX_KERNEL_VERSION="6.1.32"/g' .config
fi

sed -i 's/BR2_LINUX_KERNEL_PATCH=.*/BR2_LINUX_KERNEL_PATCH="board\/bootlin\/training\/0001-Custom-DTS-for-Bootlin-lab.patch"/g;
		s/BR2_LINUX_KERNEL_USE_DEFCONFIG=y/# BR2_LINUX_KERNEL_USE_DEFCONFIG is not set/g;
		s/# BR2_LINUX_KERNEL_USE_CUSTOM_CONFIG is not set/BR2_LINUX_KERNEL_USE_CUSTOM_CONFIG=y/g;
		s/# BR2_LINUX_KERNEL_DTS_SUPPORT is not set/BR2_LINUX_KERNEL_DTS_SUPPORT=y/g' .config

yes "" | make oldconfig

sed -i 's/BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE=.*/BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE="board\/bootlin\/training\/linux.config"/g' .config

case $LABBOARD in
	("beagleplay")
		sed -i 's/BR2_LINUX_KERNEL_INTREE_DTS_NAME=.*/BR2_LINUX_KERNEL_INTREE_DTS_NAME="ti\/k3-am625-beagleplay-custom"/g' .config;;
	("beaglebone")
		sed -i 's/BR2_LINUX_KERNEL_INTREE_DTS_NAME=.*/BR2_LINUX_KERNEL_INTREE_DTS_NAME="am335x-boneblack-custom"/g' .config;;
	("stm32mp1")
		sed -i 's/BR2_LINUX_KERNEL_INTREE_DTS_NAME=.*/BR2_LINUX_KERNEL_INTREE_DTS_NAME="stm32mp157a-dk1-custom"/g' .config;;
	(*)
		echo "This Board isn't supported yet :("
		exit 1;;
esac

yes "" | make oldconfig

# Target packages
# Enable packages
sed -i 's/# BR2_PACKAGE_MPD is not set/BR2_PACKAGE_MPD=y/g;
		s/# BR2_PACKAGE_MPD_MPC is not set/BR2_PACKAGE_MPD_MPC=y/g;
        s/# BR2_PACKAGE_NUNCHUK_DRIVER is not set/BR2_PACKAGE_NUNCHUK_DRIVER=y/g;
        s/# BR2_PACKAGE_DROPBEAR is not set/BR2_PACKAGE_DROPBEAR=y/g' .config

yes "" | make oldconfig

# Tweak MPD pkg
sed -i 's/BR2_PACKAGE_MPD_MAD=y/# BR2_PACKAGE_MPD_MAD is not set/g;
		s/BR2_PACKAGE_LIBID3TAG=y/# BR2_PACKAGE_LIBID3TAG is not set/g;
		s/BR2_PACKAGE_LIBMAD=y/# BR2_PACKAGE_LIBMAD is not set/g;
		s/# BR2_PACKAGE_MPD_VORBIS is not set/BR2_PACKAGE_MPD_VORBIS=y/g;
		s/BR2_PACKAGE_ZLIB=y/# BR2_PACKAGE_ZLIB is not set/g;
		s/BR2_PACKAGE_NCURSES=y/# BR2_PACKAGE_NCURSES is not set/g' .config

make -j"$(nproc)"