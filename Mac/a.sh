#!/bin/bash

# Create a safe local directory for global npm installs
mkdir -p ~/.npm-global

# Configure npm to use the new directory
npm config set prefix ~/.npm-global

# Add the new path to your shell config (zsh for macOS default)
if ! grep -q "export PATH=\$HOME/.npm-global/bin:\$PATH" ~/.zshrc; then
  echo 'export PATH=$HOME/.npm-global/bin:$PATH' >> ~/.zshrc
fi

# Reload shell configuration
source ~/.zshrc

# Verify npm path is correct
echo "npm will now install global packages into: $(npm config get prefix)"

# Reinstall npm safely (no sudo needed)
npm install -g npm@11.6.0

echo "✅ npm fixed! Run 'npm -v' to check version."

