#!/bin/bash

set -e

Help ()
{
	echo " Setup lab data help "
	echo
	echo "Syntax: $0 [option...]"
	echo "    -t, --testdir      Indicates where lab datas will be installed"
	echo "    -u, --url          Indicates the url to download the labs-data"
	echo "                         This url has to point a tar file"
	echo 
}


## Get inline parameters
while [ $# -gt 0 ]; do
	case $1 in
		(-u|--url)
			LAB_URL="$2"
			shift
			shift;;
		(-t|--testdir)
			TEST_DIR="$2"
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

##

# Tests if the script is running as root
if [ "${EUID}" -ne 0 ]
then
    echo "Please run this script as root"
    exit 1
fi

# Tests if LAB_URL and TEST_DIR have been set
if [ -z $LAB_URL ] || [ -z $TEST_DIR ]
then
	echo "LAB_URL or/and TEST_DIR variables need to be set\n"
	Help
	exit 1
fi


##Install other requirements

apt update
apt dist-upgrade

# Picked from the official Crosstool-NG Dockerfile
apt install -y gcc g++ gperf bison flex texinfo help2man make libncurses5-dev \
    python3-dev autoconf automake libtool libtool-bin gawk wget bzip2 xz-utils unzip \
    patch libstdc++6 rsync git meson ninja-build

cd $TEST_DIR

BASE_NAME="$(echo $LAB_URL | sed -e 's/^.*.\///g')"
wget $LAB_URL -O $BASE_NAME

# Extract the the tar file name and decompress it
tar xvf $BASE_NAME

# Export the lab data path into LAB_DIR in case of source
export LAB_DIR="$(echo $BASE_NAME | sed -e 's/\..*.$//g')"
