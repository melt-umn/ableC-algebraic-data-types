#!/bin/bash

# This script shows the steps in compiling an extended C program (.xc)
# down to C via an extended instance of ableC and then using GCC to
# compile the generated C code to an executable.
# Of course, if the use of 'cut' below fails for you, then just run
# the commands individually by hand.

top_level=".."
if [ -d ../../artifact ]; then
    top_level="../.."
elif [ -d ../../../artifact ]; then
    top_level="../../.."
fi

cmd="java -jar $top_level/artifact/ableC.jar $1"
echo $cmd
$cmd

#java -jar ../artifact/ableC.jar $1

# extract the base filename, everything before the dot (.)

filename=$1
extension="${filename##*.}"
filename_withoutpath=$(basename $filename)
basefilename="${filename_withoutpath%.*}"

cfile="${basefilename}.c"
#executable="${basefilename}"
executable="a.out"

gcc ${cfile} -o ${executable}
