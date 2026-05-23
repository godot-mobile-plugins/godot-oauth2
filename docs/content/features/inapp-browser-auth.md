---
title: In-App Browser Authentication
icon: fontawesome/solid/browser
---

# <img src="../images/icon.png" width="20"> In-App Browser Authentication

The plugin supports two browser modes, selectable via the `browser_mode` exported property on the `OAuth2` node.

| Mode | Value | Description |
| :--- | :--- | :--- |
| System Browser | `BrowserMode.EXTERNAL` | Opens the provider page in the default system browser. Requires a `Deeplink` node on both platforms. |
| In-App Browser | `BrowserMode.IN_APP` | Opens a sandboxed browser inside the app. See platform details below. |

## Android — Chrome Custom Tab

In `IN_APP` mode on Android, the plugin opens a **Chrome Custom Tab** (`androidx.browser`), presented as a full-screen overlay inside the app. The redirect URI travels through the Android intent system exactly as in `EXTERNAL` mode, so **a `Deeplink` node is still required**.

## iOS — ASWebAuthenticationSession

In `IN_APP` mode on iOS, the plugin uses **ASWebAuthenticationSession** (`AuthenticationServices`, iOS 12+). The OS intercepts the redirect URI internally via a completion block, so **no `Deeplink` node is needed** on iOS in this mode.

An additional property controls session privacy on iOS:

| Property | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `ios_ephemeral_browser_session` | `bool` | `false` | When `true`, opens the session in private-browsing mode — no cookies or credentials are shared with Safari. Set to `false` to enable SSO (users skip re-entering their password when already signed in to the provider in Safari). Has no effect on Android or in `EXTERNAL` mode. |

## Deeplink node requirements at a glance

| Platform | `EXTERNAL` mode | `IN_APP` mode |
| :--- | :---: | :---: |
| Android | Required | Required |
| iOS | Required | **Not required** |

## Cancelling an in-app session

Call `cancel_auth()` to dismiss an in-progress in-app browser session. This is safe to call in `EXTERNAL` mode as well — it is a no-op when no in-app session is active.

```
func _on_cancel_button_pressed():
	oauth2.cancel_auth()
```

## Signals emitted in IN_APP mode

In addition to `auth_success` and `auth_error`, the `auth_cancelled` signal is emitted when the user closes the in-app browser without completing authentication. This maps to the user tapping **Cancel** in the Chrome Custom Tab or dismissing the ASWebAuthenticationSession sheet.
