# Ketal iOS Rebranding - Quick Start Guide

## ✅ What Has Been Done

All rebranding from **ElementX** to **ketal** has been completed on this Linux environment:

- ✓ Directory structure renamed (ElementX → ketal)
- ✓ Configuration files updated (project.yml, app.yml)
- ✓ Bundle IDs changed (io.element.elementx → io.ketal.app)
- ✓ Target schemes updated (ElementX → ketal)
- ✓ 154 test files updated
- ✓ All build configuration files updated
- ✓ Documentation and guides created

## 🚀 Next Steps on macOS VM

### Step 1: Copy to macOS (if needed)
```bash
# Already synced to macOS via sync-to-mac.sh
```

### Step 2: Regenerate Xcode Project
```bash
cd /path/to/ketal
swift run tools setup-project
# This generates ketal.xcodeproj from updated YAML configs
```

### Step 3: Open in Xcode
```bash
open ketal.xcodeproj
```

### Step 4: Select Scheme
- In Xcode, select scheme: **ketal** (not "Element X")

### Step 5: Select Simulator
- Choose desired iOS simulator (iPhone 16 Pro, iPad, etc.)

### Step 6: Build & Run
```bash
# Via Xcode: Cmd+R
# Or via terminal:
xcodebuild -scheme ketal -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16'
```

## 📋 Key Identifiers

| Setting | Value |
|---------|-------|
| App Name | ketal |
| Bundle ID | io.ketal.app |
| App Group | group.io.ketal |
| Scheme | ketal |
| Directory | ketal/ |
| Organization | ketal |

## 🔍 Verification Checklist

Before building, verify:

- [ ] `ketal/` directory exists
- [ ] `project.yml` has `name: ketal`
- [ ] `app.yml` shows correct bundle IDs
- [ ] Test imports use `@testable import ketal`

## 🔄 Upstream Merge Strategy

If pulling updates from Element X iOS upstream:

1. **Create merge branch:**
   ```bash
   git fetch upstream
   git checkout -b merge/upstream-latest
   git merge upstream/main
   ```

2. **Resolve conflicts:** Keep ketal configuration for:
   - project.yml
   - app.yml
   - All target.yml files
   - All .xctestplan files

3. **Accept upstream changes for:**
   - Source code files in ketal/Sources/
   - All business logic files

4. **Regenerate project:**
   ```bash
   swift run tools setup-project
   ```

5. **Test build:**
   ```bash
   xcodebuild -scheme ketal -configuration Debug
   ```

See `.rebranding-strategy.md` for detailed instructions.

## 🐛 Troubleshooting

### Build Error: "ElementX has no scheme"
**Solution:** Run `swift run tools setup-project` again to regenerate

### Import Error: "ketal module not found"
**Solution:** Check that all test files have `@testable import ketal` (not ElementX)

### Bundle ID Mismatch
**Solution:** Verify `app.yml` has `BASE_BUNDLE_IDENTIFIER: io.ketal.app`

### Entitlements Error
**Solution:** Ensure `ketal.entitlements` file exists (renamed from ElementX.entitlements)

## 📚 Documentation Files

- **REBRANDING_SUMMARY.txt** - Complete summary of all changes
- **.rebranding-strategy.md** - Detailed upstream merge guide
- **docs/FORKING.md** - Updated with new bundle IDs
- **.github/copilot-instructions.md** - Updated with ketal references

## 💾 Committing Changes

To commit the rebranding:

```bash
# Option 1: Use the provided script
chmod +x commit-rebranding.sh
./commit-rebranding.sh

# Option 2: Manual commit
git add .
git commit -m "feat: Rebrand ElementX to ketal

- Renamed ElementX/ → ketal/
- Updated bundle IDs: io.element.elementx → io.ketal.app
- Updated app group: group.io.element → group.io.ketal
- Updated all configuration and test files
- Ready for macOS build and TestFlight submission"
```

## 🎯 For App Store Submission

When submitting to App Store:
- App Name: **ketal**
- Bundle ID: **io.ketal.app**
- Scheme: **ketal**
- Signing Team: Configured in app.yml

## 📞 Support

If you encounter any issues:
1. Check REBRANDING_SUMMARY.txt for verification checklist
2. Review .rebranding-strategy.md for advanced scenarios
3. Verify all YAML configuration files have correct values
4. Run `swift run tools setup-project` to regenerate Xcode project

---

**Status:** ✅ Complete and ready for macOS build
**Last Updated:** 2026-01-22
**Rebranding Version:** ElementX → ketal (v1.0)
