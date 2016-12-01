#!/bin/bash

# The -I directive includes the parent directory of the artifact and
# ableC specification directories.

silver -I ../../../../ableC \
       -I ../../.. \
       -I ../../../../ableC/extensions/closure \
       -I ../../../../ableC/extensions/gc \
       -I ../../../../ableC/extensions/string \
       -o ableC.jar $@ \
       edu:umn:cs:melt:exts:ableC:algDataTypes:artifacts:core
