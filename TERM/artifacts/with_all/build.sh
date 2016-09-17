#!/bin/bash

# The -I directive includes the parent directory of the artifact and
# ableC specification directories.

silver -I ../../.. -I ../../../../ableC -I ../../../../ableC/extensions/closure -o ableC.jar $@ \
   edu:umn:cs:melt:exts:ableC:algDataTypes:artifacts:with_all

