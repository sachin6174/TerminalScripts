#!/bin/bash

# This script changes the desktop wallpaper to a random image from a specified folder at a given frequency.
# Usage: ./wallpaper_changer.sh <folder_path> [frequency_in_seconds]

# Check for the folder path argument
if [ -z "$1" ]; then
    echo "Usage: $0 <folder_path> [frequency_in_seconds]"
    exit 1
fi

# Check if the provided path is a directory
if [ ! -d "$1" ]; then
    echo "Error: The provided path is not a directory."
    exit 1
fi

FOLDER_PATH="$1"
# Set the frequency from the second argument, or default to 10 seconds
FREQUENCY=${2:-10}

echo "Starting wallpaper changer..."
echo "Folder: $FOLDER_PATH"
echo "Frequency: $FREQUENCY seconds"

while true; do
    # Find all image files (jpg, jpeg, png, heic) in the folder, and pick one at random
    IMAGE_PATH=$(find "$FOLDER_PATH" -type f -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.heic" | awk 'BEGIN {srand()} {a[NR]=$0} END {print a[int(rand()*NR)+1]}')

    if [ -n "$IMAGE_PATH" ]; then
        # Use osascript to change the wallpaper
        osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$IMAGE_PATH\""
        echo "Wallpaper changed to: $IMAGE_PATH"
    else
        echo "No images found in the specified folder."
        exit 1
    fi

    sleep "$FREQUENCY"
done
