#!/bin/bash
# Find and optionally kill a process running on a specific port
# Domain: Network & Development

PORT=$1
KILL_PROC=$2

if [[ -z "$PORT" ]]; then
    echo "Usage: $0 <port> [kill]"
    echo "Example: $0 8080"
    echo "Example: $0 8080 kill"
    exit 1
fi

echo "🔍 Scanning for processes on port $PORT..."
PIDS=$(lsof -t -i :$PORT)

if [[ -z "$PIDS" ]]; then
    echo "✅ No processes found running on port $PORT."
else
    lsof -i :$PORT
    if [[ "$KILL_PROC" == "kill" ]]; then
        echo "⚠️ Killing processes: $PIDS"
        kill -9 $PIDS
        echo "✅ Killed."
    fi
fi
