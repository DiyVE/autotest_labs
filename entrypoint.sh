#!/bin/bash

set -e

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

## Get inline parameters
while [ $# -gt 0 ]; do
	case $1 in
		(-t|--training)
			export TRAINING_NAME="$2"
			shift
			shift;;
        (-b|--board)
            export LABBOARD="$2"
            shift
            shift;;
        (-l|--lab)
            export STOP_LAB="$2"
            shift
            shift;;
        (-s|--skip-labs)
            export SKIP_LABS="$2"
            shift
            shift;;
        (-o|--output)
            export LAB_DIR="$2"
            shift
            shift;;
        (-u|--url)
            export LAB_URL="$2"
            shift
            shift;;
        (-c|--clean)
            CLEAN_REQUESTED=true
            shift;;
        (-r|--re-build)
            shift;;
		(-h|--help)
			Help
			exit 0;;
		(*)
			echo "Unknown option $1"
			echo
			Help
			exit 1;;
  esac
done

## Testing requirements

# Test if the script is running as root
if [ "${EUID}" -eq 0 ]
then
    echo "You cannot run this script as root !"
    exit 1
fi

# Test if LABBOARD, TRAINING_NAME and LAB_DIR have been set
if [ -z "$TRAINING_NAME" ] || [ -z "$LABBOARD" ] || [ -z "$LAB_DIR" ]
then
	echo "Missing required arguments !"
	echo
	Help
	exit 1
fi

# Test if the OUTPUT directory is empty and lab url not defined
if [ "$(ls -A $LAB_DIR)" ] && [ -z "$LAB_URL" ]
then
    echo "$LAB_DIR is empty and you didn't specified any tar file"
    echo
    Help
    exit 1
fi

# Updating LABDIR with an absolute path
export LAB_DIR=$(realpath "$LAB_DIR")

# If clean has been requested
if [ "$CLEAN_REQUESTED" ]
then
    echo -e '\033[1;33m'
    echo "[WARN] Cleaning the Output directory"
    echo -e '\033[0m'
    rm -rf $LAB_DIR/.* 2>/dev/null || true
    rm -rf $LAB_DIR/*
fi

# Initial value for SKIP_LABS
if [ -z "$SKIP_LABS" ]
then
    export SKIP_LABS=()
fi

# Source the corresponding training
source $PWD/trainings/$TRAINING_NAME.env

cd lab-scripts

# Execute the mandatorty setup script
./setup.sh

AVAILABLE_SCRIPTS=(*)

# Iterate through lab test sequence
for CURRENT_LAB in "${TRAINING_SEQ[@]}"
do
    # Check if the CURRENT_LAB needs to be skipped
    if [[ ${SKIP_LABS[*]} =~ $CURRENT_LAB ]] || [ -f "$LAB_DIR/.$CURRENT_LAB-completed" ]
    then 
        echo -e '\033[1;33m'
        echo "[WARN] Skipping the $CURRENT_LAB lab"
        echo -e '\033[0m'

        # If we don't do this, we will skip the previously completed lab and
        # do not respect the STOP_LAB param
        if [ "$CURRENT_LAB" != "$STOP_LAB" ]
        then
            continue
        else
            break
        fi
    fi
    
    # Get the available scripts for the CURRENT_LAB
    selected_scripts=()
    for script in "${AVAILABLE_SCRIPTS[@]}"
    do
        if [[ "$script" == *"$CURRENT_LAB"* ]]
        then
            selected_scripts+=("$script")
        fi
    done

    # If a script name have a suffix that corresponds to the board
    # Then we execute it
    current_script="none"
    for script in "${selected_scripts[@]}"
    do
        if [[ "$script" == *-$LABBOARD.sh ]]
        then
            current_script="$script"
            break
        fi
    done

    echo -e '\033[34m'
    if [ "$current_script" == "none" ]
    then
        echo "[INFO] Testing $TRAINING_NAME-$CURRENT_LAB lab..."
        echo -e '\033[0m'
        ./"$TRAINING_NAME-$CURRENT_LAB.sh"
    else
        echo "[INFO] Testing $current_script lab..."
        echo -e '\033[0m'
        ./"$current_script"
    fi

    # Mark the lab completed
    touch "$LAB_DIR/.$CURRENT_LAB-completed"

    # Check if this CURRENT_LAB is the last requested
    if [ "$CURRENT_LAB" == "$STOP_LAB" ] 
    then 
        echo -e '\033[1;33m'
        echo "[WARN] Stopping as requested at $CURRENT_LAB lab"
        echo -e '\033[0m'
        break
    fi
done
