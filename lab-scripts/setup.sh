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

## Testing requirements

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

# Define a global user email and name for git config
git config --global user.email "tux@bootlin.com"
git config --global user.name "Tux Tux"

# If the output dir is empty and we have an url
if [ ! -z "$LAB_URL" ] && [ ! "$(ls -A $LAB_DIR)" ]
then
	BASE_NAME="$(echo $LAB_URL | sed -e 's/^.*.\///g')"
	if ! wget $LAB_URL -O /tmp/$BASE_NAME
	then
		echo
		echo "The LAB_URL not seems to correspond to an URL"
		echo "Trying to use the URL as a file path..."
		echo
		cp $LAB_URL /tmp/$BASE_NAME
	fi

	# Extract the the tar file name and decompress it
	tar xvf /tmp/$BASE_NAME -C $LAB_DIR --strip 1
fi