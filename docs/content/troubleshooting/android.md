---
title: Android troubleshooting
icon: fontawesome/brands/android
---

# <img src="../images/icon.png" width="20"> Troubleshooting for Android

- Download Android export templates

- Enable Gradle Build in export settings

- Ensure your redirect URI scheme is registered correctly

## Troubleshooting

To help diagnose issues with the plugin, you can check the logs from your device.

- **Linux/macOS:**  
```bash
    adb logcat | grep 'godot'
```

- **Windows:**  
```powershell
    adb.exe logcat | select-string "godot"
```

## Useful resources

- [Godot: Exporting for Android](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)  
- [Android Debug Bridge (ADB) Documentation](https://developer.android.com/tools/adb)  
- [Android Studio Debugging Tools](https://developer.android.com/studio/debug)  
- [Android Developer Courses](https://developer.android.com/courses)  