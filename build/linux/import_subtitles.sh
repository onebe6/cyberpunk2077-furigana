#!/bin/bash

# This script handles the import of subtitles and packaging into the final archive.
set -e  # Exit on error, but we handle specific errors gracefully where needed

cd "$(dirname "$0")"

BUILD_DIR=$(pwd)

# Import necessary paths
. ./cp2077path.sh || { echo "Failed to load cp2077path.sh"; exit 1; }

SOURCE="../../src/wolvenkit/Cyberpunk\ 2077\ Furigana/files/Raw_Subtitles"
MODFILES="../../src/wolvenkit/Cyberpunk\ 2077\ Furigana/files/Mod"
TARGET="$MODFILES"
ARCHIVEFOLDER="../../src/wolvenkit/Cyberpunk\ 2077\ Furigana/packed/archive/pc/mod"

echo "Removing previous files..."
if [ -d "$TARGET" ]; then
    rm -rf "$TARGET" || { echo "Failed to remove target directory: $TARGET"; exit 1; }
fi
mkdir -p "$TARGET" || { echo "Failed to create target directory: $TARGET"; exit 1; }

echo "Copying files..."
if [ -d "$SOURCE" ]; then
    cp -r "$SOURCE" "$TARGET" || { echo "Failed to copy from source: $SOURCE -> $TARGET"; exit 1; }
else
    echo "(Source directory does not exist, skipping copy)"
fi

echo "Encode unicode characters..."
if [ -f "../escapeunicode.py" ]; then
    python3 ../escapeunicode.py "$TARGET" || { 
        echo "Warning: Unicode escape failed (may be expected if no files to process)"
    }
else
    echo "(escapeunicode.py not found, skipping encoding step)"
fi

# Use WolvenKit Linux binary from the same location as export_subtitles.sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && cd ..)"  # Go up to build/linux directory
WOLVENKIT_CLI="$SCRIPT_DIR/../src/wolvenkit/Cyberpunk\ 2077\ Furigana/files/WolvenKit.ConsoleLinux/WolvenKit.CLI"

if [ ! -f "$WOLVENKIT_CLI" ]; then
    echo "Error: WolvenKit CLI not found at: $WOLVENKIT_CLI"
    exit 1
fi

echo "Converting files..."
"$WOLVENKIT_CLI" cr2w -d -p "$TARGET" || { 
    echo "(cr2w conversion failed or no subtitles to encode, continuing)"
}

# Delete copied source files (similar logic to remove .json while leaving .json.json)
echo "Deleting temporary json files..."
find "$TARGET" -name "*.json" ! -name "*.json.json" -type f -delete 2>/dev/null || true

echo "Packaging files..."
if [ -d "$MODFILES" ]; then
    if ! "$WOLVENKIT_CLI" pack -p "$MODFILES" -o "$ARCHIVEFOLDER"; then
        echo "Error: Failed to package mod archive"
        exit 1
    fi
else
    echo "(Mod files directory does not exist, skipping packaging)"
fi

# Update archive name to the specific mod identifier
if [ -f "$ARCHIVEFOLDER/Mod.archive" ]; then
    mv "$ARCHIVEFOLDER/Mod.archive" "$ARCHIVEFOLDER/cyberpunk2077-furigana.archive" || { 
        echo "Warning: Failed to rename archive file"
    }
else
    echo "(No Mod.archive found, skipping rename)"
fi

echo "Build complete!"
