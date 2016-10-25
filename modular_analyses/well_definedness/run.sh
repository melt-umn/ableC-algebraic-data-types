#!/bin/bash

# turn on verbose option, which echos commands to stdout
# also exit on non-zero return code
set -v -e

silver -I ../../.. -I ../../../../ableC -o MDWA.jar --clean --warn-all $@ \
       edu:umn:cs:melt:exts:ableC:skeleton:modular_analyses:well_definedness

# This script runs Silver on the grammar that performs the modular
# well-definedness.  Note the use of the --warn-all flag.

# A fair amount of information is displayed to the screen, so look for
# errors after the "Checking for Errors." line.

