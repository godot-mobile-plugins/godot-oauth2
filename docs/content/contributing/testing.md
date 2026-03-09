---
title: Testing
icon: fontawesome/solid/vial
---

# <img src="../images/icon.png" width="24"> Testing

## Testing in Demo App

1. **Install plugin to demo:**
   ```bash
   ./script/build.sh -D
   ```

2. **Open demo project:**
   ```bash
   cd demo
   godot project.godot
   ```

3. **Run and test features:**

## Android Testing

```bash
# Build and install
./script/build.sh -caD

# Export Android build from Godot
# Install on device/emulator
adb install demo/export/android/demo.apk

# View logs
adb logcat | grep -i OAuth2
```

## iOS Testing (macOS only)

```bash
# Build and install
./script/build.sh -I -D

# Open in Xcode
cd demo
open ios/demo.xcodeproj

# Build and run on simulator/device from Xcode
```

## Automated Testing

Consider adding:
- Unit tests for native code
- UI tests for demo app
- CI/CD pipeline (GitHub Actions)
