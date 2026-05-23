//
// © 2025-present https://github.com/cengiz-pz
//

#ifndef oauth2_plugin_h
#define oauth2_plugin_h

#include "core/object/class_db.h"
#include "core/object/object.h"

/**
 * iOS plugin that provides:
 *
 *  1. Secure token storage via the iOS Keychain (kSecClassGenericPassword).
 *  2. In-app OAuth2 authorization via ASWebAuthenticationSession
 *     (AuthenticationServices, iOS 12+).
 *
 * The plugin is registered as an Engine singleton accessed through:
 *
 *   var plugin = Engine.get_singleton("@pluginName@")
 *
 * Signals
 * -------
 * auth_session_completed(callback_url: String)
 *     Emitted when ASWebAuthenticationSession delivers the redirect URI.
 *     The URL contains the authorization code and state as query parameters.
 *
 * auth_session_cancelled()
 *     Emitted when the user dismisses the in-app browser without completing
 *     authentication (ASWebAuthenticationSessionErrorCodeCanceledLogin).
 *
 * auth_session_error(error_message: String)
 *     Emitted when the session encounters an unrecoverable error other than
 *     user cancellation.
 */
class OAuth2Plugin : public Object {
	GDCLASS(OAuth2Plugin, Object);

	static OAuth2Plugin *instance;

protected:
	static void _bind_methods();

public:
	// -- Keychain / token storage ------------------------------------------

	PackedStringArray get_all_keys();
	void save_token(String key, String value);
	String get_token(String key);
	void delete_token(String key);

	// -- In-app browser (ASWebAuthenticationSession) -----------------------

	/**
	 * Opens an ASWebAuthenticationSession for the given authorization URL.
	 *
	 * @param url             Fully-assembled authorization URL.
	 * @param callback_scheme URI scheme registered for the app's redirect URI
	 *                        (e.g. "mygame" for "mygame://auth/callback").
	 * @param ephemeral       When true, the session does not share cookies or
	 *                        credential data with Safari (private mode).
	 *                        When false, existing Safari sessions are reused
	 *                        for single-sign-on.
	 */
	void start_auth_session(String url, String callback_scheme, bool ephemeral);

	/**
	 * Programmatically cancels the in-progress ASWebAuthenticationSession.
	 * The session object is released and auth_session_cancelled is NOT emitted
	 * (since the cancellation was initiated by the app, not the user).
	 * Call auth_cancelled.emit() in GDScript after invoking this if you wish
	 * to notify the rest of the game.
	 */
	void cancel_auth_session();

	// -- Singleton access --------------------------------------------------

	static OAuth2Plugin *get_singleton();

	OAuth2Plugin();
	~OAuth2Plugin();

private:
	void cleanup_expired_tokens();
};

#endif /* oauth2_plugin_h */
