#!/bin/bash

set -e

Help ()
{
	echo "Tinysystem lab test help "
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


##### Tinysystem Lab Test #####

# Export the corresponding toolchain binaries
if [ $LABBOARD == "beagleplay" ]
then
	export PATH=$HOME/x-tools/aarch64-training-linux-musl/bin:$PATH
else
	export PATH=$HOME/x-tools/arm-training-linux-musleabihf/bin:$PATH
fi

cd $LAB_DIR/tinysystem

mkdir -p nfsroot/proc nfsroot/etc/init.d \
		 nfsroot/sys nfsroot/lib nfsroot/dev

# Clone the Busybox official repo
git clone https://git.busybox.net/busybox
cd busybox/
git checkout 1_36_stable

# Copy the given Busybox config file

cp ../data/busybox-1.36.config .config

make -j"$(nproc)"
make install

cd $LAB_DIR/tinysystem

# Writing a basic inittab file
case $LABBOARD in
    ("beagleplay")
        TTY_INT="ttyS2";;
    ("beaglebone")
        TTY_INT="ttyS0";;
    ("stm32mp1")
        TTY_INT="ttySTM0";;
    ("qemu")
        TTY_INT="ttyAMA0";;
    (*)
        echo "This Board isn't supported yet :("
		exit 1;;
esac

echo "::sysinit:/etc/init.d/rcS
$TTY_INT::askfirst:-/bin/sh
::restart:/sbin/init
::ctrlaltdel:/sbin/reboot
::shutdown:/bin/umount -a -r
::shutdown:/sbin/swapoff -a" > nfsroot/etc/inittab

# Writing a basic rcS init file
echo "#!/bin/sh

mount -t proc proc /proc
mount -t sysfs sys /sys
/usr/sbin/httpd -h /www/" > nfsroot/etc/init.d/rcS

chmod +x nfsroot/etc/init.d/rcS

# Switching to shared lib
if [ $LABBOARD == "beagleplay" ]
then
	aarch64-linux-gcc data/hello.c -o data/hello
    cp $HOME/x-tools/aarch64-training-linux-musl/aarch64-training-linux-musl/sysroot/lib/ld-musl-aarch64.so.1 nfsroot/lib
else
	arm-linux-gcc data/hello.c -o data/hello
    cp $HOME/x-tools/arm-training-linux-musleabihf/arm-training-linux-musleabihf/sysroot/lib/ld-musl-armhf.so.1 nfsroot/lib
fi

cp data/hello nfsroot/

# Need to make the Busybox shared lib switch !

cp -r data/www nfsroot




