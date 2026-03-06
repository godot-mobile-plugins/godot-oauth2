---
title: Custom
icon: fontawesome/solid/plug
---

# <img src="../images/icon.png" width="16"> Custom

Use this option for any OAuth 2.0 compliant provider not listed above.

## Requirements

You must manually provide:

- Authorization endpoint
- Token endpoint
- Scopes
- Optional PKCE setting
- Optional extra parameters

Follow these steps to configure your app:

- Create an OAuth2 client in your provider’s dashboard.
- Copy Client ID (and Client Secret if required).
- Register your redirect URI.
- Enter endpoints and scopes in the plugin inspector.

## Notes

- PKCE is strongly recommended for public clients.
- Some providers require additional parameters (audience, resource, etc.).
