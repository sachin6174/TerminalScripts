#!/usr/bin/env bash

set -euo pipefail

echo "==> MongoDB + Compass install & setup script for macOS"

# Detect architecture for Homebrew path
if [[ "$(uname -m)" == "arm64" ]]; then
  BREW_PREFIX="/opt/homebrew"
else
  BREW_PREFIX="/usr/local"
fi

# Ensure Homebrew is installed
if ! command -v brew &>/dev/null; then
  echo "Homebrew not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Load brew into current shell
  if [[ -f "${BREW_PREFIX}/bin/brew" ]]; then
    eval "$(${BREW_PREFIX}/bin/brew shellenv)"
  fi
else
  echo "Homebrew already installed."
  if [[ -f "${BREW_PREFIX}/bin/brew" ]]; then
    eval "$(${BREW_PREFIX}/bin/brew shellenv)" || true
  fi
fi

echo "==> Updating Homebrew and tapping official MongoDB repo"
brew update
brew tap mongodb/brew

# Install MongoDB Community Edition (6.0.x via official tap, stable widely available)
echo "==> Installing MongoDB Community Edition"
brew install mongodb-community@6.0

# Start MongoDB service so it persists across reboots/logins
echo "==> Starting MongoDB as a background service"
brew services start mongodb-community@6.0

# Install MongoDB Compass (GUI)
echo "==> Installing MongoDB Compass"
brew install --cask mongodb-compass || {
  echo "brew cask install failed; attempting direct download fallback..."

  TMPDIR="$(mktemp -d)"
  cd "$TMPDIR"

  # Get latest stable version (hardcoding expected file name pattern; adjust if version changes)
  COMPASS_URL="https://downloads.mongodb.com/compass/mongodb-compass-1.46.7-darwin-arm64.dmg"
  # Fallback: user can change URL manually if architecture differs (x86_64 builds etc.)
  echo "Downloading MongoDB Compass from $COMPASS_URL"
  curl -L -o compass.dmg "$COMPASS_URL"

  echo "Mounting DMG"
  MOUNT_POINT=$(hdiutil attach compass.dmg -nobrowse -quiet | awk -F'\t' '/\/Volumes\// {print $3}')
  if [[ -z "$MOUNT_POINT" ]]; then
    echo "Failed to mount Compass DMG. Please install manually."
    exit 1
  fi

  echo "Copying Compass to /Applications"
  cp -R "${MOUNT_POINT}/MongoDB Compass.app" /Applications/

  echo "Detaching DMG"
  hdiutil detach "$MOUNT_POINT" -quiet

  echo "Cleanup"
  rm -rf "$TMPDIR"
}

# Wait briefly for service to settle
sleep 2

# Verification
echo "==> Verifying MongoDB service status"
if brew services list | grep -E 'mongodb-community(@6\.0)?\s+started' >/dev/null; then
  echo "✔ MongoDB service is running."
else
  echo "⚠ MongoDB service is not obviously running. Run: brew services list"
fi

echo
cat <<EOF

✅ Done.

Quick usage checks:
  1. Open Mongo shell: 
       mongosh
     then inside it: 
       > db.runCommand({ ping: 1 })

  2. Launch GUI: open MongoDB Compass from /Applications or via Spotlight.

Helpful commands:
  - Stop MongoDB:    brew services stop mongodb-community@6.0
  - Restart:         brew services restart mongodb-community@6.0
  - Check services:  brew services list
  - Logs:            tail -f $( [[ "$(uname -m)" == "arm64" ]] && echo "/opt/homebrew/var/log/mongodb/mongo*.log" || echo "/usr/local/var/log/mongodb/mongo*.log" )

EOF
