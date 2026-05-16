#!/bin/bash

INPUT="$1"

if [ ! -f "$INPUT" ]; then
    echo "❌ File not found"
    exit 1
fi

DIR="$(dirname "$INPUT")"
NAME="$(basename "$INPUT")"
BASE="${NAME%.*}"

OUTPUT="$DIR/${BASE}_small.jpg"
TARGET=1000000   # 1 MB

echo "📦 Compressing..."

# convert to jpg first (best compression)
sips -s format jpeg "$INPUT" --out "$OUTPUT" >/dev/null

QUALITY=90
WIDTH=2000

while [ $(stat -f%z "$OUTPUT") -gt $TARGET ]; do
    echo "→ Reducing quality=$QUALITY width=$WIDTH"

    sips -Z $WIDTH -s formatOptions $QUALITY "$OUTPUT" --out "$OUTPUT" >/dev/null

    QUALITY=$((QUALITY - 5))
    WIDTH=$((WIDTH - 200))

    if [ $QUALITY -lt 20 ]; then
        echo "⚠️ Can't compress below 1MB without heavy loss"
        break
    fi
done

echo "✅ Done!"
echo "Saved at: $OUTPUT"
echo "Final size:"
stat -f%z "$OUTPUT"
