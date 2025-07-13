#!/usr/bin/env bash
set -e

# -----------------------------------------------------------------------------
# trim_video.sh
#   A simple tool to extract a video+audio segment using ffmpeg on macOS.
#
# Usage:
#   trim_video.sh <input_file> <start_time> <end_time> [output_file]
#
#   <start_time> and <end_time> can be in HH:MM:SS or seconds (e.g. 90).
#   If [output_file] is omitted, one is auto-generated.
# -----------------------------------------------------------------------------

# 1) Ensure ffmpeg is installed
if ! command -v ffmpeg &>/dev/null; then
  echo "⚙️  'ffmpeg' not found. Installing..."

  # 1a) Install Homebrew if needed
  if ! command -v brew &>/dev/null; then
    echo "  → Homebrew not found. Installing Homebrew…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "  → Homebrew installed."
    # ensure brew is on PATH for this session
    eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)"
  fi

  # 1b) Install ffmpeg via Homebrew
  echo "  → Installing ffmpeg via Homebrew…"
  brew install ffmpeg
  echo "✅ ffmpeg installed."
fi

# 2) Parse args
if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <input_file> <start_time> <end_time> [output_file]"
  exit 1
fi

INPUT="$1"
START="$2"
END="$3"

# 3) Determine output filename
if [[ -n "$4" ]]; then
  OUTPUT="$4"
else
  BASENAME=$(basename "$INPUT")
  EXT="${BASENAME##*.}"
  NAME="${BASENAME%.*}"
  # replace colons for filesystem
  OUTSTAMP="${START//:/-}_to_${END//:/-}"
  OUTPUT="${NAME}_${OUTSTAMP}.${EXT}"
fi

# 4) Run ffmpeg trim
echo "✂️  Trimming \"$INPUT\" from $START to $END → \"$OUTPUT\"…"
ffmpeg -y \
  -i "$INPUT" \
  -ss "$START" \
  -to "$END" \
  -c copy \
  -avoid_negative_ts make_zero \
  "$OUTPUT"

echo "🎉 Done! Saved segment as \"$OUTPUT\"."
# ./trim_video.sh /path/to/movie.mp4 00:02:15 00:05:00