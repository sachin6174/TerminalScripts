#!/bin/bash

# Target folder: Default to current directory if none provided.
# Drag-and-drop friendly: Rebuilds paths with spaces from all arguments.
ROOT_DIR="${*:-.}"

# Help screen
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  echo "Usage: $0 [directory]"
  echo "Recursively finds and deletes all .mp4 and .m4a files in the specified directory."
  echo "If no directory is specified, it defaults to the current working directory."
  exit 0
fi

# Clear screen or print nice header
echo "=================================================="
echo "      🗑️  Recursive MP4 & M4A Media Cleaner       "
echo "=================================================="

# Check if target is a valid directory
if [[ ! -d "$ROOT_DIR" ]]; then
  echo "❌ Error: '$ROOT_DIR' is not a valid directory."
  exit 1
fi

# Resolve absolute path for clarity
ABS_PATH=$(cd "$ROOT_DIR" && pwd)
echo "📁 Target Directory: $ABS_PATH"
echo "🔍 Searching for .mp4 and .m4a files recursively..."
echo "--------------------------------------------------"

# Function to format bytes into human-readable size (pure Bash)
format_size() {
  local bytes=$1
  if [[ -z "$bytes" || "$bytes" -eq 0 ]]; then
    echo "0 B"
    return
  fi
  
  local -a units=("B" "KB" "MB" "GB" "TB")
  local unit_idx=0
  local size=$bytes
  local decimal=""
  
  while (( size >= 1024 && unit_idx < 4 )); do
    local remainder=$(( (size % 1024) * 10 / 1024 ))
    size=$(( size / 1024 ))
    decimal=".$remainder"
    unit_idx=$(( unit_idx + 1 ))
  done
  
  if [ $unit_idx -eq 0 ]; then
    echo "${size} ${units[$unit_idx]}"
  else
    echo "${size}${decimal} ${units[$unit_idx]}"
  fi
}

# Temporary files to store search results
TEMP_FILE_LIST=$(mktemp)

# Find matching files recursively (case-insensitive)
find "$ABS_PATH" -type f \( -iname "*.mp4" -o -iname "*.m4a" \) -print0 > "$TEMP_FILE_LIST"

# Count files
FILE_COUNT=0
TOTAL_BYTES=0

# Read the null-terminated list
while IFS= read -r -d '' FILE; do
  FILE_COUNT=$((FILE_COUNT + 1))
  FILE_SIZE=$(stat -f%z "$FILE" 2>/dev/null || echo 0)
  TOTAL_BYTES=$((TOTAL_BYTES + FILE_SIZE))
  # Also print the file path relative to ROOT_DIR (or just absolute)
  REL_PATH="${FILE#$ABS_PATH/}"
  HUMAN_FILE_SIZE=$(format_size "$FILE_SIZE")
  echo "📄 [Found] $REL_PATH ($HUMAN_FILE_SIZE)"
done < "$TEMP_FILE_LIST"

if [[ $FILE_COUNT -eq 0 ]]; then
  echo "✨ No .mp4 or .m4a files found in this directory!"
  rm -f "$TEMP_FILE_LIST"
  exit 0
fi

HUMAN_SIZE=$(format_size "$TOTAL_BYTES")

echo "--------------------------------------------------"
echo "📊 Summary:"
echo "   • Total Files Found: $FILE_COUNT"
echo "   • Total Space to Free: $HUMAN_SIZE"
echo "--------------------------------------------------"

# Ask for confirmation
read -p "⚠️  Are you sure you want to permanently delete these $FILE_COUNT files? (y/N): " CONFIRMATION

if [[ "$CONFIRMATION" =~ ^[Yy]$ ]]; then
  echo "🚀 Deleting files..."
  DELETED_COUNT=0
  
  while IFS= read -r -d '' FILE; do
    if rm "$FILE" 2>/dev/null; then
      REL_PATH="${FILE#$ABS_PATH/}"
      echo "✅ Deleted: $REL_PATH"
      DELETED_COUNT=$((DELETED_COUNT + 1))
    else
      echo "❌ Failed to delete: $FILE"
    fi
  done < "$TEMP_FILE_LIST"
  
  echo "--------------------------------------------------"
  echo "🎉 Success! Deleted $DELETED_COUNT/$FILE_COUNT files."
  echo "🧹 Total space freed: $HUMAN_SIZE"
  echo "================================================--"
else
  echo "❌ Deletion cancelled. No files were deleted."
  echo "================================================--"
fi

# Cleanup
rm -f "$TEMP_FILE_LIST"
