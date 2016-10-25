#!/bin/bash

# set -x

export JAVA_OPTS="-Xss20M -Xmx400M ${JAVA_OPTS}"

filename=$1

if [ ! -e $filename ]; then
  echo "File \"$1\" does not exist."
  exit 1
fi

extension="${filename##*.}"

if [ $extension != "xc" ]; then
  echo "Input must be an extended C file with an \".xc\" extension"
  exit 2
fi

filename_withoutpath=$(basename $filename)
basefilename="${filename_withoutpath%.*}"


java ${JAVA_OPTS} -jar ableC.jar ${basefilename}.xc \
   --show-cpp \
   -I /project/melt/Software/ext-libs/usr/local/include/ \
   -I /project/melt3/People/evw/ableC_Home/able/extensions/closure/include \
   -I /project/melt3/People/evw/ableC_Home/extensions/edu.umn.cs.melt.exts.ableC.algDataTypes/include

if [ $? != 0 ]; then
    exit 3
fi


export C_INCLUDE_PATH=/project/melt/Software/ext-libs/usr/local/include
export LIBRARY_PATH=/project/melt/Software/ext-libs/usr/local/lib

gcc ${basefilename}.pp_out.c -std=c11 -lgc


