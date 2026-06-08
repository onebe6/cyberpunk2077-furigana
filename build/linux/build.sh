#!/bin/bash

set -eo pipefail

TARGET="target"

mkdir -p "${TARGET}/r6/cache"

# This script handles environment setup and building.
cd "$(dirname "$0")"

CONFIG="Release"
if [ -n "$1" ]; then
    CONFIG="$1"
fi

echo "Configuration: $CONFIG"

# Get the absolute path
. ./cp2077path.sh || { echo "Failed to load cp2077path.sh"; exit 1; }

# Run the compiler/process data
echo "Cyberpunk 2077 Path: ${CP2077_FOLDER}"

echo "Killing Cyberpunk2077.exe..."
killall -q Cyberpunk2077.exe 2>/dev/null || true

#echo "Copying files..."
#mkdir -p "$CP2077_FOLDER/r6/scripts/cyberpunk2077-furigana"
#if [ -d "../../src/redscript" ]; then
#    cp -rf ../../src/redscript/* "$CP2077_FOLDER/r6/scripts/cyberpunk2077-furigana/" 2>/dev/null || true
#fi

#mkdir -p "$CP2077_FOLDER/dist/red4ext/plugins"
#if [ -d "../../src/red4ext/x64/$CONFIG" ]; then
#    cp -rf ../../src/red4ext/x64/$CONFIG/*.dll "$CP2077_FOLDER/dist/red4ext/plugins/" 2>/dev/null || true
#else
#    echo "(red4ext directory not found, skipping)"
#fi

# Create nativeSettings mod if it doesn't exist yet (will be populated later)
#mkdir -p "$CP2077_FOLDER/bin/x64/plugins/cyber_engine_tweaks/mods/nativeSettings"
#if [ -d "../../src/CP77_nativeSettings/nativeSettings" ]; then
#    cp -rf ../../src/CP77_nativeSettings/nativeSettings/* "$CP2077_FOLDER/bin/x64/plugins/cyber_engine_tweaks/mods/nativeSettings/" 2>/dev/null || true
#else
#    echo "(nativeSettings source not found, creating empty directory)"
#fi

# Create packed folder for wolvenkit (will be populated during export)
#mkdir -p "$CP2077_FOLDER/dist/wolvenkit/Cyberpunk\ 2077\ Furigana/packed/" || true

#echo "Copy to CP2077FOLDER folder..."
#cp -rf "$CP2077_FOLDER/dist"/* "$CP2077_FOLDER/" 2>/dev/null || { echo "(Some files may not have been copied)"; }

echo "Running redscript compiler..."
# Note: The .exe might still need to be called as an executable if running in a bash environment (like WSL)
# but paths must use forward slashes.
if [ -f "../redscript-cli.exe" ]; then
    ../redscript-cli.exe compile -s "${CP2077_FOLDER}/r6/scripts" -b "${CP2077_FOLDER}/r6/cache/final.redscripts" -o "$TARGET/r6/cache/final.redscripts.modded" 2>/dev/null || { 
        echo "(redscript compilation failed or not available, continuing)"
    }
else
    echo "(redscript-cli.exe not found in ../ directory, skipping redscript compile step)"
fi

echo "Build complete!"
