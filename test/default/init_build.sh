#!/bin/bash

source $ABLEC_PATH/extensions/closure/init_build.sh

export ADT_PATH=../../../../extensions/edu.umn.cs.melt.exts.ableC.algDataTypes

export ABLEC_SOURCE+=" $ADT_PATH/datatype/** $ADT_PATH/patternmatching/**"
export SILVER_INCLUDES+=" -I $ADT_PATH/.." # TODO: Not sure why this has to be the containing directory?
export CPPFLAGS+=" -I$ADT_PATH/include"
export TRANSLATE_DEPENDS+=" $ADT_PATH/include"
