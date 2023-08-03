#!/bin/bash

set -e

Help ()
{
	echo "Toolchain lab test help "
	echo
	echo "Syntax: $0 [option...]"
	echo "    -d, --lab-dir       Indicates the path of the extracted lab-data"
	echo "                         directory"
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

#####  Toolchain Lab Tests  #####

cd $LAB_DIR/toolchain

# Clean the lab
rm -rf crosstool-ng

sudo apt install -y build-essential git autoconf bison flex texinfo help2man gawk \
	 libtool-bin libncurses5-dev unzip

git clone https://github.com/crosstool-ng/crosstool-ng
cd crosstool-ng/
git checkout 36ad0b1

./bootstrap
./configure --enable-local
make -j"$(nproc)"

# Choose the correct ready-made config for Crosstool-NG
case $LABBOARD in
	("beagleplay")
		./ct-ng aarch64-unknown-linux-uclibc;;
	("qemu")
		./ct-ng arm-cortexa9_neon-linux-gnueabihf;;
	("beaglebone")
		./ct-ng arm-cortex_a8-linux-gnueabi;;
	("stm32")
		./ct-ng arm-cortexa5-linux-uclibcgnueabihf;;
	(*)
		echo "This Board isn't supported yet :("
		exit 1;;
esac

## Tweak some Crosstool NG parameters

# Path and misc options
sed -i 's/# CT_EXPERIMENTAL is not set/CT_EXPERIMENTAL=y/g;
        s/CT_LOG_EXTRA=y/# CT_LOG_EXTRA is not set/g;
        s/# CT_LOG_DEBUG is not set/CT_LOG_DEBUG=y/g;
        s/CT_LOG_LEVEL_MAX="EXTRA"/CT_LOG_LEVEL_MAX="DEBUG"/g' .config;

sed -i '/^CT_PREFIX_DIR/s/\${HOME}/$LAB_DIR/g' .config # Used to keep the toolchain inside the output directory

# Refresh config params
yes "" | ./ct-ng oldconfig
	
# Target options
case $LABBOARD in
	("stm32")
		sed -i 's/CT_ARCH_CPU=.*/CT_ARCH_CPU="cortex-a7"/g;
			s/CT_ARCH_FPU=.*/CT_ARCH_FPU="vfpv4"/g' .config;;
	("beaglebone")
		sed -i 's/CT_ARCH_FPU=.*/CT_ARCH_FPU="vfpv3"/g;
				s/# CT_ARCH_FLOAT_HW is not set/CT_ARCH_FLOAT_HW=y/g;
				s/CT_ARCH_FLOAT_SW=y/# CT_ARCH_FLOAT_SW is not set/g;
				s/CT_ARCH_FLOAT=.*/CT_ARCH_FLOAT="hard"/g' .config;;
	("beagleplay")
		sed -i 's/CT_ARCH_CPU=.*/CT_ARCH_CPU="cortex-a53"/g' .config;;
esac

# Toolchain options
if [ $LABBOARD == "beagleplay" ]
then
	sed -i 's/CT_TARGET_VENDOR=.*/CT_TARGET_VENDOR="training"/g;
		s/CT_TARGET_ALIAS=.*/CT_TARGET_ALIAS="aarch64-linux"/g' .config
else
	sed -i 's/CT_TARGET_VENDOR=.*/CT_TARGET_VENDOR="training"/g;
                s/CT_TARGET_ALIAS=.*/CT_TARGET_ALIAS="arm-linux"/g' .config
fi

# Operating System options
sed -i '/^CT_LINUX_V_/s/=.*/ is not set/g;
        /^CT_LINUX_V_/s/^/# /g' .config 

if [ $LABBOARD == "beagleplay" ]
then
	sed -i 's/^# CT_LINUX_V_6_3 is not set/CT_LINUX_V_6_3=y/g;
		s/^CT_LINUX_VERSION=.*/CT_LINUX_VERSION="6.3.2"/g' .config
else
	sed -i 's/^# CT_LINUX_V_6_1 is not set/CT_LINUX_V_6_1=y/g;
                s/^CT_LINUX_VERSION=.*/CT_LINUX_VERSION="6.1.25"/g' .config
fi

# C library options
sed -i 's/# CT_LIBC_MUSL is not set/CT_LIBC_MUSL=y/g;
	s/CT_LIBC_UCLIBC_NG=y/# CT_LIBC_UCLIBC_NG is not set/g' .config

# C Compiler options
sed -i '/^CT_GCC_V_/s/=.*/ is not set/g;
		/^CT_GCC_V_/s/^/# /g' .config

sed -i 's/# CT_GCC_V_12 is not set/CT_GCC_V_12=y/g' .config 

# Debug facilities options
sed -i '/^CT_DEBUG_/s/=.*/ is not set/g;
        /^CT_DEBUG_/s/^/# /g' .config # Need to find a cleaner way

##Updating the .config file
yes "" | ./ct-ng oldconfig

## Building the toolchain
./ct-ng build

## Testing the toolchain

