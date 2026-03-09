---
title: Configuration
icon: fontawesome/solid/sliders
---

# <img src="../images/icon.png" width="24"> Configuration

The build files are largely static and shared across all GMP plugins. Any plugin-specific build customization is handled through the following configuration files:

```text
.
├── addon/
│   └── ?.gradle.kts                   # Any extra Gradle configuration (configured in
│                                      # common/config/config.properties) for the plugin goes here
│
├── common/
│   ├── config/
│   │   └── config.properties          # Common plugin configuration
│   │
│   └── gradle/
│       └── libs.versions.toml         # Android dependencies and versions
│
└── ios/
	└── config/
		└── config.properties          # iOS configuration
```

## <img src="../images/icon.png" width="20"> Common Configuration

The `common/config/config.properties` file contains core plugin settings:

```properties
# Plugin identification
pluginNodeName=...                # Name of the plugin node in Godot
pluginModuleName=...              # Module name for native code
pluginVersion=1.0                 # Plugin version

# Godot configuration
godotVersion=4.6                  # Target Godot version
godotReleaseType=stable           # Release type: stable, dev6, beta3, rc1, etc.

# Extra properties configured in the following format
extra.anotherProperty=property value

# Extra gradle configuration files in the following format
gradle.another=another.gradle.kts
```

**Key Properties:**
- `pluginNodeName` - The name of the main plugin node used in Godot
- `pluginVersion` - Semantic version for releases
- `godotVersion` - Must match your target Godot version
- `godotReleaseType` - Determines which Godot binary to download

## <img src="../images/icon.png" width="20"> Gradle Configuration

The `common/gradle/libs.versions.toml` defines dependency versions:

```toml
[versions]
android-plugin = "8.5.0"
kotlin = "1.9.0"
...

[libraries]
...

[plugins]
android-library = { id = "com.android.library", version.ref = "android-plugin" }
kotlin-android = { id = "org.jetbrains.kotlin.android", version.ref = "kotlin" }
```

## <img src="../images/icon.png" width="20"> Android SDK Configuration

Create `common/local.properties` to specify your Android SDK location:

```properties
# Windows
sdk.dir=C\:\\Users\\YourUsername\\AppData\\Local\\Android\\Sdk

# macOS/Linux
sdk.dir=/Users/YourUsername/Library/Android/sdk

# Linux (alternate)
sdk.dir=/usr/lib/android-sdk
```
!!! note
    This file is gitignored and must be created locally.

## <img src="../images/icon.png" width="20"> iOS Configuration

The `ios/config/config.properties` file contains iOS-specific settings:

```properties
# iOS deployment target
platform_version=14.3

# iOS system framework dependencies
frameworks=Foundation.framework,...

# Embedded iOS external framework dependencies
embedded_frameworks=res://ios/framework/*.xcframework,...

# Linker flags
flags=-ObjC,-Wl,...

# Pod dependencies
dependencies=Dependency-SDK:1.0.0
```
