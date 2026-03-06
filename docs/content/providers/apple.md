---
title: Apple
icon: fontawesome/brands/apple
---

# <img src="../images/icon.png" width="16"> Apple

We can access the [Apple Developer Console](https://developer.apple.com/account/resources/identifiers/list) 

Follow these steps to configure your app:

- Create an App ID and enable Sign in with Apple.
- Create a Service ID for OAuth.
- Configure Return URLs.
- Generate a Client ID (Service ID identifier).
- (Optional) Generate a Client Secret using a private key.

## Important Apple Limitation:

- Apple does NOT support custom URI schemes (e.g. mygame://callback).
- Redirect URIs must be HTTPS.
- The domain must be verified with Apple.
- This usually requires a backend relay that redirects back into the app.

## Notes

- PKCE is disabled for Apple.
- Apple often returns data via form_post.

Requires additional backend setup for most mobile games.