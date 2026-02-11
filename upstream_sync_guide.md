# Upstream Sync Guide

## Overview
This guide explains how to safely sync your **Ketal** application with the original **ElementX** repository `element-hq/element-x-ios` while preserving all your rebranding and custom features.

## The Script: `upstream_sync.sh`
The synchronization is handled by the `upstream_sync.sh` script located in the root of your project.

### Key Features
- **Automatic Backups:** Creates a backup branch before doing anything. Use this to roll back if needed.
- **Smart Merging:** Automatically resolves conflicts in configuration files (like `project.yml`, `app.yml`), ensuring your Ketal branding is **always** preserved.
- **Validation:** Runs checks after merging to ensure the project name and bundle IDs are still correct.

## How to Run the Sync

### Prerequisites
1. You must be on the `main` branch.
2. Your working directory must be clean (no uncommitted changes).
3. Internet connection (to fetch from GitHub).

### Command
```bash
./upstream_sync.sh
```

### What Happens Next?
1. **Pre-flight Checks:** Verifies you are ready to sync.
2. **Backup:** A branch named `backup-before-upstream-sync-YYYY-MM-DD-HHMMSS` is created.
3. **Fetch & Merge:** The script fetches the latest `main` from `element-hq/element-x-ios` and attempts to merge it.
4. **Auto-Resolution:** If there are conflicts in known configuration files, the script automatically keeps your Ketal version.
5. **Project Regeneration:** Runs `swift run tools setup-project` to regenerate the Xcode project and Ensure everything is consistent.
6. **Final Validation:** Checks that the app name is still "Ketal" and bundle IDs are correct.

## Handling Manual Conflicts
Sometimes, the upstream code might change the same source files (Swift code) that you have modified. The script cannot safely resolve these automatically.

 **If the script says "Manual Intervention Required":**
1. Run `git status` to see the conflicted files.
2. Open the files and look for the conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`).
3. Edit the code to combine the changes (keep your custom logic while incorporating upstream improvements).
4. Save the files.
5. Run `git add <file>`.
6. Run `git commit` to finish the merge.
7. Run `swift run tools setup-project` manually to ensure the project is healthy.

## Rolling Back
If anything breaks or you want to undo the sync:

```bash
# Finds the backup branch name (printed in the script output)
git reset --hard backup-before-upstream-sync-YYYY-MM-DD-HHMMSS
```

## Best Practices
- **Sync Regularly:** Syncing monthly will keep the conflicts smaller and easier to manage.
- **Test After Sync:** Always build the app and run a quick manual test after syncing.
