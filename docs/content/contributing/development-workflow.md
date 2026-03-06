---
title: Development workflow
icon: fontawesome/solid/diagram-project
---

## <img src="../images/icon.png" width="24"> Development Workflow

## Initial Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/godot-mobile-plugins/godot-oauth2.git
   cd godot-oauth2
   ```

2. **Configure Android SDK:**
   ```bash
   echo "sdk.dir=/path/to/your/android-sdk" > common/local.properties
   ```

3. **First build (downloads Godot automatically):**
   ```bash
   # Android only
   ./script/build.sh -ca

   # iOS only (macOS)
   ./script/build.sh -i -- -A

   # Both platforms
   ./script/build.sh -ca -i -- -A
   ```

## Making Changes

1. **Edit source code:**
   - Android: `android/src/main/`
   - iOS: `ios/src/`
   - GDScript templates: `addon/src/`

2. **Build and test:**
   ```bash
   # Quick Android build
   ./script/build.sh -a

   # Install to demo app
   ./script/build.sh -D

   # Run demo in Godot to test
   cd demo
   godot project.godot
   ```

3. **Iterate:**
   - Make changes
   - Rebuild with `./script/build.sh -a`
   - Test in demo app
   - Repeat until satisfied
