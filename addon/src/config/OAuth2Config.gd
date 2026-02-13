#
# © 2025-present https://github.com/cengiz-pz
#

class_name OAuth2Config extends RefCounted

enum Provider {
	CUSTOM, ## Custom provider configuration
	GOOGLE, ## Provider configuration presets for Google
	APPLE, ## Provider configuration presets for Apple
	DISCORD, ## Provider configuration presets for Discord
	GITHUB, ## Provider configuration presets for GitHub
	AUTH0 ## Provider configuration presets for Auth0
}

const PROVIDER_PRESETS = {
	Provider.GOOGLE: {
		ProviderConfig.AUTH_ENDPOINT_PROPERTY: "https://accounts.google.com/o/oauth2/v2/auth",
		ProviderConfig.TOKEN_ENDPOINT_PROPERTY: "https://oauth2.googleapis.com/token",
		ProviderConfig.SCOPES_PROPERTY: ["openid", "profile", "email"],
		ProviderConfig.PKCE_ENABLED_PROPERTY: true,
		ProviderConfig.PARAMS_PROPERTY: { "access_type": "offline", "prompt": "consent" }
	},
	Provider.APPLE: {
		ProviderConfig.AUTH_ENDPOINT_PROPERTY: "https://appleid.apple.com/auth/authorize",
		ProviderConfig.TOKEN_ENDPOINT_PROPERTY: "https://appleid.apple.com/auth/token",
		ProviderConfig.SCOPES_PROPERTY: ["name", "email"],
		ProviderConfig.PKCE_ENABLED_PROPERTY: false, # Apple uses 'nonce' and 'state', usually handled via params
		ProviderConfig.PARAMS_PROPERTY: { 
			"response_mode": "form_post", # Apple defaults to form_post; requires a backend relay to redirect to app scheme
			"response_type": "code" 
		}
	},
	Provider.DISCORD: {
		ProviderConfig.AUTH_ENDPOINT_PROPERTY: "https://discord.com/api/oauth2/authorize",
		ProviderConfig.TOKEN_ENDPOINT_PROPERTY: "https://discord.com/api/oauth2/token",
		ProviderConfig.SCOPES_PROPERTY: ["identify", "email"],
		ProviderConfig.PKCE_ENABLED_PROPERTY: true,
		ProviderConfig.PARAMS_PROPERTY: {}
	},
	Provider.GITHUB: {
		ProviderConfig.AUTH_ENDPOINT_PROPERTY: "https://github.com/login/oauth/authorize",
		ProviderConfig.TOKEN_ENDPOINT_PROPERTY: "https://github.com/login/oauth/access_token",
		ProviderConfig.SCOPES_PROPERTY: ["read:user", "user:email"],
		ProviderConfig.PKCE_ENABLED_PROPERTY: false, # GitHub doesn't strictly enforce PKCE but supports state
		ProviderConfig.PARAMS_PROPERTY: {}
	},
	Provider.AUTH0: {# Domain must be set for AUTH0
		ProviderConfig.AUTH_ENDPOINT_PROPERTY: "https://%s/authorize",
		ProviderConfig.TOKEN_ENDPOINT_PROPERTY: "https://%s/oauth/token",
		ProviderConfig.SCOPES_PROPERTY: ["openid", "profile", "email", "offline_access"],
		ProviderConfig.PKCE_ENABLED_PROPERTY: true,
		ProviderConfig.PARAMS_PROPERTY: {}
	}
}

static func get_config(provider: int) -> ProviderConfig:
	return ProviderConfig.new(PROVIDER_PRESETS.get(provider, {}).duplicate(true))
