#!/bin/bash

# turn on option to exit on non-zero return code.
set -e
# if * doesn't exist, replace glob with "", not "*"
shopt -s nullglob
# turn on verbose option, which echos commands to stdout
set -v

# turn off option to exit on non-zero return code
set +e

for xc_file in ./*.xc; do
	echo "testing $xc_file"
	./compile.sh "$xc_file"

	if [ "$?" == "0" ]; then
		#./$(basename $xc_file .xc)
                ./a.out
 	        if [ "$?" == "0" ]; then
			echo "$xc_file: negative test unexpectedly passed"
			exit 255
		fi
	fi
done

