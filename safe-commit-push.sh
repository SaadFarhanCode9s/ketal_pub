#!/bin/bash

# A standard script for committing and pushing changes safely.

# Exit immediately if a command exits with a non-zero status.
set -e

# 1. Get the current branch name
current_branch=$(git rev-parse --abbrev-ref HEAD)
echo "🌿 You are on branch: $current_branch"

# 2. Check for uncommitted changes
if [[ -z $(git status --porcelain) ]]; then
    echo "✅ No changes to commit. Your branch is up to date."
    exit 0
fi

# 3. Stage all changes
echo "➕ Staging all changes..."
git add -A
echo "📝 The following changes are staged for commit:"
git status --short

echo "" # Add a blank line for readability

# 4. Prompt for a commit message
read -p "💬 Enter your commit message: " commit_message

# Check if the commit message is empty
if [[ -z "$commit_message" ]]; then
    echo "❌ Commit message cannot be empty. Aborting."
    git reset # Unstage the changes
    exit 1
fi

# 5. Commit the changes
echo "💾 Committing changes..."
git commit -m "$commit_message"

# 6. Push to the remote repository
echo "🚀 Pushing to origin ($current_branch)..."
git push origin "$current_branch"

echo "✅ Successfully committed and pushed to $current_branch on origin."
