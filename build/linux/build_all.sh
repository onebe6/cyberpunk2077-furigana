#!/bin/bash
# Note: Standard shell scripts usually require execution permissions
# Run as: bash build_all.sh OR chmod +x build_all.sh && ./build_all.sh

cd "$(dirname "$0")"

# Does not compile C++ binaries
if [ ! -d ".venv" ]; then
  python3 -m venv .venv
fi

source .venv/bin/activate
pip install -r requirements.txt

./build.sh
./export_subtitles.sh
python3 process_subtitles.py
./import_subtitles.sh
