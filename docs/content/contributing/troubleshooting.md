---
title: Troubleshooting
icon: fontawesome/solid/wrench
---

# <img src="../images/icon.png" width="24"> Troubleshooting

## Android

**Problem:** Gradle version mismatch
```bash
# Solution: Use Gradle wrapper
cd common
./gradlew --version
./gradlew clean build
```

**Problem:** Dependency resolution failures
```bash
# Solution: Clear Gradle cache
rm -rf ~/.gradle/caches/
./gradlew clean build --refresh-dependencies
```

## iOS

**Problem:** CocoaPods installation fails
```bash
# Solution: Update CocoaPods
sudo gem install cocoapods
pod repo update
cd ios
pod install --repo-update
```

**Problem:** Header generation timeout
```bash
# Solution: Increase timeout
./script/build_ios.sh -H -t 120
```

**Problem:** Xcode build fails
```bash
# Solution: Clean derived data
rm -rf ios/build/DerivedData
./script/build_ios.sh -cb
```

**Problem:** "No such module" errors
```bash
# Solution: Ensure pods are installed
./script/build_ios.sh -pP
```

## Getting Help

- Check existing [GitHub Issues](https://github.com/godot-mobile-plugins/godot-oauth2/issues)
- Check exısting [GitHub Discussions](https://github.com/godot-mobile-plugins/godot-oauth2/discussions)
- Review [Godot documentation](https://docs.godotengine.org/)

