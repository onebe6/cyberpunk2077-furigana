#!/bin/bash
# Unified script managing WolvenKit subtitle processing, asset deployment, and environment builds.

# Exit immediately if a command fails, an unset variable is used, or a piped command fails
set -euo pipefail

# Terminal colors for beautiful, scannable logging
GEAR="\e[1;36m⚙\e[0m"
CHECK="\e[1;32m✔\e[0m"
ALERT="\e[1;31m✘\e[0m"
INFO="\e[1;34mℹ\e[0m"

log() { echo -e "${GEAR} $1"; }
log_success() { echo -e "${CHECK} \e[1;32m$1\e[0m"; }
log_warn() { echo -e "${INFO} \e[1;33m$1\e[0m"; }
log_error() { echo -e "${ALERT} \e[1;31m$1\e[0m"; }

# Move to script directory safely
cd "$(dirname "$0")"
BUILD_DIR=$(pwd)

# --- 1. Configuration & Path Setup ---
CONFIG="${1:-Release}"
log "Configuration profile: \e[1;35m$CONFIG\e[0m"

if [ -f "./cp2077path.sh" ]; then
    # Temporarily allow unbound variables while sourcing the external path configuration
    set +u
    . "./cp2077path.sh"
    set -u
else
    log_error "Critical Error: cp2077path.sh not found!"
    exit 1
fi

# Ensure CP2077_FOLDER was actually populated and isn't empty
if [ -z "${CP2077_FOLDER:-}" ]; then
    log_error "Critical Error: CP2077_FOLDER variable was not set by cp2077path.sh!"
    exit 1
fi
log "Cyberpunk 2077 Path: \e[1;34m$CP2077_FOLDER\e[0m"

# Absolute paths for staging environments
WOLVENKITFILES="$BUILD_DIR/target"
MODFILES="$WOLVENKITFILES/Mod_Exported"
RAWFILES="$WOLVENKITFILES/Raw"
ARCHIVEFOLDER="$CP2077_FOLDER/archive/pc/content"
ARCHIVEFOLDER_EP1="$CP2077_FOLDER/archive/pc/ep1"

WOLVENKIT_CLI="wolvenkit"

# --- 2. Environment Sanity Checks ---
if ! command -v "$WOLVENKIT_CLI" &> /dev/null; then
    log_error "WolvenKit CLI '$WOLVENKIT_CLI' not found in your PATH."
    exit 1
fi

log "Terminating any running Cyberpunk 2077 instances..."
killall -q Cyberpunk2077.exe || true

# --- 3. WolvenKit Extraction & Processing Pipeline ---
log "Flushing old extraction caches..."
rm -rf "$MODFILES" "$RAWFILES"
mkdir -p "$MODFILES" "$RAWFILES"

log "Extracting Base game subtitles..."
if [ -d "$ARCHIVEFOLDER" ]; then
    pushd "$ARCHIVEFOLDER" > /dev/null
    # Dropping the wildcard filter to extract all contents cleanly
    "$WOLVENKIT_CLI" unbundle -p lang_ja_text.archive -o "$MODFILES" || log_warn "Base subtitles unbundle returned a non-zero exit code."
    popd > /dev/null
else
    log_warn "Base archive folder missing, skipping asset extraction."
fi

log "Extracting Phantom Liberty (EP1) subtitles..."
if [ -d "$ARCHIVEFOLDER_EP1" ]; then
    pushd "$ARCHIVEFOLDER_EP1" > /dev/null
    # Dropping the wildcard filter to extract all contents cleanly
    "$WOLVENKIT_CLI" unbundle -p lang_ja_text.archive -o "$MODFILES" || log_warn "EP1 subtitles unbundle returned a non-zero exit code."
    popd > /dev/null
else
    log_warn "EP1 archive folder missing, skipping asset extraction."
fi

log "Syncing extracted files to Raw staging..."
if [ -d "$MODFILES" ] && [ "$(ls -A "$MODFILES")" ]; then
    cp -r "$MODFILES/." "$RAWFILES/"
else
    log_warn "Source folder is empty. No assets found to mirror."
fi

