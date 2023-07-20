#!/bin/bash

set -e

Help ()
{
	echo "Autotest Lab help "
	echo
	echo "Syntax: $0 <script-name>"
	echo
	echo "  Scripts full tests are located in the
		   full-sequence-scripts directory"
	echo
	echo "  Exemple: $0 embedded-linux-labs-test.sh"
	echo "     Will run the embedded-linux-lab-test.sh script"
}


if [ $# -eq 0 ]
then
	echo "No script name provided !"
	echo
	Help
	exit 1
fi

if [ -f "full-sequence-scripts/$1" ]
then
	echo "Autotest Script Started !"

	./full-sequence-scripts/$1

else
	echo "The '$1' test script doesn't exists !"
	echo
	Help
	exit 1
fi


