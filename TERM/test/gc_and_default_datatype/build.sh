#!/bin/bash
# GENERATED FILE, DO NOT EDIT
touch artifact/Main.sv
silver -I . -I . -I ../../../../ableC -I ../../../../ableC/extensions/gc -I ../../../../ableC/extensions/closure -I ../../../../ableC/extensions/gc -I ../../../../ableC/extensions/string -I ../../../../extensions/edu.umn.cs.melt.exts.ableC.algDataTypes/.. -I ../../../../ableC/extensions/gc -I ../../../../ableC/extensions/gc -I ../../../../ableC/extensions/closure -I ../../../../ableC/extensions/gc -I ../../../../ableC/extensions/string -I ../../../../extensions/edu.umn.cs.melt.exts.ableC.algDataTypes/.. -o ableC.jar $@ artifact