log "Decoding serialized REDengine CR2W files..."
if [ -d "$RAWFILES" ] && [ "$(ls -A "$RAWFILES")" ]; then
    "$WOLVENKIT_CLI" cr2w -p "$RAWFILES" -s || log_warn "CR2W decoder finished with warnings."
else
    log_warn "Raw folder is empty. Skipping CR2W decode phase."
fi

log "Purging unneeded source cache files..."
find "$RAWFILES" -name "*.json" ! -name "*.json.json" -type f -delete 2>/dev/null || true

# Isolating Python virtual environment environment changes
if [ -d ".venv" ]; then
    log "Activating local Python Virtual Environment (.venv)..."
    . .venv/bin/activate
fi

log "Executing Unicode unescape filters..."
if [ -f "../unescapeunicode.py" ]; then
    python3 ../unescapeunicode.py "$RAWFILES" || log_error "Unicode unescape parser crashed."
else
    log_warn "../unescapeunicode.py script target missing. Skipping phase."
fi

# Deactivate venv if we activated it to clean up current terminal session
if [ -n "${VIRTUAL_ENV:-}" ]; then deactivate; fi


# --- 4. Mod Staging & File Deployment ---
log "Staging build trees to deployment directory..."

# Deploy Redscript source structural tree
mkdir -p "$CP2077_FOLDER/r6/scripts/cyberpunk2077-furigana"
if [ -d "../../src/redscript" ]; then
    cp -rf ../../src/redscript/* "$CP2077_FOLDER/r6/scripts/cyberpunk2077-furigana/"
fi

# Deploy RED4ext plugins based on active profile configuration context
mkdir -p "$CP2077_FOLDER/dist/red4ext/plugins"
if [ -d "../../src/red4ext/x64/$CONFIG" ]; then
    cp -rf ../../src/red4ext/x64/$CONFIG/*.dll "$CP2077_FOLDER/dist/red4ext/plugins/"
else
    log_warn "RED4ext binaries matching profile [$CONFIG] missing. Skipping copy."
fi

# Deploy Cyber Engine Tweaks nativeSettings configurations
mkdir -p "$CP2077_FOLDER/bin/x64/plugins/cyber_engine_tweaks/mods/nativeSettings"
if [ -d "../../src/CP77_nativeSettings/nativeSettings" ]; then
    cp -rf ../../src/CP77_nativeSettings/nativeSettings/* "$CP2077_FOLDER/bin/x64/plugins/cyber_engine_tweaks/mods/nativeSettings/"
else
    log_warn "nativeSettings template data not found; fallback placeholder workspace generated."
fi

# Set up WolvenKit packing workspace destination mapping layout
mkdir -p "$CP2077_FOLDER/dist/wolvenkit/Cyberpunk 2077 Furigana/packed/"

log "Pushing staged assets directly into game root directory..."
if [ -d "$CP2077_FOLDER/dist" ]; then
    cp -rf "$CP2077_FOLDER/dist"/* "$CP2077_FOLDER/"
fi


# --- 5. Redscript Compilation Engine Trigger ---
log "Interrogating local environment for Redscript compilation engines..."

REDSCRIPT_CMD=""
if [ -f "../redscript-cli" ]; then
    REDSCRIPT_CMD="../redscript-cli"
elif [ -f "../redscript-cli.exe" ]; then
    if command -v wine &> /dev/null; then
        REDSCRIPT_CMD="wine ../redscript-cli.exe"
    else
        REDSCRIPT_CMD="../redscript-cli.exe"
    fi
fi

if [ -n "$REDSCRIPT_CMD" ]; then
    log "Compiling scripts using entrypoint: \e[1;33m$REDSCRIPT_CMD\e[0m"
    $REDSCRIPT_CMD compile \
        -s "$CP2077_FOLDER/r6/scripts" \
        -b "$CP2077_FOLDER/r6/cache/final.redscripts" \
        -o "$CP2077_FOLDER/r6/cache/final.redscripts.modded" || log_error "Redscript compilation engine threw a terminal compilation failure!"
else
    log_warn "Redscript compiler engine binary not located in parent architecture layouts. Compilation skipped."
fi

log_success "Build complete!"
