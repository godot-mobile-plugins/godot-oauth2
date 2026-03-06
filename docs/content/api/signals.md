---
title: signals
icon: fontawesome/solid/signal
---

# <img src="../images/icon.png" width="20"> Signals

Register listeners for one or more signals of the `OAuth2` node.

| Name | Description |
|---|---|
| `auth_started`| Emitted when the authentication flow begins. |
| `auth_success(token_data: Dictionary)` | Emitted when authentication completes successfully. |
|  `auth_error(error_msg: String)` | Emitted when an authentication or token exchange error occurs. |
| `auth_cancelled` | Emitted when the user cancels the authentication flow.