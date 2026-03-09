---
title: Methods
icon: fontawesome/solid/bolt
---

# <img src="../images/icon.png" width="20"> Methods

| Name | Description |
|---|---|
| `authorize() -> void` | Starts the OAuth 2.0 authorization flow. |
| `save_session(token_data: Dictionary, session_id: String) -> void` | Manually saves a session when automatic saving is not possible. |
| `get_stored_token() -> String`| Returns the access token for the first active session. |
| `get_stored_token_for(provider, session_id) -> String` | Retrieves a stored access token for a specific provider and session. |
| `clear_tokens() -> void` | Removes all stored tokens for the current provider. |
| `get_all_active_sessions() -> Array` | Returns all active sessions across all providers. |
| `get_active_sessions(provider) -> Array` | Returns active sessions for a specific provider. |
| `remove_all_active_sessions() -> void` | Clears all stored sessions. |
| `remove_active_sessions(provider) -> void` | Clears all sessions for a specific provider. |