#!/bin/bash
# Download YouTube video in best possible quality (with audio)
# Domain: Media

URL="$1"
OUTPUT_DIR="${2:-"$HOME/Downloads"}"

if [[ -z "$URL" ]]; then
    echo "Usage: $0 <youtube_url> [output_directory]"
    echo "Example: $0 https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    exit 1
fi

# 1. Check for yt-dlp
if ! command -v yt-dlp &>/dev/null; then
    echo "⚙️  'yt-dlp' not found. Installing..."
    if ! command -v brew &>/dev/null; then
        echo "❌ Homebrew is required but not installed."
        exit 1
    fi
    brew install yt-dlp
    echo "✅ yt-dlp installed."
fi

# 2. Check for ffmpeg (required for merging high-res video with audio)
if ! command -v ffmpeg &>/dev/null; then
    echo "⚙️  'ffmpeg' not found (needed for merging audio & video). Installing..."
    brew install ffmpeg
    echo "✅ ffmpeg installed."
fi

echo "⏳ Downloading best quality video and audio from '$URL'..."

# yt-dlp fetches the absolute best video and best audio separately, 
# then uses ffmpeg to merge them into a single high-quality mp4 file.
yt-dlp -f 'bv*+ba/b' \
       --merge-output-format mp4 \
       -o "$OUTPUT_DIR/%(title)s.%(ext)s" \
       "$URL"

if [[ $? -eq 0 ]]; then
    echo "✅ Download complete! Saved to '$OUTPUT_DIR'"
else
    echo "❌ Download failed."
fi
