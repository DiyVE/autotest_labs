# Training info
export LABBOARD="stm32mp1"
export SESSION_NAME="embedded-linux"
export LAB_URL="https://bootlin.com/doc/training/embedded-linux/embedded-linux-labs.tar.xz"

export LAB_DIR=$PWD/out/$SESSION_NAME-labs

cd lab-scripts

# Test sequence
./setup.sh
./sysdev-toolchain.sh
./sysdev-u-boot-beagply.sh
