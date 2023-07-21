#!/bin/bash

set -e

Help ()
{
	echo " Setup lab data help "
	echo
	echo "Syntax: $0 [option...]"
	echo "    -d, --lab-dir      Indicates where the lab will be stored"
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

##

# Tests if the script is running as root
if [ "${EUID}" -eq 0 ]
then
    echo "You cannot run this script as root !"
    exit 1
fi

# Tests if LAB_URL and SESSION_NAME has been set
if [ -z $LAB_URL ] || [ -z $LAB_DIR ]
then
	echo "LAB_URL and/or LAB_DIR variables need to be set\n"
	Help
	exit 1
fi


##Install other requirements

sudo apt update -y
sudo apt dist-upgrade -y

# Picked from the official Crosstool-NG Dockerfile
sudo apt install -y gcc g++ gperf bison flex texinfo help2man make libncurses5-dev \
	python3-dev autoconf automake libtool libtool-bin gawk wget bzip2 xz-utils unzip \
	patch libstdc++6 rsync git meson ninja-build bc


BASE_NAME="$(echo $LAB_URL | sed -e 's/^.*.\///g')"
wget $LAB_URL -O /tmp/$BASE_NAME

mkdir -p $LAB_DIR

# Extract the the tar file name and decompress it
tar xvf /tmp/$BASE_NAME -C $LAB_DIR --strip 1
