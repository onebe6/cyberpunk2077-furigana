#!/bin/bash

# This script handles the import of subtitles and packaging into the final archive.
cd "$(dirname "$0")"

BUILD_DIR=$(pwd)

# Import necessary paths
. ./cp2077path.sh

SOURCE="../src/wolvenkit/Cyberpunk 2077 Furigana/files/Raw_Subtitles"
MODFILES="../src/wolvenkit/Cyberpunk 2077 Furigana/files/Mod"
TARGET="$MODFILES"
ARCHIVEFOLDER="../src/wolvenkit/Cyberpunk 2077 Furigana/packed/archive/pc/mod"

echo "Removing previous files..."
rm -rf "$TARGET"
mkdir -p "$TARGET"

echo "Copying files..."
cp -r "$SOURCE" "$TARGET"

echo "Encode unicode characters..."
python3 escapeunicode.py "$TARGET"

echo "Converting files..."
./WolvenKit.Console/WolvenKit.CLI.exe cr2w -d -p "$TARGET"

echo "Deleting copied source files..."
# Similar logic to remove .json while leaving .json.json
find "$TARGET" -name "*.json" ! -name "*.json.json" -type f -delete

echo "Packaging files..."
./WolvenKit.Console/WolvenKit.CLI.exe pack -p "$MODFILES" -o "$ARCHIVEFOLDER"

# Update archive name to the specific mod identifier
mv "$ARCHIVEFOLDER/Mod.archive" "$ARCHIVEFOLDER/cyberpunk2077-furigana.archive"
