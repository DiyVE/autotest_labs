#!/bin/bash

set -e

Help ()
{
	echo "Thirdparty lab test help "
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

#####  Thirdparty Lab Tests  #####

export PATH=$LAB_DIR/x-tools/arm-training-linux-musleabihf/bin:$PATH

# Clean the lab
sudo rm -rf thirdparty

mkdir $LAB_DIR/thirdparty
cd $LAB_DIR/thirdparty

mkdir target staging

cp -a $LAB_DIR/tinysystem/nfsroot/* target/

## Alsa lib section
wget https://www.alsa-project.org/files/pub/lib/alsa-lib-1.2.9.tar.bz2
tar xvf alsa-lib-1.2.9.tar.bz2
cd alsa-lib-1.2.9

./configure --host=arm-linux --disable-topology --prefix=/usr
make -j"$(nproc)"

make DESTDIR=$LAB_DIR/thirdparty/staging/ install

cd ..
mkdir -p target/usr/lib
cp -a staging/usr/lib/libasound.so.2* target/usr/lib
arm-linux-strip target/usr/lib/libasound.so.2.0.0

mkdir -p target/usr/share
cp -a staging/usr/share/alsa target/usr/share

sed -i 's/defaults.pcm.ipc_gid audio/defaults.pcm.ipc_gid 0/g' target/usr/share/alsa/alsa.conf

## Alsa utils section
wget https://www.alsa-project.org/files/pub/utils/alsa-utils-1.2.9.tar.bz2
tar xvf alsa-utils-1.2.9.tar.bz2
cd alsa-utils-1.2.9

LDFLAGS=-L$LAB_DIR/thirdparty/staging/usr/lib \
CPPFLAGS=-I$LAB_DIR/thirdparty/staging/usr/\
include \
./configure --host=arm-linux --prefix=/usr \
--disable-alsamixer --disable-alsaconf
make -j"$(nproc)"

make DESTDIR=$LAB_DIR/thirdparty/staging/ install

cd ..
cp -a staging/usr/bin/speaker-test target/usr/bin/
arm-linux-strip target/usr/bin/speaker-test

## libgpiod section
git clone https://git.kernel.org/pub/scm/libs/libgpiod/libgpiod.git
cd libgpiod
git checkout v2.0.x

sudo apt install -y autoconf-archive pkg-config

./autogen.sh
./configure --host=arm-linux --prefix=/usr --enable-tools
make -j"$(nproc)"

make DESTDIR=$LAB_DIR/thirdparty/staging/ install

cd ..
cp -a staging/usr/lib/libgpiod.so.3* target/usr/lib/
arm-linux-strip target/usr/lib/libgpiod*
cp -a staging/usr/bin/gpio* target/usr/bin/
arm-linux-strip target/usr/bin/gpio*

## ipcalc section
sudo apt install -y meson

git clone https://gitlab.com/ipcalc/ipcalc.git
cd ipcalc/
git checkout 1.0.3

echo "[binaries]
c = 'arm-linux-gcc'

[host_machine]
system = 'linux'
cpu_family = 'arm'
cpu = 'cortex-a8'
endian = 'little'
" > ../cross-file.txt

mkdir cross-build
cd cross-build

meson --cross-file ../../cross-file.txt --prefix /usr ..
ninja

DESTDIR=$LAB_DIR/thirdparty/staging ninja install

cd ../..
cp staging/usr/bin/ipcalc target/usr/bin/
arm-linux-strip target/usr/bin/ipcalc

chmod +w target/lib/*.so.*
arm-linux-strip target/lib/*.so.*