---
title: Auth0
icon: fontawesome/solid/fingerprint
---

# <img src="../images/icon.png" width="16"> Auth0

We can access the [Auth0 Console](https://manage.auth0.com/) to manage OAuth2 credentials for your project.

Follow these steps to configure your app:

- Create a new Application.
- Choose Native application type.
- Copy Client ID (Client Secret optional).
- Set Allowed Callback URLs.
- Configure your Auth0 domain (e.g. my-tenant.auth0.com).

## Notes

- Requires setting the Provider Domain in the plugin.
- Supports PKCE (enabled).

Default scopes: openid, profile, email, offline_access.