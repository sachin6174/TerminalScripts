#!/bin/bash
# Download YouTube video in best possible quality (with audio)
# Domain: Media

URL="$1"
# Automatically save to Desktop in a dedicated folder
OUTPUT_DIR="${2:-"$HOME/Desktop/YouTube_Downloads"}"

if [[ -z "$URL" ]]; then
    echo "Usage: $0 <youtube_url> [output_directory]"
    echo "Example: $0 https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    exit 1
fi

# We use the pre-compiled macOS binary to bypass Python 3.9 version limits on macOS
YT_DLP_BIN="$HOME/Desktop/YouTube_Downloads/yt-dlp_bin"

if [[ ! -f "$YT_DLP_BIN" ]]; then
    echo "⚙️  Downloading latest yt-dlp engine..."
    mkdir -p "$OUTPUT_DIR"
    curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos -o "$YT_DLP_BIN"
    chmod +x "$YT_DLP_BIN"
    echo "✅ Engine installed."
fi

# 2. Check for ffmpeg (required for merging high-res video with audio)
if ! command -v ffmpeg &>/dev/null; then
    echo "⚙️  'ffmpeg' not found (needed for merging audio & video). Installing..."
    brew install ffmpeg
    echo "✅ ffmpeg installed."
fi

echo "⏳ Downloading best quality video and audio from '$URL'..."

# We specifically request h264 (avc) video and m4a audio. 
# This guarantees the downloaded .mp4 file will play natively on Mac/QuickTime!
"$YT_DLP_BIN" -f 'bestvideo[vcodec^=avc]+bestaudio[ext=m4a]/bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best' \
       --restrict-filenames \
       --merge-output-format mp4 \
       -o "$OUTPUT_DIR/%(title)s.%(ext)s" \
       "$URL"

if [[ $? -eq 0 ]]; then
    echo "✅ Download complete! Saved to '$OUTPUT_DIR'"
else
    echo "❌ Download failed."
fi
