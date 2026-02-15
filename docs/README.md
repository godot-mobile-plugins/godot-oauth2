<p align="center">
	<img width="256" height="256" src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/demo/assets/oauth2-android.png">
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	<img width="256" height="256" src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/demo/assets/oauth2-ios.png">
</p>

---

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

---

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="20"> Table of Contents

- [Demo](#demo)
- [Installation](#installation)
- [Dependencies](#dependencies)
- [Usage](#usage)
- [Signals](#signals)
- [Methods](#methods)
- [Classes](#classes)
- [Providers](#providers)
- [Platform-Specific Notes](#platform-specific-notes)
- [Links](#links)
- [All Plugins](#all-plugins)
- [Credits](#credits)
- [Contributing](#contributing)

---

<a name="demo"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="20"> Demo

Try the **demo app** located in the `demo` directory.

<p align="center">
	<img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/docs/assets/demo_screenshot_ios_111.gif" width="252">
</p>

---

<a name="installation"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="20"> Installation

Before installing this plugin, make sure to uninstall any previous versions of the same plugin.

_If installing both Android and iOS versions of the plugin in the same project, then make sure that both versions use the same addon interface version._

There are 2 ways to install the OAuth2 plugin into your project:

- Through the Godot Editor's AssetLib
- Manually by downloading archives from GitHub

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="18"> Installing via AssetLib

Steps:

- Search for and select the OAuth2 plugin in the Godot Editor

- Click the Download button

On the installation dialog:

- Keep Change Install Folder pointing to your project root

- Keep Ignore asset root checked

- Click Install

- Enable the plugin via `Project --> Project Settings… --> Plugins`

- _For iOS, also enable the plugin in the export settings._

#### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="16"> Installing both Android and iOS versions

When installing via AssetLib, the installer may warn that some files conflict.
This is expected and can be safely ignored, as both versions share the same addon code.

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="18"> Installing manually

Steps:

- Download the release archive from GitHub

- Unzip the archive

- Copy the contents into your Godot project root

- Enable the plugin via `Project --> Project Settings… --> Plugins`

- _For iOS, also enable the plugin in the export settings._

---

<a name="dependencies"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="20"> Dependencies

**`Deeplink Plugin` version `5.3`**

The [Deeplink Plugin](https://github.com/godot-mobile-plugins/godot-deeplink) is required to receive OAuth redirect callbacks via custom URI schemes.

---

<a name="usage"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="20"> Usage

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

---

<a name="signals"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="20"> Signals

Register listeners to the following signals of the OAuth2 node:

- `auth_started`
Emitted when the authentication flow begins.

- `auth_success(token_data: Dictionary)`
Emitted when authentication completes successfully.

- `auth_error(error_msg: String)`
Emitted when an authentication or token exchange error occurs.

- `auth_cancelled`
Emitted when the user cancels the authentication flow.

---

<a name="methods"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="20"> Methods

- `authorize() -> void`
Starts the OAuth 2.0 authorization flow.

- `save_session(token_data: Dictionary, session_id: String) -> void`
Manually saves a session when automatic saving is not possible.

- `get_stored_token() -> String`
Returns the access token for the first active session.

- `get_stored_token_for(provider, session_id) -> String`
Retrieves a stored access token for a specific provider and session.

- `clear_tokens() -> void`
Removes all stored tokens for the current provider.

- `get_all_active_sessions() -> Array`
Returns all active sessions across all providers.

- `get_active_sessions(provider) -> Array`
Returns active sessions for a specific provider.

- `remove_all_active_sessions() -> void`
Clears all stored sessions.

- `remove_active_sessions(provider) -> void`
Clears all sessions for a specific provider.

---

<a name="classes"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="20"> Classes

This section documents the GDScript interface classes implemented and exposed by the plugin.

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="16"> OAuth2

Main node that manages OAuth authorization flows, token exchange, and session storage.

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="16"> OAuth2Config

Provides provider presets and configuration helpers for OAuth2 providers.

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="16"> ProviderConfig

Encapsulates configuration for OAuth2 providers.

---

<a name="providers"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="20"> Providers

The plugin includes built-in presets for common OAuth 2.0 providers as well as a fully Custom provider option.
Each provider requires creating an OAuth2 client in the provider’s developer console and configuring redirect URIs correctly.

**Important**:
Redirect URIs must exactly match what is configured in the provider dashboard, including scheme, host, path, and trailing slashes.

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="16"> Google

Console:
https://console.cloud.google.com/apis/credentials

Steps:

- Create or select a Google Cloud project.
- Go to APIs & Services --> Credentials.
- Create an OAuth Client ID.
- Choose Android, iOS, or Web depending on your setup.
- Copy the Client ID (Client Secret is optional and usually not required for mobile).
- Add your redirect URI (custom scheme or HTTPS).

Notes:

- Supports PKCE (enabled by default).
- Offline access and refresh tokens are supported.

Default scopes: openid, profile, email.

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="16"> Apple

Console:
https://developer.apple.com/account/resources/identifiers/list

Steps:

- Create an App ID and enable Sign in with Apple.
- Create a Service ID for OAuth.
- Configure Return URLs.
- Generate a Client ID (Service ID identifier).
- (Optional) Generate a Client Secret using a private key.

**Important Apple Limitation**:

- Apple does NOT support custom URI schemes (e.g. mygame://callback).
- Redirect URIs must be HTTPS.
- The domain must be verified with Apple.
- This usually requires a backend relay that redirects back into the app.

Notes:

- PKCE is disabled for Apple.
- Apple often returns data via form_post.

Requires additional backend setup for most mobile games.

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="16"> Discord

Console:
https://discord.com/developers/applications

Steps:

- Create a new application.
- Open OAuth2 --> General.
- Copy the Client ID.
- (Optional) Copy the Client Secret.
- Add your redirect URI.

Notes:

- Supports custom URI schemes.
- PKCE is enabled.

Default scopes: identify, email.

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="16"> GitHub

Console:
https://github.com/settings/developers

Steps:

- Create a New OAuth App.
- Set application name and homepage URL.
- Set Authorization callback URL (redirect URI).
- Copy Client ID and Client Secret.

Notes:

- PKCE is optional (disabled by default).
- Custom URI schemes are supported.

Default scopes: read:user, user:email.

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="16"> Auth0

Console:
https://manage.auth0.com/

Steps:

- Create a new Application.
- Choose Native application type.
- Copy Client ID (Client Secret optional).
- Set Allowed Callback URLs.
- Configure your Auth0 domain (e.g. my-tenant.auth0.com).

Notes:

- Requires setting the Provider Domain in the plugin.
- Supports PKCE (enabled).

Default scopes: openid, profile, email, offline_access.

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="16"> Custom

Use this option for any OAuth 2.0 compliant provider not listed above.

You must manually provide:

- Authorization endpoint
- Token endpoint
- Scopes
- Optional PKCE setting
- Optional extra parameters

Steps:

- Create an OAuth2 client in your provider’s dashboard.
- Copy Client ID (and Client Secret if required).
- Register your redirect URI.
- Enter endpoints and scopes in the plugin inspector.

Notes:

- PKCE is strongly recommended for public clients.
- Some providers require additional parameters (audience, resource, etc.).

---

<a name="platform-specific-notes"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="20"> Platform-Specific Notes
### Android

Download Android export templates

Enable Gradle Build in export settings

Ensure your redirect URI scheme is registered correctly

**Troubleshooting**:

- Logs:
`adb logcat | grep 'godot'` (Linux/macOS)
`adb.exe logcat | select-string "godot"` (Windows)

Useful resources:

- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
- https://developer.android.com/tools/adb
- https://developer.android.com/studio/debug
- https://developer.android.com/courses

### iOS
Follow Exporting for iOS

View Xcode logs while running the app

Ensure URL schemes are correctly registered

See Godot iOS Export Troubleshooting

<a name="links"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="24"> Links

- [AssetLib Entry Android](https://godotengine.org/asset-library/asset/4601)
- [AssetLib Entry iOS](https://godotengine.org/asset-library/asset/4602)

---

<a name="all-plugins"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="24"> All Plugins

| Plugin | Android | iOS | Free | Open Source | License |
| :--- | :---: | :---: | :---: | :---: | :---: |
| [Admob](https://github.com/godot-sdk-integrations/godot-admob) | ✅ | ✅ | ✅ | ✅ | MIT |
| [Notification Scheduler](https://github.com/godot-mobile-plugins/godot-notification-scheduler) | ✅ | ✅ | ✅ | ✅ | MIT |
| [Deeplink](https://github.com/godot-mobile-plugins/godot-deeplink) | ✅ | ✅ | ✅ | ✅ | MIT |
| [Share](https://github.com/godot-mobile-plugins/godot-share) | ✅ | ✅ | ✅ | ✅ | MIT |
| [In-App Review](https://github.com/godot-mobile-plugins/godot-inapp-review) | ✅ | ✅ | ✅ | ✅ | MIT |
| [Native Camera](https://github.com/godot-mobile-plugins/godot-native-camera) | ✅ | ✅ | ✅ | ✅ | MIT |
| [Connection State](https://github.com/godot-mobile-plugins/godot-connection-state) | ✅ | ✅ | ✅ | ✅ | MIT |
| [OAuth 2.0](https://github.com/godot-mobile-plugins/godot-oauth2) | ✅ | ✅ | ✅ | ✅ | MIT |
| [QR](https://github.com/godot-mobile-plugins/godot-qr) | ✅ | ✅ | ✅ | ✅ | MIT |
| [Firebase](https://github.com/godot-mobile-plugins/godot-firebase) | ✅ | ✅ | ✅ | ✅ | MIT |

---

<a name="credits"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="24"> Credits

Developed by [Cengiz](https://github.com/cengiz-pz)

Based on [Godot Mobile Plugin Template](https://github.com/godot-mobile-plugins/godot-plugin-template)

Original repository: [Godot OAuth 2.0 Plugin](https://github.com/godot-mobile-plugins/godot-oauth2)

---

<a name="contributing"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="24"> Contributing

See [the contribution guide](https://github.com/godot-mobile-plugins/godot-oauth2?tab=contributing-ov-file) if you would like to contribute to this project.
