# Autotest Labs

This repository contains various scripts able to test Bootlin Training labs.

In addition to that a Dockerfile is also provided in order to automate this
testing process with Github Workflow

## Usage and Installation

### Docker

You first need to build the docker image :
```
docker build -t autotest_labs .
```

You can then run it with the following command:
```
docker run autotest_labs <arg>
```

### From source code

Just call the top level script :
```
./top_level_script.sh <script-name>
```

The `script-name` argument defines the full-sequence-script to run.
All these scripts are stored in the `full-sequence-scripts` directory.

## Repo Structure

This repository is composed of two main directories.  

First, you have the `lab-scripts` directory, which contains the test
procedure for each specific lab. These script can be run autonomously and
parametered with inline arguments or by defining environnement variables.

Next you have the `full-sequence-scripts` directory, which contains
training wide test scripts.
These define some variables specific to the training(training name, board name, etc...)
but also describe the test sequence by calling scripts contained in `lab-scripts`
directory sequentially.
