<p align="center">
	<img width="128" height="128" src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/demo/assets/oauth2-android.png">
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	<img width="128" height="128" src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/demo/assets/oauth2-ios.png">
</p>

<div align="center">
	<a href="https://github.com/godot-mobile-plugins/godot-oauth2"><img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-oauth2?label=Stars&style=plastic" height="32"/></a>
	<img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-oauth2?label=Latest%20Release&style=plastic" height="32"/>
	<img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-oauth2/latest/total?label=Downloads&style=plastic" height="32"/>
	<img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-oauth2/total?label=Total%20Downloads&style=plastic" height="32"/>
</div>

<br>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="24"> Godot OAuth 2.0 Plugin

A Godot plugin that provides a unified GDScript interface for OAuth 2.0 authentication flows on Android and iOS.

It supports popular OAuth providers via presets (Google, Apple, GitHub, Discord, Auth0) as well as fully custom OAuth2 providers, with built-in PKCE, deep link handling, and secure token storage through native platform integrations.

**Key Features**:

- Unified OAuth 2.0 API for Android and iOS
- Built-in provider presets (Google, Apple, GitHub, Discord, Auth0)
- Custom OAuth2 provider support
- PKCE (Proof Key for Code Exchange) support
- Deep link–based redirect handling
- Secure token storage via native platform plugins
- Session-based token management
- Editor-friendly configuration via exported properties

<a name="demo"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="20"> Demo

Try the **demo app** located in the `demo` directory.

<p align="center">
	<img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/docs/assets/demo_screenshot_ios_111.png" width="252">
</p>

<a name="installation"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="20"> Installation

> **Before installing:** uninstall any previous version of this plugin. If installing both Android and iOS versions in the same project, ensure both use the same addon interface version.

**Via AssetLib (recommended)**
1. Search for `OAuth` in the Godot Editor's AssetLib and click **Download**. (AssetLib Links: [Android](https://godotengine.org/asset-library/asset/4601), [iOS](https://godotengine.org/asset-library/asset/4602))
2. In the install dialog, keep the default install folder (project root) and **Ignore asset root** checked, then click **Install**.
3. Enable the plugin under **Project → Project Settings → Plugins**.

> If the installer warns about conflicting files when adding a second platform, you can safely ignore it — both platforms share the same addon code.

