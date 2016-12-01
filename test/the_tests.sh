#!/bin/bash

# turn on option to exit on non-zero return code.
set -e
# turn on verbose option, which echos commands to stdout
set -v

# cd to top of extension directory.
cd ../

#
# Build: building the artifact
#
cd artifact
pwd
./build.sh --clean
cd ../

#
# MDA: run modular determinism analysis
#
cd modular_analyses/determinism
pwd
./run.sh
cd ../../

#
# MWDA: run modular well-definedness analysis
#
cd modular_analyses/well_definedness
pwd
./run.sh
cd ../../

# positive tests
cd test/positive
pwd
./the_tests.sh
cd ../../

# negative tests
cd test/negative
pwd
./the_tests.sh
cd ../../

pwd

set +v

