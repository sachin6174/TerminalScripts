#!/bin/bash

# Usage: ./batch_make_videos.sh <root_directory>
# Drag-and-drop friendly: rebuild the path from all args in case spaces were not escaped.

ROOT_DIR="${*:-.}"

if [[ -z "$ROOT_DIR" ]]; then
  echo "Usage: $0 <root_directory>"
  exit 1
fi

if [[ ! -d "$ROOT_DIR" ]]; then
  echo "❌ Not a directory: $ROOT_DIR"
  exit 1
fi

# Traverse all directories safely (handles spaces)
find "$ROOT_DIR" -type d -print0 | while IFS= read -r -d '' DIR; do
  echo "🔍 Processing folder: $DIR"

  # Find image (any .png in this folder)
  IMAGE=""
  while IFS= read -r -d '' CANDIDATE; do
    IMAGE="$CANDIDATE"
    break
  done < <(find "$DIR" -maxdepth 1 -type f -iname "*.png" -print0)
  if [[ -z "$IMAGE" ]]; then
    echo "⚠️ No image found in $DIR, skipping..."
    continue
  fi

  # Process all .m4a audio files in this folder
  find "$DIR" -maxdepth 1 -type f -iname "*.m4a" -print0 | while IFS= read -r -d '' AUDIO; do
    BASENAME=$(basename "$AUDIO" .m4a)
    OUTPUT="$DIR/$BASENAME.mp4"

    echo "🎧 Converting: $BASENAME.m4a → $BASENAME.mp4"

    # Get audio duration
    DURATION=$(ffprobe -i "$AUDIO" -show_entries format=duration -v quiet -of csv="p=0")

    # Create the video (exactly same duration as audio)
    ffmpeg -y -loop 1 -framerate 2 -i "$IMAGE" -i "$AUDIO" \
      -t "$DURATION" \
      -c:v libx264 -tune stillimage -c:a aac -b:a 192k \
      -pix_fmt yuv420p -shortest "$OUTPUT" < /dev/null

    if [[ $? -eq 0 ]]; then
      echo "✅ Created video: $OUTPUT"
    else
      echo "❌ Failed for: $AUDIO"
    fi
  done
done
