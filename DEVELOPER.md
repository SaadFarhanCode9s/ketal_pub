# Ketal Developer Documentation

## Overview
Ketal is a fork of Element X iOS, a next-generation Matrix client built using the Matrix Rust SDK.

## Setting up a development environment

### Prerequisites
- macOS 14.5+
- Xcode 15.0.1+
- [Homebrew](https://brew.sh/)
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (installed via setup script)

### Setup Project
Run the following command after cloning the repository:

```bash
swift run tools setup-project
```

This command will:
- Install required brew dependencies.
- Configure git hooks.
- Generate the Xcode project (`ketal.xcodeproj`) using `xcodegen`.

### Building
Open `ketal.xcodeproj` and build the `ketal` scheme.
Note: The project uses Swift Package Manager for dependencies. If package resolution fails, try `File -> Packages -> Reset Package Caches`.

### Compiling the Rust SDK (Optional)
To build the Rust SDK locally:
```bash
swift run tools build-sdk
```

## Project Structure
- `ketal/`: Main application source code.
- `ketal/Sources`: Swift sources.
- `ketal/Resources`: Assets and strings.
- `UnitTests/`: Unit tests.
- `UITests/`: UI tests.
- `project.yml`: XcodeGen configuration file.

## Contributing
- Please ensure all new code follows the existing style guidelines.
- Run `swift run tools setup-project` to ensure hooks are installed.
- We use SwiftLint and SwiftFormat.

## Syncing with Upstream
Use the provided script to sync with the upstream `element-x-ios` repository:
```bash
./scripts/sync_upstream.sh
```
