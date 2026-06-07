#!/bin/bash

# This script handles the export of subtitles from WolvenKit and preparation for the build.
cd "$(dirname "$0")"

BUILD_DIR=$(pwd)

# Import necessary paths
. ./cp2077path.sh || { echo "Failed to load cp2077path.sh"; exit 1; }

SUBTITLEPATH="base/localization/jp-jp/subtitles"
SUBTITLEPATH_EP1="ep1/localization/jp-pp/subtitles"
WOLVENKITFILES="$BUILD_DIR/../src/wolvenkit/Cyberpunk\ 2077\ Furigana/files"
MODFILES="$WOLVENKITFILES/Mod_Exported"
RAWFILES="$WOLVENKITFILES/Raw"
SOURCE="$MODFILES"
TARGETRAW="$RAWFILES"
ARCHIVEFOLDER="$CP2077_FOLDER/archive/pc/content"
ARCHIVEFOLDER_EP1="$CP2077_FOLDER/archive/pc/ep1"

# Cleanup and prepare target directory
echo "Removing previous files..."
rm -rf "$SOURCE" 2>/dev/null || true
mkdir -p "$SOURCE" || { echo "Failed to create source dir"; exit 1; }
rm -rf "$TARGETRAW" 2>/dev/null || true
mkdir -p "$TARGETRAW" || { echo "Failed to create target raw dir"; exit 1; }

# Download and extract WolvenKit Linux binary if not exists or outdated (version 8.18.0)
WOLVENKIT_CLI_PATH="$BUILD_DIR/../src/wolvenkit/Cyberpunk\ 2077\ Furigana/files/WolvenKit.ConsoleLinux"
if [ ! -d "$WOLVENKIT_CLI_PATH" ]; then
    echo "Downloading WolvenKit Linux binary..."
    cd "$BUILD_DIR/../src/wolvenkit" || exit 1
    
    # Create directory if needed (handle spaces in path)
    mkdir -p "$(dirname "./Cyberpunk\ 2077\ Furigana/files/WolvenKit.ConsoleLinux")" || { echo "Failed to create WolvenKit dir"; exit 1; }
    
    rm -f "Cyberpunk\ 2077\ Furigana/files/src.zip.old" "Cyberpunk\ 2077\ Furigana/files/WolvenKit.ConsoleLinux*" 2>/dev/null || true
    
    curl -L --fail-with-body \
      https://github.com/WolvenKit/WolvenKit/releases/download/8.18.0/WolvenKit.ConsoleLinux-8.18.0.zip \
      -o "Cyberpunk\ 2077\ Furigana/files/src.zip.old" || { echo "Failed to download WolvenKit"; exit 1; } && {
        echo "Extracting WolvenKit Linux binary..."
        unzip -q "Cyberpunk\ 2077\ Furigana/files/src.zip.old" -d "$BUILD_DIR/../src/wolvenkit/Cyberpunk\ 2077\ Furigana/files/" || { 
            echo "Failed to extract WolvenKit"; exit 1;
        } && \
          rm -f "Cyberpunk\ 2077\ Furigana/files/src.zip.old"
    }
fi

WOLVENKIT_CLI="$BUILD_DIR/../src/wolvenkit/Cyberpunk\ 2077\ Furigana/files/WolvenKit.ConsoleLinux/WolvenKit.CLI"

echo "Exporting subtitles ($ARCHIVEFOLDER)..."
pushd "$ARCHIVEFOLDER" || exit 1
"$WOLVENKIT_CLI" unbundle -p lang_ja_text.archive -o "$MODFILES" -w "$SUBTITLEPATH/*" || true # continue even if error
popd

echo "Exporting subtitles ($ARCHIVEFOLDER_EP1)..."
pushd "$ARCHIVEFOLDER_EP1" || exit 1
"$WOLVENKIT_CLI" unbundle -p lang_ja_text.archive -o "$MODFILES" -w "$SUBTITLEPATH_EP1/*" || true # continue even if error
popd

echo "Copying files..."
cp -r "$SOURCE" "$TARGETRAW" 2>/dev/null || echo "(Source empty, skipping copy)"

echo "Decoding subtitles..."
"$WOLVENKIT_CLI" cr2w -p "$TARGETRAW" -s || true # continue even if error (no subtitles to decode)

echo "Deleting copies of source files (clearing temporary items)..."
# The original logic was a trick to delete only .json while leaving .json.json
# We can replicate this with find.
find "$TARGETRAW" -name "*.json" ! -name "*.json.json" -type f -delete 2>/dev/null || true

# Ensure we are using the virtual environment if available
if [ -d ".venv" ]; then
  source .venv/bin/activate
fi

echo "Decode unicode characters..."
python3 ../unescapeunicode.py "$TARGETRAW" || { echo "(Unicode decode failed, continuing)" }
