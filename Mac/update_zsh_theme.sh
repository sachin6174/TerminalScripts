#!/bin/bash

# File to modify
ZSHRC_FILE="$HOME/.zshrc"

# Backup the original file before modifying
cp "$ZSHRC_FILE" "$ZSHRC_FILE.bak"

# Replace the theme line
sed -i '' 's/^ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC_FILE"

echo "ZSH theme has been updated in $ZSHRC_FILE."
echo "Backup saved as $ZSHRC_FILE.bak."