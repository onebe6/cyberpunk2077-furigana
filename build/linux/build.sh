#!/bin/bash

# This script handles environment setup and building.
cd "$(dirname "$0")"

CONFIG="Release"
if [ -n "$1" ]; then
    CONFIG="$1"
fi

echo "Configuration: $CONFIG"

# Get the absolute path
./cp2077path.sh

# Run the compiler/process data
echo "Cyberpunk 2077 Path: $CP2077_FOLDER"

echo "Killing Cyberpunk2077.exe..."
# killall -q Cyberpunk2077.exe 2>/dev/null || true

echo "Copying files..."
mkdir -p ../../dist/r6/scripts/cyberpunk2077-furigana
cp -rf ../../src/redscript/* ../../dist/r6/scripts/cyberpunk2077-furigana/

mkdir -p ../../dist/red4ext/plugins
cp -rf ../../src/red4ext/x64/$CONFIG/*.dll ../../dist/red4ext/plugins/

#mkdir -p ../../dist/bin/x64/plugins/cyber_engine_tweaks/mods/cyberpunk2077-furigana
#cp -rf ../../src/cyber_engine_tweaks/* ../../dist/bin/x64/plugins/cyber_engine_tweaks/mods/cyberpunk2077-furigana/

mkdir -p ../../dist/bin/x64/plugins/cyber_engine_tweaks/mods/nativeSettings
cp -f ../../src/CP77_nativeSettings/nativeSettings/* ../../dist/bin/x64/plugins/cyber_engine_tweaks/mods/nativeSettings/

cp -rf ../../src/wolvenkit/"Cyberpunk 2077 Furigana"/packed/* ../../dist/

echo "Copy to CP2077FOLDER folder..."
cp -rf ../../dist/* "$CP2077_FOLDER"

echo "Running redscript compiler..."
# redscript-cli.exe compile -s "$CP2077_FOLDER/r6/scripts" -b "$CP2077_FOLDER/r6/cache/final.redscripts" -o "$CP2077_FOLDER/r6/cache/final.redscripts.modded"
# Note: The .exe might still need to be called as an executable if running in a bash environment (like WSL)
# but paths must use forward slashes.
../redscript-cli.exe compile -s "$CP2077_FOLDER/r6/scripts" -b "$CP2077_FOLDER/r6/cache/final.redscripts" -o "$CP2077_FOLDER/r6/cache/final.redscripts.modded"

# echo "Type \"$CP2077_FOLDER/r6/cache/redscript.log\""
