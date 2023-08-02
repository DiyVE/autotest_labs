#!/bin/bash

set -e

Help ()
{
	echo " Setup lab data help "
	echo
	echo "Syntax: $0 [option...]"
	echo "    -o, --output-dir      Indicates where the lab will be stored"
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
		(-o|--lab-dir)
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

##

# Tests if the script is running as root
if [ "${EUID}" -eq 0 ]
then
    echo "You cannot run this script as root !"
    exit 1
fi

# Tests if LAB_URL and SESSION_NAME has been set
if [ -z $LAB_DIR ]
then
	echo "LAB_DIR variable needs to be set"
	echo
	Help
	exit 1
fi


##Install other requirements

sudo apt update -y
sudo apt dist-upgrade -y

# Picked from the official Crosstool-NG Dockerfile
sudo apt install -y gcc g++ gperf bison flex texinfo help2man make libncurses5-dev \
	python3-dev autoconf automake libtool libtool-bin gawk wget bzip2 xz-utils unzip \
	patch libstdc++6 rsync git meson ninja-build bc cpio kmod

# If the output dir is empty and we have an url
if [ ! -z "$LAB_URL" ] && [ "$(ls -A $LAB_DIR)" ]
then
	BASE_NAME="$(echo $LAB_URL | sed -e 's/^.*.\///g')"
	wget $LAB_URL -O /tmp/$BASE_NAME

	# Extract the the tar file name and decompress it
	tar xvf /tmp/$BASE_NAME -C $LAB_DIR --strip 1
fi