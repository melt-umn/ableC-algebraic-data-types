#!/bin/bash

source ../default/init_build.sh
source ../../../../ableC/extensions/string/init_build.sh
source ../../../../ableC/extensions/vector/init_build.sh

export ABLEC_SOURCE+=" $ADT_PATH/associativepatterns/** $ADT_PATH/associativerewrite/**"
