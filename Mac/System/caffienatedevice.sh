#!/bin/bash

# Prevent the device from sleeping
caffeinate -i &
CAFFEINATE_PID=$!

# Function to clean up and allow the device to sleep
cleanup() {
    kill $CAFFEINATE_PID
    exit 0
}

# Trap SIGINT and SIGTERM to run cleanup
trap cleanup SIGINT SIGTERM

# Keep the script running
while true; do
    sleep 1
done

# Direct terminal command to prevent the device from sleeping
# caffeinate -i
# (idle sleeping)