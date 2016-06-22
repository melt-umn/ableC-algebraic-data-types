#!/bin/bash

# The -I directive includes the parent directory of the artifact and
# ableC specification directories.

silver -I ../../../../ableC \
       -I ../../.. \
       -I ../../../../ableC/extensions/string \
       -I ../../../../ableC/extensions/vector \
       -I ../../../../ableC/extensions/closure \
       -I ../../../../ableC/extensions/gc \
       -o ableC.jar $@ \
       edu:umn:cs:melt:exts:ableC:algDataTypes:artifacts:associative


rm -f build.xml
