#!/bin/bash
# Cleans up local branches that have been merged into main or master
# Domain: Git / Version Control

# Make sure we are in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "❌ Error: Not a git repository."
  exit 1
fi

MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
if [[ -z "$MAIN_BRANCH" ]]; then
    MAIN_BRANCH="main" # Fallback
fi

echo "🧹 Fetching latest from origin..."
git fetch -p

echo "🧹 Finding branches merged into $MAIN_BRANCH..."
MERGED_BRANCHES=$(git branch --merged $MAIN_BRANCH | grep -v "\*" | grep -v "$MAIN_BRANCH" | grep -v "master")

if [[ -z "$MERGED_BRANCHES" ]]; then
    echo "✅ No merged branches to clean up."
else
    echo "🗑️ Deleting the following branches:"
    echo "$MERGED_BRANCHES"
    echo "$MERGED_BRANCHES" | xargs -n 1 git branch -d
    echo "✅ Cleanup complete!"
fi
