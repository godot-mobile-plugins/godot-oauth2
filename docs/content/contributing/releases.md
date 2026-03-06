---
title: Releases
icon: fontawesome/solid/tag
---

## <img src="../images/icon.png" width="24"> Creating Releases

## Full Multi-Platform Release

```bash
# Create all release archives
./script/build.sh -R
```

This creates:
- `release/OAuth2Plugin-Android-v*.zip`
- `release/OAuth2Plugin-iOS-v*.zip`
- `release/OAuth2Plugin-Multi-v*.zip` (combined)

## Platform-Specific Releases

```bash
# Android only
./script/build.sh -A

# iOS only (assumes Godot already downloaded)
./script/build.sh -I

# Multi-platform (combines existing archives)
./script/build.sh -Z
```

## Release Checklist

- [ ] Update version in `common/config/config.properties`
- [ ] Update versions in issue templates (`.github/ISSUE_TEMPLATE`)
- [ ] Test on both platforms
- [ ] Build release archives
- [ ] Create GitHub release
- [ ] Upload archives to release & publish
- [ ] Close GitHub milestone
- [ ] Post GitHub announcement
- [ ] Update Asset Library listing
- [ ] Update Asset Store listing
