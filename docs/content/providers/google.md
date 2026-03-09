---
title: Google
icon: fontawesome/brands/google
---

# <img src="../images/icon.png" width="16"> Google

We can access the [Google Cloud Console](https://console.cloud.google.com/apis/credentials) 

Follow these steps to configure your app:

- Create or select a Google Cloud project.
- Go to APIs & Services --> Credentials.
- Create an OAuth Client ID.
- Choose Android, iOS, or Web depending on your setup.
- Copy the Client ID (Client Secret is optional and usually not required for mobile).
- Add your redirect URI (custom scheme or HTTPS).

## Notes

- Supports PKCE (enabled by default).
- Offline access and refresh tokens are supported.

Default scopes: openid, profile, email.
