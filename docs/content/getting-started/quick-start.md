---
title: Quick start
icon: fontawesome/solid/rocket
---

# <img src="../images/icon.png" width="20"> Quick Start

- Add an `OAuth2` node to your main scene or to an autoload/global scene.

- Add a `Deeplink` node to your scene and configure your redirect URI.

- Assign the `Deeplink` node path in the `OAuth2` node inspector.

- Configure provider settings (preset or custom).

- Connect to `OAuth2` signals.

- Call `authorize()` to start authentication.

- Use the `OAuth2` node’s public methods to initiate authorization and manage sessions.

- Listen to signals to handle success, errors, and cancellations.

Example of  basic  setup 

```gdscript
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

There is also a [demo](https://github.com/godot-mobile-plugins/godot-oauth2/tree/main/demo) which can help you get started quickly.