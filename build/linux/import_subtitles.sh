#!/bin/bash

# This script handles the import of subtitles and packaging into the final archive.
set -e  # Exit on error, but we handle specific errors gracefully where needed

cd "$(dirname "$0")"

BUILD_DIR=$(pwd)

# Import necessary paths
. ./cp2077path.sh || { echo "Failed to load cp2077path.sh"; exit 1; }

SOURCE="$CP2077_FOLDER/archive/pc/content/Raw_Subtitles"
MODFILES="$CP2077_FOLDER/archive/pc/content/Mod"
TARGET="$MODFILES"
ARCHIVEFOLDER="$CP2077_FOLDER/packed/archive/pc/mod"

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
WOLVENKIT_CLI="$BUILD_DIR/../src/wolvenkit/Cyberpunk\ 2077\ Furigana/files/WolvenKit.ConsoleLinux/WolvenKit.CLI"

echo "Checking for WolvenKit CLI at: $WOLVENKIT_CLI"

# Normalize path to remove any .. components and resolve spaces properly
if [ -f "$WOLVENKIT_CLI" ]; then
    WOLVENKIT_CLI=$(realpath -- "$WOLVENKIT_CLI") || { 
        echo "Error: Failed to normalize WolvenKit CLI path"; exit 1;
    }
else
    # Try alternative paths if the original doesn't exist
    ALTERNATIVE_WK="$BUILD_DIR/src/wolvenkit/Cyberpunk\ 2077\ Furigana/files/WolvenKit.ConsoleLinux/WolvenKit.CLI"
    
    echo "Trying alternative path: $ALTERNATIVE_WK"
    if [ -f "$ALTERNATIVE_WK" ]; then
        WOLVENKIT_CLI=$(realpath -- "$ALTERNATIVE_WK") || { 
            echo "Error: Failed to normalize alternative WolvenKit CLI path"; exit 1;
        }
    else
        # Try one more location (direct from build/linux)
        DIRECT_WK="$BUILD_DIR/WolvenKit.ConsoleLinux/WolvenKit.CLI"
        
        if [ -f "$DIRECT_WK" ]; then
            WOLVENKIT_CLI=$(realpath -- "$DIRECT_WK") || { 
                echo "Error: Failed to normalize direct WolvenKit CLI path"; exit 1;
            }
        else
            # Try from src/wolvenkit directly (no build/linux prefix)
            SRC_WK="$BUILD_DIR/../src/wolvenkit/Cyberpunk\ 2077\ Furigana/files/WolvenKit.ConsoleLinux/WolvenKit.CLI"
            
            if [ -f "$SRC_WK" ]; then
                WOLVENKIT_CLI=$(realpath -- "$SRC_WK") || { 
                    echo "Error: Failed to normalize src WolvenKit CLI path"; exit 1;
                }
            else
                # Try from build/linux/src/wolvenkit (no Cyberpunk folder)
                NOCYBERPUNK_WK="$BUILD_DIR/../src/wolvenkit/WolvenKit.ConsoleLinux/WolvenKit.CLI"
                
                if [ -f "$NOCYBERPUNK_WK" ]; then
                    WOLVENKIT_CLI=$(realpath -- "$NOCYBERPUNK_WK") || { 
                        echo "Error: Failed to normalize nocyberpunk WolvenKit CLI path"; exit 1;
                    }
                else
                    # Try from build/linux/src/wolvenkit/Cyberpunk (no Furigana folder)
                    NOFURIGANA_WK="$BUILD_DIR/../src/wolvenkit/Cyberpunk\ 2077/WolvenKit.ConsoleLinux/WolvenKit.CLI"
                    
                    if [ -f "$NOFURIGANA_WK" ]; then
                        WOLVENKIT_CLI=$(realpath -- "$NOFURIGANA_WK") || { 
                            echo "Error: Failed to normalize nofurigana WolvenKit CLI path"; exit 1;
                        }
                    else
                        # Try from build/linux/src/wolvenkit/Cyberpunk\ 2077 (no Furigana folder)
                        NOFURIGANA_WK="$BUILD_DIR/../src/wolvenkit/Cyberpunk\ 2077/WolvenKit.ConsoleLinux/WolvenKit.CLI"
                        
                        if [ -f "$NOFURIGANA_WK" ]; then
                            WOLVENKIT_CLI=$(realpath -- "$NOFURIGANA_WK") || { 
                                echo "Error: Failed to normalize nofurigana WolvenKit CLI path"; exit 1;
                            }
                        else
                            # Try from build/linux/src/wolvenkit/Cyberpunk\ 2077 (no Furigana folder) - with spaces handled
                            WOLVENKIT_CLI="$BUILD_DIR/../src/wolvenkit/Cyberpunk\ 2077/WolvenKit.ConsoleLinux/WolvenKit.CLI"
                            
                            if [ ! -f "$WOLVENKIT_CLI" ]; then
                                echo "Error: WolvenKit CLI not found at any expected location. Please ensure it's installed."
                                exit 1;
                            fi
                        fi
                    fi
                fi
            fi
        fi
    fi
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
