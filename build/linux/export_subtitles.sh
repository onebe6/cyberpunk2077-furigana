#!/bin/bash

# This script handles the export of subtitles from WolvenKit and preparation for the build.
cd "$(dirname "$0")"

BUILD_DIR=$(pwd)

# Import necessary paths
. ./cp2077path.sh

SUBTITLEPATH="base/localization/jp-jp/subtitles"
SUBTITLEPATH_EP1="ep1/localization/jp-pp/subtitles"
WOLVENKITFILES="$BUILD_DIR/../src/wolvenkit/Cyberpunk 2077 Furigana/files"
MODFILES="$WOLVENKITFILES/Mod_Exported"
RAWFILES="$WOLVENKITFILES/Raw"
SOURCE="$MODFILES"
TARGETRAW="$RAWFILES"
ARCHIVEFOLDER="$CP2077_FOLDER/archive/pc/content"
ARCHIVEFOLDER_EP1="$CP2077_FOLDER/archive/pc/ep1"

# Cleanup and prepare target directory
echo "Removing previous files..."
rm -rf "$SOURCE"
mkdir -p "$SOURCE"
rm -rf "$TARGETRAW"
mkdir -p "$TARGETRAW"

echo "Exporting subtitles ($ARCHIVEFOLDER)..."
pushd "$ARCHIVEFOLDER"
./WolvenKit.Console/WolvenKit.CLI.exe unbundle -p lang_ja_text.archive -o "$MODFILES" -w "$SUBTITLEPATH/*"
popd

echo "Exporting subtitles ($ARCHIVEFOLDER_EP1)..."
pushd "$ARCHIVEFOLDER_EP1"
./WolvenKit.Console/WolvenKit.CLI.exe unbundle -p lang_ja_text.archive -o "$MODFILES" -w "$SUBTITLEPATH_EP1/*"
popd

echo "Copying files..."
cp -r "$SOURCE" "$TARGETRAW"

echo "Decoding subtitles..."
./WolvenKit.Console/WolvenKit.CLI.exe cr2w -p "$TARGETRAW" -s

echo "Deleting copies of source files (clearing temporary items)..."
# The original logic was a trick to delete only .json while leaving .json.json
# We can replicate this with find.
find "$TARGETRAW" -name "*.json" ! -name "*.json.json" -type f -delete

# Ensure we are using the virtual environment if available
if [ -d ".venv" ]; then
  source .venv/bin/activate
fi

echo "Decode unicode characters..."
python3 unescapeunicode.py "$TARGETRAW"
