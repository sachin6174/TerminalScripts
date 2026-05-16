#!/bin/bash
# Safely clear macOS system caches, DNS, and user temporary files
# Domain: System Maintenance

echo "🧹 Starting macOS System Cleanup..."

# 1. Flush DNS Cache
echo "🌐 Flushing DNS Cache..."
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder

# 2. Clear User Cache
echo "🗑️ Clearing User Cache (~/Library/Caches)..."
# Using a safe approach to only delete contents, not the folder itself
rm -rf ~/Library/Caches/* 2>/dev/null || true

# 3. Clear System Logs
echo "📜 Clearing System Logs..."
sudo rm -rf /private/var/log/* 2>/dev/null || true

echo "✅ macOS Cleanup Complete! Your system should feel a bit fresher."
