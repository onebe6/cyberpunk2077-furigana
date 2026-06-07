#!/bin/bash

# This script handles the import of subtitles and packaging into the final archive.
cd "$(dirname "$0")"

BUILD_DIR=$(pwd)

# Import necessary paths
. ./cp2077path.sh

SOURCE="../../src/wolvenkit/Cyberpunk 2077 Furigana/files/Raw_Subtitles"
MODFILES="../../src/wolvenkit/Cyberpunk 2077 Furigana/files/Mod"
TARGET="$MODFILES"
ARCHIVEFOLDER="../../src/wolvenkit/Cyberpunk 2077 Furigana/packed/archive/pc/mod"

echo "Removing previous files..."
rm -rf "$TARGET"
mkdir -p "$TARGET"

echo "Copying files..."
cp -r "$SOURCE" "$TARGET"

echo "Encode unicode characters..."
python3 ../escapeunicode.py "$TARGET"

# Use WolvenKit Linux binary from the same location as export_subtitles.sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && cd ..)"  # Go up to build/linux directory
WOLVENKIT_CLI="$SCRIPT_DIR/../src/wolvenkit/Cyberpunk\ 2077\ Furigana/files/WolvenKit.ConsoleLinux/WolvenKit.CLI"

echo "Converting files..."
"$WOLVENKIT_CLI" cr2w -d -p "$TARGET" || true # continue even if error (no subtitles to encode)

echo "Deleting copied source files..."
# Similar logic to remove .json while leaving .json.json
find "$TARGET" -name "*.json" ! -name "*.json.json" -type f -delete 2>/dev/null || true

echo "Packaging files..."
"$WOLVENKIT_CLI" pack -p "$MODFILES" -o "$ARCHIVEFOLDER" || exit 1 # required operation

# Update archive name to the specific mod identifier
mv "$ARCHIVEFOLDER/Mod.archive" "$ARCHIVEFOLDER/cyberpunk2077-furigana.archive"
