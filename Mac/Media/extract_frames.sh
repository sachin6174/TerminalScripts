#!/bin/bash
# Usage: ./extract_frames.sh <input_video> [output_directory] [frames_per_second]

INPUT="$1"
# Default to a timestamped folder on the Desktop if no directory is provided
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="${2:-"$HOME/Desktop/extracted_frames_$TIMESTAMP"}"
FPS="$3"

if [[ -z "$INPUT" ]]; then
  echo "Usage: $0 <input_video> [output_directory] [frames_per_second]"
  echo "Example: $0 my_video.mp4 frames_folder 2"
  exit 1
fi

if ! command -v ffmpeg &>/dev/null; then
  echo "⚙️  'ffmpeg' not found. Installing..."
  if ! command -v brew &>/dev/null; then
    echo "  → Homebrew not found. Installing Homebrew…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)"
  fi
  echo "  → Installing ffmpeg via Homebrew…"
  brew install ffmpeg
  echo "✅ ffmpeg installed."
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

if [[ -n "$FPS" ]]; then
  echo "⏳ Extracting $FPS frames per second from '$INPUT' to '$OUTPUT_DIR'..."
  # Uses the fps filter to extract specific amount of frames per second
  ffmpeg -i "$INPUT" -vf "fps=$FPS" "$OUTPUT_DIR/frame_%05d.png"
else
  echo "⏳ Extracting ALL frames from '$INPUT' to '$OUTPUT_DIR'..."
  # -vsync 0 ensures exact original frames without dropping/duplicating (perfect for VFR)
  ffmpeg -i "$INPUT" -vsync 0 "$OUTPUT_DIR/frame_%05d.png"
fi

echo "✅ Extraction complete! Frames are saved in '$OUTPUT_DIR/'"
