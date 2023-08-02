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

# Updating LABDIR with an absolute path and with permissions
export LAB_DIR=$(realpath out/)
sudo chmod -R a+rwX out/ # Not very clean, to improve 

# Initial value for SKIP_LABS
if [ -z "$SKIP_LABS" ]
then
    export SKIP_LABS=()
fi

# Source the corresponding training
source $PWD/trainings/$TRAINING_NAME.env

cd lab-scripts

AVAILABLE_SCRIPTS=(*)

# Iterate through lab test sequence
for CURRENT_LAB in "${TRAINING_SEQ[@]}"
do
    # Check if the CURRENT_LAB need to be skipped
    if [[ ${SKIP_LABS[*]} =~ $CURRENT_LAB ]] || [ -f "$LAB_DIR/.$CURRENT_LAB-completed" ]
    then 
        echo "[WARN] Skipping the $CURRENT_LAB lab"

        # If we don't do this, we will skip the previously completed lab and
        # not respect the STOP_LAB param
        if [ "$CURRENT_LAB" != "$STOP_LAB" ]
        then
            continue
        else
            break
        fi
    fi
    
    # Get the scripts available for the CURRENT_LAB
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

    if [ "$current_script" == "none" ]
    then 
        ./"$TRAINING_NAME-$CURRENT_LAB.sh"
    else
        ./"$current_script"
    fi

    touch "$LAB_DIR/.$CURRENT_LAB-completed"

    # Check if this CURRENT_LAB is the last requested
    if [ "$CURRENT_LAB" == "$STOP_LAB" ] 
    then 
        echo "[WARN] Stopping as requested at $CURRENT_LAB lab"
        break
    fi
done
