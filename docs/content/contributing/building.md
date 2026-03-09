---
title: Building
icon: fontawesome/solid/hammer
---

# <img src="../images/icon.png" width="24"> Building

## <img src="../images/icon.png" width="20"> Android Builds

### Quick Reference

```bash
# Clean and build debug
./script/build.sh -ca

# Clean and build release
./script/build.sh -car

# Create release archive
./script/build.sh -carz

# Build specific Gradle task
./script/run_gradle_task.sh buildDebug
./script/run_gradle_task.sh buildRelease
./script/run_gradle_task.sh createArchive
```

### Build Options

| Option | Description |
|--------|-------------|
| `-a` | Build plugin for Android platform |
| `-A` | Build and create Android release archive |
| `-c` | Remove existing Android build |
| `-r` | Use release build variant |
| `-z` | Create Android zip archive |

### Available Gradle Tasks

```bash
# Generate GDScript code only
./script/run_gradle_task.sh generateGDScript

# Copy assets
./script/run_gradle_task.sh copyAssets

# Build debug AAR
./script/run_gradle_task.sh buildDebug

# Build release AAR
./script/run_gradle_task.sh buildRelease

# Build both debug and release
./script/run_gradle_task.sh build

# Create release archive
./script/run_gradle_task.sh createArchive

# Install to demo app
./script/run_gradle_task.sh installToDemo

# Clean build
./script/run_gradle_task.sh clean
```

### Output Locations

- **GDScript code:** `addon/build/output/`
- **Debug AAR:** `android/build/outputs/aar/*-debug.aar`
- **Release AAR:** `android/build/outputs/aar/*-release.aar`
- **Built plugin:** `common/build/plugin/`
- **Release archive:** `common/build/archive/OAuth2Plugin-Android-v*.zip`


## <img src="../images/icon.png" width="20"> iOS Builds

### Quick Reference

```bash
# Full build (first time - downloads Godot)
./script/build_ios.sh -A

# Clean and rebuild (reuses Godot)
./script/build_ios.sh -ca

# Full clean rebuild (removes Godot)
./script/build_ios.sh -cgA

# Build and create archive
./script/build_ios.sh -cbz

# Custom timeout for header generation (seconds)
./script/build_ios.sh -H -t 60
```

### Build Options

| Option | Description |
|--------|-------------|
| `-a` | Generate headers, install pods, and build |
| `-A` | Download Godot + full build |
| `-b` | Build plugin only |
| `-c` | Clean existing build |
| `-g` | Remove Godot directory |
| `-G` | Download Godot |
| `-h` | Display help |
| `-H` | Generate Godot headers |
| `-p` | Remove pods and pod trunk |
| `-P` | Install CocoaPods |
| `-t <seconds>` | Set header generation timeout |
| `-z` | Create zip archive |

### Build Process Explained

The iOS build process involves several steps:

1. **Download Godot** (if needed):
   - Downloads the official Godot binary from GitHub
   - Version specified in `config.properties`
   - Extracted to `ios/godot/`

2. **Generate Headers**:
   - Starts a Godot build to generate C++ headers
   - Timeout prevents full Godot build (we only need headers)
   - Default timeout: 40 seconds (increase if needed)

3. **Install CocoaPods**:
   - Creates workspace for Xcode

4. **Build XCFrameworks**:
   - Builds for iOS device (arm64)
   - Builds for iOS simulator (arm64, x86_64)
   - Creates universal XCFrameworks for debug and release

### Output Locations

- **Godot source:** `ios/godot/`
- **Build artifacts:** `ios/build/`
- **Frameworks:** `ios/build/framework/`
- **Archives:** `ios/build/lib/*.xcarchive`
- **Release archive:** `ios/build/release/OAuth2Plugin-iOS-v*.zip`

### Common iOS Build Patterns

```bash
# Initial setup
./script/build_ios.sh -A

# Development cycle (reuses Godot and pods)
./script/build_ios.sh -cb

# Update dependencies
./script/build_ios.sh -pP

# Clean slate rebuild
./script/build_ios.sh -cgpA

# Create release with custom header timeout
./script/build_ios.sh -cH -t 60 -Pbz
```

## <img src="../images/icon.png" width="20"> Cross-Platform Builds

Use the main `build.sh` script for coordinated builds:

```bash
# Build Android, then iOS
./script/build.sh -cai -- -ca

# iOS build with options (passed after --)
./script/build.sh -i -- -cgA

# Clean everything
./script/build.sh -C

# Full release (creates all archives)
./script/build.sh -R
```
!!! note
 Options after `--` are passed to `build_ios.sh`
