#!/bin/bash

cd "$(dirname "$0")"

# Set build directory variable
BUILD_DIR=$(pwd)

# Call the path script
. ./cp2077path.sh

# Decompile Redscripts
redscript-cli.exe decompile -i "$CP2077_FOLDER/r6/cache/final.redscripts" -o dump.reds
