#!/bin/bash

# This script determines the game path.
# On Linux/macOS systems without a Windows Registry,
# you may need to set the CP2077_FOLDER environment variable manually.

if [ -z "$CP2077_FOLDER" ]; then
    # Fallback or default if not set via env
    # You can edit this line to provide a default path for local builds
    export CP2077_FOLDER="/home/onebe6/1TB/Heroic/Cyberpunk/Cyberpunk 2077"
fi

echo "Cyberpunk 2077 Folder: $CP2077_FOLDER"
