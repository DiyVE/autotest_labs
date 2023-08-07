# Autotest Labs

This repository contains various scripts able to test Bootlin Training labs.

## Usage

The main script, `run-lab.sh`, is in fact just a docker wrapper
that runs, and eventually builds the test docker container.

His function is to automate this process and don't care about
docker at all.

`run-lab` script syntax :
```bash
./run-lab <param1> <value1> <param2> <value2> ...
```
For example if you want to run the sysdev training test on the stm32 board you
can type :
```bash
./run-lab -t sysdev -b stm32 -o output/ -u https://bootlin.com/doc/training/embedded-linux/embedded-linux-labs.pdf
```

If you don't want to run the test scripts in a docker container
you can directly run the `entrypoint.sh` script.

In the rest of this explanation we will suppose you run `run-lab.sh`
script.

### Mandatory parameters

The `run-lab.sh` requires a minimum of 3-4 parameters including:

- `-t,--training`: Defines the target training to test 
- `-b,--board`: Defines the target board to test
- `-o,--output`: Defines the output directory where all the operations will be
made, and data stored. Note that the docker container will only be able to
access this directory.

If the output directory is not empty, the scripts will try to test
the labs with its content. If you have done some previous tests on this specific
directory, the script will try to resume where you stopped.

In case the output directory is empty you need to specify either a path or an
url where to get lab-data.
**Note that the path or the URL needs to point to tar file**.
- `-u,--url`: Defines the PATH or an URL to a lab-data tar file in order to
populate the OUTPUT directory.

### Optional parameters

- `-l,--lab`: Defines the last lab to test in the training sequence.
For example if you specify the second to last lab in the training, the script
will execute all the tests until it completed it.
- `-s,--skip-labs`: Defines an additional lab name to skip. For now just one
lab can be specified
- `-c,--clean`: Requests the script to clean up the output directory, all files
or directories contained in the output will be erased.
- `-r,--re-build`: Requests the Docker wrapper to re-build the docker container
image. **This is mandatory if you modify lab scripts or training env file**.
Note that the image is automatically built if not already present.
## Tool Architecture

### Directories

This repository is composed of two main directories.  

First, you have the `lab-scripts` directory, which contains the test
procedure for each specific labs. These script can be run autonomously and
parameterized with in-line arguments or by defining environment variables.

Next you have the `training` directory, which contains
training definitions, and will be sourced by the `entrypoint` script.
These define some variables specific to the training (kernel version used, etc...)
but also describe the test sequence.

### Global Environment Variables

The main script defines some useful global environment variables like :

- `LABBOARD`: The name of the board used
- `LAB_DIR`: The path of the output directory
- `TRAINING_NAME`: The name of the training selected
## How to add trainings ?

### Training env file
The first thing to do when defining a new training is to create a file in
the `trainings` directory. This file must correspond to the training name
and end with a `.env` extension.

Each training `env` must, at least, define a bash array called
`TRAINING_SEQ`, composed of lab names you want to test. Another bash array
needs to be defined, `SUPPORTED_PLATFORMS`, and lists all the platforms
supported by the current training.
You can also **add** elements to the `SKIP_LABS` bash array according to
the `LABBOARD` variable. That might be useful when you don't want to execute
some labs for a specific board.

If you have to define others environment variables specific to your
training this is the place to do it.

### Lab scripts
Now, you may want to add some lab test scripts to compose your
test sequence.
To do so please create a file in the `lab-scripts` directory and name it
with the following triplet syntax :
```
<training-name>-<lab-name>-<board>.sh
```

The `training-name` and `lab-name` definitions are quite obvious, and correspond
to the name of the training and the lab since the `board` field is optional.
Indeed the `board` field is used when you want to create a specific script for
a specific board.
But when you want to have a unique script for all board you just don't define
this field.

For example, in the sysdev training you may noticed that 2 files are used to
describe the buildroot test script. One `sysdev-buildroot-qemu.sh` script is
used when the board used is `qemu`, and the `sysdev-buildroot` script for all
the remaining boards.

Some recommendations when writing a lab script :
- If your lab script need some variables to be defined, please
test if there are set before executing your real code.
- Please include a system to launch the script autonomously with
inline arguments, like in sysdev lab scripts.
- Please integrate a small Help function that describe the required
information to run the script correctly.