**Manually**
1. Download the release archive from [GitHub](https://github.com/godot-mobile-plugins/godot-oauth2/releases) and unzip it into your project's root directory.
2. Enable the plugin under **Project → Project Settings → Plugins**.

**Dependencies**

Depends on the [Deeplink Plugin](https://github.com/godot-mobile-plugins/godot-deeplink), which is required to receive OAuth redirect callbacks via custom URI schemes.

<a name="quick-start"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="20"> Quick Start

- Add an `OAuth2` node to your main scene or to an autoload/global scene.

- Add a `Deeplink` node to your scene and configure your redirect URI.

- Assign the `Deeplink` node path in the `OAuth2` node inspector.

- Configure provider settings (preset or custom).

- Connect to `OAuth2` signals.

- Call `authorize()` to start authentication.

- Use the `OAuth2` node’s public methods to initiate authorization and manage sessions.

- Listen to signals to handle success, errors, and cancellations.

Example:

```
@onready var oauth2 := $OAuth2

func _ready():
	oauth2.auth_started.connect(_on_auth_started)
	oauth2.auth_success.connect(_on_auth_success)
	oauth2.auth_error.connect(_on_auth_error)
	oauth2.auth_cancelled.connect(_on_auth_cancelled)

func login():
	oauth2.authorize()

func _on_auth_started():
	print("Authentication started")

func _on_auth_success(token_data: Dictionary):
	print("Authentication success:", token_data)

func _on_auth_error(msg: String):
	print("Authentication error:", msg)

func _on_auth_cancelled():
	print("Authentication cancelled")
```

<br>

<a name="documentation"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="24"> Documentation

Explore the plugin documentation for a deep dive into features:

- [https://godot-mobile-plugins.github.io/godot-oauth2](https://godot-mobile-plugins.github.io/godot-oauth2/)

<br>

<a name="all-plugins"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="24"> All Plugins

| ✦ | Plugin | Android | iOS | Latest Release | Downloads | Stars |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| <img src="https://raw.githubusercontent.com/godot-sdk-integrations/godot-admob/main/addon/src/icon.png" width="20"> | [Admob](https://github.com/godot-sdk-integrations/godot-admob) | ✅ | ✅ | <a href="https://github.com/godot-sdk-integrations/godot-admob/releases"><img src="https://img.shields.io/github/release-date/godot-sdk-integrations/godot-admob?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-sdk-integrations/godot-admob?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-sdk-integrations/godot-admob/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-sdk-integrations/godot-admob/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-sdk-integrations/godot-admob?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-connection-state/main/addon/src/icon.png" width="20"> | [Connection State](https://github.com/godot-mobile-plugins/godot-connection-state) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-connection-state/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-connection-state?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-connection-state?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-connection-state/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-connection-state/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-connection-state?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-deeplink/main/addon/src/icon.png" width="20"> | [Deeplink](https://github.com/godot-mobile-plugins/godot-deeplink) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-deeplink/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-deeplink?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-deeplink?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-deeplink/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-deeplink/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-deeplink?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/addon/src/icon.png" width="20"> | [Firebase](https://github.com/godot-mobile-plugins/godot-firebase) | ✅ | ✅ | - <!-- <a href="https://github.com/godot-mobile-plugins/godot-firebase/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-firebase?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-firebase?label=%20" /></a> --> | - <!-- <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-firebase/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-firebase/total?label=%20" /> --> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-firebase?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-inapp-review/main/addon/src/icon.png" width="20"> | [In-App Review](https://github.com/godot-mobile-plugins/godot-inapp-review) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-inapp-review/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-inapp-review?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-inapp-review?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-inapp-review/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-inapp-review/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-inapp-review?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="20"> | [Native Camera](https://github.com/godot-mobile-plugins/godot-native-camera) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-native-camera/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-native-camera?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-native-camera?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-native-camera/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-native-camera/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-native-camera?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="20"> | [Notification Scheduler](https://github.com/godot-mobile-plugins/godot-notification-scheduler) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-notification-scheduler/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-notification-scheduler?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-notification-scheduler?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-notification-scheduler/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-notification-scheduler/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-notification-scheduler?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="20"> | [OAuth 2.0](https://github.com/godot-mobile-plugins/godot-oauth2) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-oauth2/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-oauth2?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-oauth2?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-oauth2/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-oauth2/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-oauth2?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-qr/main/addon/src/icon.png" width="20"> | [QR](https://github.com/godot-mobile-plugins/godot-qr) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-qr/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-qr?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-qr?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-qr/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-qr/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-qr?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-share/main/addon/src/icon.png" width="20"> | [Share](https://github.com/godot-mobile-plugins/godot-share) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-share/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-share?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-share?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-share/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-share/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-share?style=plastic&label=%20" /> |

<br>

<a name="credits"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="24"> Credits

Developed by [Cengiz](https://github.com/cengiz-pz)

Based on [Godot Mobile Plugin Template v5](https://github.com/godot-mobile-plugins/godot-plugin-template/tree/v5)

Original repository: [Godot OAuth 2.0 Plugin](https://github.com/godot-mobile-plugins/godot-oauth2)

<br>

<a name="contributing"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="24"> Contributing

See [our guide](https://godot-mobile-plugins.github.io/godot-oauth2/contributing/) if you would like to contribute to this project.

<br>

# 💖 Support the Project

If this plugin has helped you, consider supporting its development! Every bit of support helps keep the plugin updated and bug-free.

| ✦ | Ways to Help | How to do it |
| :--- | :--- | :--- |
|✨⭐| **Spread the Word** | [Star this repo](https://github.com/godot-mobile-plugins/godot-oauth2/stargazers) to help others find it. |
|💡✨| **Give Feedback** | [Open an issue](https://github.com/godot-mobile-plugins/godot-oauth2/issues) or [suggest a feature](https://github.com/godot-mobile-plugins/godot-oauth2/issues/new). |
|🧩| **Contribute** | [Submit a PR](https://github.com/godot-mobile-plugins/godot-oauth2?tab=contributing-ov-file) to help improve the codebase. |
|❤️| **Buy a Coffee** | Support the maintainers on GitHub Sponsors or other platforms. |

## ⭐ Star History
[![Star History Chart](https://api.star-history.com/svg?repos=godot-mobile-plugins/godot-oauth2&type=Date)](https://star-history.com/#godot-mobile-plugins/godot-oauth2&Date)
