#!/bin/bash

# The -I directive includes the parent directory of the artifact and
# ableC specification directories.

silver -I ../../.. -I ../../../../ableC -o ableC.jar $@ \
   edu:umn:cs:melt:exts:ableC:algDataTypes:artifacts:core

