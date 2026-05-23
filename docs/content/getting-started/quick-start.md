---
title: Quick start
icon: fontawesome/solid/rocket
---

# <img src="../images/icon.png" width="20"> Quick Start

- Add an `OAuth2` node to your main scene or to an autoload/global scene.

- Set the **Browser Mode** in the inspector: `EXTERNAL` (default, system browser) or `IN_APP` (Chrome Custom Tab on Android / ASWebAuthenticationSession on iOS).

- Add a `Deeplink` node to your scene and configure your redirect URI.
  > **Note:** A `Deeplink` node is required in all cases **except** iOS with `IN_APP` mode, where the OS intercepts the redirect internally.

- Assign the `Deeplink` node path in the `OAuth2` node inspector.

- Configure provider settings (preset or custom).

- Connect to `OAuth2` signals.

- Call `authorize()` to start authentication. Call `cancel_auth()` to cancel an in-progress in-app session (safe no-op in `EXTERNAL` mode).

- Use the `OAuth2` node’s public methods to initiate authorization and manage sessions.

- Listen to signals to handle success, errors, and cancellations.

Example:

```gdscript
@onready var oauth2 := $OAuth2

func _ready():
	oauth2.auth_started.connect(_on_auth_started)
	oauth2.auth_success.connect(_on_auth_success)
	oauth2.auth_error.connect(_on_auth_error)
	oauth2.auth_cancelled.connect(_on_auth_cancelled)

func login():
	oauth2.authorize()

func cancel_login():
	oauth2.cancel_auth()  # safe to call in EXTERNAL mode (no-op)

func _on_auth_started():
	print("Authentication started")

func _on_auth_success(token_data: Dictionary):
	print("Authentication success:", token_data)

func _on_auth_error(msg: String):
	print("Authentication error:", msg)

func _on_auth_cancelled():
	print("Authentication cancelled")
```
