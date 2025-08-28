#!/bin/bash

# This script extracts images from a video file, supporting both local files and YouTube URLs.
# It downloads the best quality from YouTube and saves them to an output folder.
# Usage: ./ffMpegimagefromvideos.sh <video_path_or_url> <start_time> <end_time> [photos_per_sec]

# Check for the correct number of arguments
if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <video_path_or_url> <start_time> <end_time> [photos_per_sec]"
    exit 1
fi

# Check for yt-dlp dependency if the input is a URL
if [[ "$1" == http* ]]; then
    if ! command -v yt-dlp &> /dev/null; then
        echo "Error: yt-dlp is not installed. Please install it to use YouTube URLs."
        echo "On macOS, you can install it with: brew install yt-dlp"
        exit 1
    fi
fi

# Assign arguments to variables
video_input="$1"
start_time="$2"
end_time="$3"
photos_per_sec="$4"


# If input is a URL, download the best quality video
if [[ "$video_input" == http* ]]; then
    # Create a temporary directory
    temp_dir=$(mktemp -d)
    temp_video_file="$temp_dir/video.mp4"
    echo "Temporary file: $temp_video_file"

    echo "Downloading best quality video from YouTube..."
    yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" -o "$temp_video_file" "$video_input"
    video_path="$temp_video_file"
    # Set output directory to the current directory for URLs
    output_dir="./output"
else
    video_path="$video_input"
    # Get the directory of the video file for local files
    output_dir=$(dirname "$video_path")
fi

# Set the output file pattern
output_pattern="$output_dir/output_%03d.png"

# If photos_per_sec is not provided, use the video's FPS
if [ -z "$photos_per_sec" ]; then
    # Get the video's FPS using ffprobe
    fps=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$video_path")
    # ffmpeg expects the fps as a fraction, so we evaluate it
    fps_eval=$(echo "$fps" | bc -l)
else
    fps_eval="$photos_per_sec"
fi

# Run the ffmpeg command
ffmpeg -i "$video_path" -ss "$start_time" -to "$end_time" -vf "fps=$fps_eval" "$output_pattern"

# Clean up the temporary file
if [[ "$video_input" == http* ]]; then
    rm -rf "$temp_dir"
fi

echo "Images extracted successfully to $output_dir"
