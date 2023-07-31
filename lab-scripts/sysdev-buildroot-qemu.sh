#!/bin/bash

set -e

Help ()
{
	echo "Buildroot for QEMU lab test help "
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

#####  Buildroot for QEMU Lab Tests  #####

# Clone and checkout Buildroot
cd $LAB_DIR/buildroot

git clone https://git.buildroot.net/buildroot
cd buildroot
git checkout 2023.02.x

sed -i 's/BR2_i386=y/# BR2_i386 is not set/g;
		s/# BR2_arm is not set/BR2_arm=y/g' .config

yes "" | make oldconfig

sed -i 's/BR2_arm926t=y/# BR2_arm926t is not set/g' .config

sed -i 's/BR2_GCC_TARGET_CPU=.*/BR2_GCC_TARGET_CPU="cortex-a9"/g;
		s/# BR2_cortex_a9 is not set/BR2_cortex_a9=y/g' .config

yes "" | make oldconfig

sed -i 's/# BR2_ARM_ENABLE_NEON is not set/BR2_ARM_ENABLE_NEON=y/g;
		s/# BR2_ARM_ENABLE_VFP is not set/BR2_ARM_ENABLE_VFP=y/g;
		/BR2_SOFT_FLOAT=y\|BR2_ARM_SOFT_FLOAT=y/d;
		s/BR2_GCC_TARGET_FLOAT_ABI=.*/BR2_GCC_TARGET_FLOAT_ABI="hard"/g;
		s/BR2_ARM_EABI=y/# BR2_ARM_EABI is not set/g;
		s/# BR2_ARM_EABIHF is not set/BR2_ARM_EABIHF=y/g' .config

yes "" | make oldconfig

# Toolchain options
sed -i 's/BR2_TOOLCHAIN_BUILDROOT=y/# BR2_TOOLCHAIN_BUILDROOT is not set/g;
        s/# BR2_TOOLCHAIN_EXTERNAL is not set/BR2_TOOLCHAIN_EXTERNAL=y/g' .config
yes "" | make oldconfig
sed -i 's/BR2_TOOLCHAIN_EXTERNAL_ARM_ARM=y/# BR2_TOOLCHAIN_EXTERNAL_ARM_ARM is not set/g;
        s/# BR2_TOOLCHAIN_EXTERNAL_CUSTOM is not set/BR2_TOOLCHAIN_EXTERNAL_CUSTOM=y/g;
		s/BR2_TOOLCHAIN_EXTERNAL_DOWNLOAD=y/# BR2_TOOLCHAIN_EXTERNAL_DOWNLOAD is not set/g' .config
yes "" | make oldconfig
sed -i 's/BR2_TOOLCHAIN_EXTERNAL_CUSTOM_UCLIBC=y/# BR2_TOOLCHAIN_EXTERNAL_CUSTOM_UCLIBC is not set/g;
		s/# BR2_TOOLCHAIN_EXTERNAL_CUSTOM_MUSL is not set/BR2_TOOLCHAIN_EXTERNAL_CUSTOM_MUSL=y/g;
		s/# BR2_TOOLCHAIN_EXTERNAL_HAS_SSP is not set/BR2_TOOLCHAIN_EXTERNAL_HAS_SSP=y/g;
		s/# BR2_TOOLCHAIN_EXTERNAL_CXX is not set/BR2_TOOLCHAIN_EXTERNAL_CXX=y/g;
		s/# BR2_TOOLCHAIN_EXTERNAL_HEADERS_6_1 is not set/BR2_TOOLCHAIN_EXTERNAL_HEADERS_6_1=y/g;
		s/BR2_TOOLCHAIN_EXTERNAL_HEADERS_REALLY_OLD=y/# BR2_TOOLCHAIN_EXTERNAL_HEADERS_REALLY_OLD is not set/g' .config

sed -i "s/BR2_TOOLCHAIN_EXTERNAL_PATH=.*/BR2_TOOLCHAIN_EXTERNAL_PATH=\"\/home\/$USER\/x-tools\/arm-training-linux-musleabihf\"/" .config


yes "" | make oldconfig

# Target packages

# Enable packages
sed -i 's/# BR2_PACKAGE_ALSA_UTILS is not set/BR2_PACKAGE_ALSA_UTILS=y/g;
		s/# BR2_PACKAGE_MPD is not set/BR2_PACKAGE_MPD=y/g;
		s/# BR2_PACKAGE_MPD_MPC is not set/BR2_PACKAGE_MPD_MPC=y/g' .config

yes "" | make oldconfig

# Tweak Alsa utils pkg
sed -i '/^BR2_PACKAGE_ALSA_UTILS_/s/=.*/ is not set/g;
		/^BR2_PACKAGE_ALSA_UTILS_/s/^/# /g' .config

yes "" | make oldconfig

sed -i 's/# BR2_PACKAGE_ALSA_UTILS_ALSA_MIXER is not set/BR2_PACKAGE_ALSA_UTILS_ALSA_MIXER=y/g' .config

# Tweak MPD pkg
sed -i 's/BR2_PACKAGE_MPD_MAD=y/# BR2_PACKAGE_MPD_MAD is not set/g;
		s/BR2_PACKAGE_LIBID3TAG=y/# BR2_PACKAGE_LIBID3TAG is not set/g;
		s/BR2_PACKAGE_LIBMAD=y/# BR2_PACKAGE_LIBMAD is not set/g;
		s/# BR2_PACKAGE_MPD_VORBIS is not set/BR2_PACKAGE_MPD_VORBIS=y/g;
		s/BR2_PACKAGE_ZLIB=y/# BR2_PACKAGE_ZLIB is not set/g' .config

make -j"$(nproc)"

# Analyzing Dep
sudo apt install graphviz
make graph-depends
