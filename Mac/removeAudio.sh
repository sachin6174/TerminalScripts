#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: ./removeAudio.sh <video_path>"
    exit 1
fi

INPUT="$1"

DIR=$(dirname "$INPUT")
FILENAME=$(basename -- "$INPUT")
EXT="${FILENAME##*.}"
NAME="${FILENAME%.*}"

OUTPUT="$DIR/${NAME}_noaudio.${EXT}"

ffmpeg -i "$INPUT" -an -c:v copy "$OUTPUT"

echo "Done -> $OUTPUT"

# Open folder in Finder
open "$DIR"

