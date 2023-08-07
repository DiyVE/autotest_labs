#!/bin/bash

Help ()
{
	echo "run-lab command help "
	echo
	echo "Syntax: $0 [OPTIONS] -t <training> -b <board> -o <output>"
	echo
	echo "    -t, --training         Indicates the training name"
    echo "    -b, --board            Indicates the target board"
    echo "    -l, --lab              Indicates the last lab of the training to test"
    echo "                              The remaining labs will not be executed  "
    echo "    -s, --skip-labs         Indicates the labs to skip"
    echo "    -o, --output           Indicates the output directory"
    echo "    -u, --url              Indicates where to get lab-data. Can be either an url or"
    echo "                              a path to a tar.gz file. This option is optional only"
    echo "                              if the output directory is not empty"
    echo "    -c, --clean            Remove every file in the output directory"
    echo "    -r, --re-build         Rebuild the Dockerimage"
    echo "    -h, --help             Shows this help"
    echo
	echo "  Exemple: $0 -t sysdev -l buildroot -b beagleplay -o output/"
	echo "     Will run all the sysdev lab scripts until it finished the buildroot lab"
}

SAVED_ARGS=($@)

## Get inline parameters
while [ $# -gt 0 ]; do
	case $1 in
        (-o|--output)
            LAB_DIR="$2"
            shift
            shift;;
        (-r|--re-build)
            RE_BUILD=true
            shift;;
        (-u|--url)
            export LAB_URL="$2"
            shift
            shift;;
        (*)
            shift;;
  esac
done


# Checking requirements
if command -v docker > /dev/null
then
    docker ps > /dev/null 2>&1
    if [ $? -eq 1 ]
    then
        echo "You don't have permission to connect to the docker daemon !"
        echo
        echo "To address this issue please create a docker group:"
        echo
        echo "      sudo groupadd docker"
        echo
        echo "And add your USER to it :"
        echo
        echo '      sudo usermod -aG docker ${USER}'
        exit 1
    fi
else
    echo "Docker is not installed on your machine"
    exit 1
fi

if [ -z "$LAB_DIR" ]
then
	echo "Missing required arguments !"
	echo
	Help
	exit 1
fi

# Build the docker image if requested or if not already built
if [ "$RE_BUILD" ] || [[ "$(docker images -q autotest_labs:latest 2> /dev/null)" == "" ]]
then
    docker build --build-arg UID="$UID" -t autotest_labs .
fi


# Updating LAB_DIR with an absolute path
LAB_DIR=$(realpath $LAB_DIR)

# In case $LAB_URL is in fact a file path
if [ -f "$LAB_URL" ]
then
    # Updating LAB_URL with an absolute path
    LAB_URL=$(realpath $LAB_URL)
    BASE_NAME="$(echo $LAB_URL | sed -e 's/^.*.\///g')"
    SAVED_ARGS+=("-u" "/home/work/$BASE_NAME")

    # Launching the Docker container with correct UID and mounted output directory AND $LAB_URL file
    docker run -it -v "$LAB_URL:/home/work/$BASE_NAME" -u "$UID" --mount type=bind,source="$LAB_DIR",target=/home/work/out autotest_labs "${SAVED_ARGS[@]}" --output /home/work/out
else
    # Launching the Docker container with correct UID and mounted output directory
    docker run -it -u "$UID" --mount type=bind,source="$LAB_DIR",target=/home/work/out autotest_labs "${SAVED_ARGS[@]}" --output /home/work/out
fi