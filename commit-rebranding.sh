#!/bin/bash
# Ketal Rebranding - Git Commit Script
# Use this to properly stage and commit the rebranding changes

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         Ketal Rebranding - Git Commit Helper                   ║"
echo "║        ElementX → ketal Rebranding Commit                      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check git status
echo "📊 Current repository status:"
git status --short | head -5
echo "..."
echo ""

# Verify we're on the right branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "🌿 Current branch: $BRANCH"
echo ""

# Add all changes
echo "📝 Staging changes..."
git add -A

echo "✅ All changes staged"
echo ""

# Show what will be committed
echo "📋 Summary of changes to commit:"
git status --short | wc -l | xargs echo "   Total files:"
echo ""

# Commit message
COMMIT_MESSAGE="feat: Rebrand ElementX to ketal

This commit rebrandsthe application from Element X (ElementX) to ketal.

Changes made:
- Renamed directory ElementX/ → ketal/
- Updated project.yml: project name and organization
- Updated app.yml: APP_DISPLAY_NAME, BASE_BUNDLE_IDENTIFIER, APP_GROUP_IDENTIFIER
- Updated all target.yml files to reference ketal directory and scheme
- Updated bundle identifiers: io.element.elementx → io.ketal.app
- Updated app group identifiers: group.io.element → group.io.ketal
- Updated all xctestplan files with new containerPath references
- Updated 154 test files with '@testable import ketal'
- Updated build configuration files (localazy.json, fastlane, githooks)
- Updated documentation and copilot instructions
- Added comprehensive rebranding strategy guide for upstream merges

Configuration changes are isolated to minimize conflicts with upstream.
All source code logic remains intact and functional.

Next steps:
1. On macOS VM: swift run tools setup-project
2. Build with xcodebuild -scheme ketal -configuration Debug
3. For upstream merges: follow .rebranding-strategy.md guide

BREAKING CHANGES: Project name and bundle ID changed - update any external references"

echo "💾 Commit message:"
echo "───────────────────────────────────────────────────────────────"
echo "$COMMIT_MESSAGE"
echo "───────────────────────────────────────────────────────────────"
echo ""

read -p "🤔 Proceed with commit? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    git commit -m "$COMMIT_MESSAGE"
    echo ""
    echo "✅ Commit successful!"
    echo ""
    echo "📝 Commit details:"
    git log -1 --oneline
    echo ""
else
    echo "❌ Commit cancelled."
    git reset
    exit 1
fi
