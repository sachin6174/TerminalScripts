#!/bin/bash

# Script to install cloudflared on macOS

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Checking for Homebrew..."
# Check if Homebrew is installed
if ! command -v brew &> /dev/null
then
    echo "Homebrew not found. Installing Homebrew..."
    # Install Homebrew using the official script
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "Homebrew installed successfully."
else
    echo "Homebrew is already installed."
fi

echo "Updating Homebrew..."
brew update

echo "Running brew doctor to check for issues..."
brew doctor

echo "Installing or upgrading cloudflared..."
# Install or upgrade cloudflared using Homebrew
brew install cloudflared


echo "cloudflared installation/update complete."

# Verify the installation
echo "Verifying cloudflared installation..."
cloudflared --version

echo "Installation successful! You can now use the 'cloudflared' command."