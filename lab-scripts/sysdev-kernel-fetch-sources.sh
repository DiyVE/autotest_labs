#!/bin/bash

set -e

Help ()
{
	echo "Kernel fetch source lab test help "
	echo
	echo "Syntax: $0 [option...]"
	echo "    -d, --lab-dir           Indicates the path of the extracted lab-data"
	echo "                             directory"
	echo
	echo "    -k, --kernel-version    Indicates the stable kernel version to fetch"
	echo 
}


## Get inline parameters
while [ $# -gt 0 ]; do
	case $1 in
		(-k|--kernel-version)
			LAB_KERNEL_VERSION="$2"
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

## Testing requirements

# Tests if the script is running as root

if [ "${EUID}" -eq 0 ]
then
    echo "You cannot run this script as root !"
    exit 1
fi

# Tests if LABBOARD and LAB_DIR have been set

if [ -z $LAB_KERNEL_VERSION ] || [ -z $LAB_DIR ]
then
	echo "LAB_KERNEL_VERSION and LAB_DIR variables need to be set\n"
	Help
	exit 1
fi


##### Kernel Fetch Source Lab Test #####

mkdir -p $LAB_DIR/kernel

source common-kernel-clone-master-stable
