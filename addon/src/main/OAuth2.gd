#
# © 2025-present https://github.com/cengiz-pz
#

@tool
@icon("icon.png")
class_name OAuth2 extends Node

## Emitted when the authorization flow is initiated and the browser is opening.
signal auth_started

## Emitted when the full authorization + token-exchange flow completes
## successfully. [param token_data] contains the provider's token response
## (access_token, refresh_token, expires_in, id_token, etc.).
signal auth_success(token_data: Dictionary)

## Emitted when any step of the flow fails. [param error_msg] is a
## human-readable description of the failure.
signal auth_error(error_msg: String)

## Emitted when the user closes the browser without completing authentication.
signal auth_cancelled

const PLUGIN_SINGLETON_NAME: String = "@pluginName@"

# -- Browser mode --------------------------------------------------------------

enum BrowserMode {
	## Opens the provider authorization page in the system browser.
	## Requires a Deeplink node on both platforms to receive the redirect URI.
	EXTERNAL,
	## Opens a secure, sandboxed in-app browser tab.
	##
	## Android — Chrome Custom Tab (androidx.browser).
	##   Presented as a full-screen overlay inside the app.
	##   A Deeplink node is still required because Android routes the
	##   redirect URI through the intent system.
	##
	## iOS — ASWebAuthenticationSession (AuthenticationServices, iOS 12+).
	##   The OS intercepts the redirect URI internally via a completion block.
	##   No Deeplink node is required on iOS in this mode.
	##
	## The developer API is identical for both platforms in either mode;
	## all routing differences are handled internally.
	IN_APP,
}

# -- Provider Configuration ----------------------------------------------------

@export_category("Provider Configuration")

@export var provider: OAuth2Config.Provider = OAuth2Config.Provider.GOOGLE:
	set = _set_provider

@export_group("Settings", "provider_")

@export var provider_auth_endpoint: String = ""
@export var provider_token_endpoint: String = ""

@export var provider_domain: String = "":
	set = _set_provider_domain

@export var provider_scopes: PackedStringArray = []
@export var provider_pkce_enabled: bool = true
@export var provider_parameters: Dictionary = {}

# -- Browser Mode --------------------------------------------------------------

@export_category("Browser Mode")

## Controls how the OAuth2 authorization page is presented to the user.
## Platform differences are handled internally; the developer API is the same
## regardless of which mode or platform is active.
@export var browser_mode: BrowserMode = BrowserMode.EXTERNAL:
	set(value):
		browser_mode = value
		notify_property_list_changed()

## When true, the iOS in-app browser session is ephemeral (private-browsing
## mode): no cookies or credentials are shared with Safari.
## Set to false to allow SSO — users skip re-entering their password when
## already signed in to the provider in Safari.
## Has no effect on Android or when [member browser_mode] is EXTERNAL.
@export var ios_ephemeral_browser_session: bool = false

# -- Client Configuration ------------------------------------------------------

@export_category("Client Configuration")

@export_group("Android", "android_")

@export var android_client_id: String = ""
@export var android_client_secret: String = ""
@export var android_redirect_uri: String = "mygame://auth/callback"

## Required for EXTERNAL mode and for IN_APP mode (Chrome Custom Tab).
## Not required on iOS when browser_mode is IN_APP.
@export_node_path("Deeplink") var android_deeplink_path: NodePath

@export_group("iOS", "ios_")

@export var ios_client_id: String = ""
@export var ios_client_secret: String = ""
@export var ios_redirect_uri: String = "mygame://auth/callback"

## Required only when browser_mode is EXTERNAL on iOS.
## Not required when browser_mode is IN_APP on iOS.
@export_node_path("Deeplink") var ios_deeplink_path: NodePath

# -- Internal state ------------------------------------------------------------

var auth_endpoint_format: String = ""
var token_endpoint_format: String = ""

var _client_id: String = ""
var _client_secret: String = ""
var _redirect_uri: String = ""
var _deeplink_path: NodePath

var _deeplink_node: Deeplink
var _http_request: HTTPRequest
var _state: String
var _code_verifier: String
var _plugin_singleton: Object

var _using_in_app_browser: bool = false

# ═════════════════════════════════════════════════════════════════════════════
# Lifecycle – fully automatic, no developer action required
# ═════════════════════════════════════════════════════════════════════════════


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# Select the correct credential set for the current platform.
	# This is the only place platform identity matters; it never surfaces
	# in developer code.
	if OS.has_feature("ios"):
		_client_id = ios_client_id
		_client_secret = ios_client_secret
		_redirect_uri = ios_redirect_uri
		_deeplink_path = ios_deeplink_path
	else:
		_client_id = android_client_id
		_client_secret = android_client_secret
		_redirect_uri = android_redirect_uri
		_deeplink_path = android_deeplink_path

	_using_in_app_browser = (browser_mode == BrowserMode.IN_APP)

	# On iOS + IN_APP, ASWebAuthenticationSession delivers the callback
	# internally via a completion block, so no Deeplink node is needed.
	# On every other combination a Deeplink node is required.
	var needs_deeplink := not (_using_in_app_browser and OS.has_feature("ios"))

	if needs_deeplink:
		if _deeplink_path:
			_deeplink_node = get_node(_deeplink_path)
		if _deeplink_node:
			_wire_deeplink(_deeplink_node)
		else:
			GmpLogger.log_warn("Deeplink node not found — redirect callbacks will not be received.")
	# iOS + IN_APP falls through here with no deeplink node.

	_setup_http()
	_setup_native_plugin()


## Advanced / edge-case override.  Under normal usage the node configures
## itself automatically from inspector properties in _ready().
## Only call this when you need to supply a Deeplink node that was not
## available at scene load time.
func initialize(a_deeplink_node: Deeplink) -> void:
	_wire_deeplink(a_deeplink_node)
	if not _http_request:
		_setup_http()
	if not _plugin_singleton:
		_setup_native_plugin()


# ═════════════════════════════════════════════════════════════════════════════
# Internal setup – invisible to developers
# ═════════════════════════════════════════════════════════════════════════════


func _wire_deeplink(node: Deeplink) -> void:
	_deeplink_node = node
	if not _deeplink_node.deeplink_received.is_connected(_on_deeplink_received):
		_deeplink_node.deeplink_received.connect(_on_deeplink_received)


func _setup_http() -> void:
	if _http_request:
		return
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_token_request_completed)


func _setup_native_plugin() -> void:
	if not Engine.has_singleton(PLUGIN_SINGLETON_NAME):
		GmpLogger.log_warn("Native plugin '%s' not found — secure storage is unavailable." % PLUGIN_SINGLETON_NAME)
		return

	_plugin_singleton = Engine.get_singleton(PLUGIN_SINGLETON_NAME)

	# Connect native in-app browser signals.  Guards with has_signal() keep
	# the node functional against older plugin binaries that pre-date in-app
	# browser support.
	_try_connect_signal("auth_session_completed", _on_auth_session_completed)
	_try_connect_signal("auth_session_cancelled", _on_auth_session_cancelled)
	_try_connect_signal("auth_session_error", _on_auth_session_error)


func _try_connect_signal(sig: String, callable: Callable) -> void:
	if _plugin_singleton.has_signal(sig) and not _plugin_singleton.is_connected(sig, callable):
		_plugin_singleton.connect(sig, callable)


# ═════════════════════════════════════════════════════════════════════════════
# Public API — identical across all platforms and browser modes
# ═════════════════════════════════════════════════════════════════════════════


## Starts the OAuth2 authorization flow.
## The correct browser (system browser, Chrome Custom Tab, or
## ASWebAuthenticationSession) is chosen automatically based on the
## [member browser_mode] setting and the current platform.
func authorize() -> void:
	var config: ProviderConfig = _get_current_config()
	if config.get_auth_endpoint().is_empty() or _client_id.is_empty():
		auth_error.emit("Configuration Invalid: Missing endpoint or client_id")
		return

	auth_started.emit()

	_state = OAuth2PKCE.generate_verifier().left(32)
	var params := config.get_params()

	params["client_id"] = _client_id
	params["redirect_uri"] = _redirect_uri
	params["response_type"] = "code"
	params["state"] = _state
	params["scope"] = " ".join(config.get_scopes())

	if config.is_pkce_enabled():
		_code_verifier = OAuth2PKCE.generate_verifier()
		params["code_challenge"] = OAuth2PKCE.generate_challenge(_code_verifier)
		params["code_challenge_method"] = "S256"

	var query_parts: Array = []
	for key in params:
		query_parts.append("%s=%s" % [key.uri_encode(), str(params[key]).uri_encode()])

	var auth_url := config.get_auth_endpoint() + "?" + "&".join(query_parts)

	# Internal dispatch — developer never sees this branch.
	if _using_in_app_browser and _plugin_singleton:
		_dispatch_in_app(auth_url)
	else:
		OS.shell_open(auth_url)


## Cancels an in-progress in-app browser session.
## Safe to call in EXTERNAL mode (no-op) so callers need no mode check.
func cancel_auth() -> void:
	_state = ""
	if _using_in_app_browser and _plugin_singleton and _plugin_singleton.has_method("cancel_auth_session"):
		_plugin_singleton.cancel_auth_session()


## Manually persists a session when the provider does not return an id_token
## (e.g. GitHub) or when a custom session identifier is preferred.
func save_session(token_data: Dictionary, session_id: String) -> void:
	_save_tokens_for_session(token_data, session_id)


## Returns the access token for the first active session found for the
## configured provider, or an empty string when no session exists.
func get_stored_token() -> String:
	var sessions := get_active_sessions(provider)
	if sessions.size() > 0:
		return get_stored_token_for(provider, sessions[0]["session_id"])
	return ""


## Returns the access token for a specific provider and session ID.
func get_stored_token_for(p_provider: OAuth2Config.Provider, s_id: String) -> String:
	if _plugin_singleton:
		var prefix := "session:%s:%s:" % [OAuth2Config.Provider.keys()[p_provider], s_id]
		return _plugin_singleton.get_token(prefix + "access_token")
	return ""


## Removes all stored tokens for the configured provider.
func clear_tokens() -> void:
	remove_active_sessions(provider)


# -- Session queries -----------------------------------------------------------


func get_all_active_sessions() -> Array:
	return _filter_sessions("")


func get_active_sessions(p_provider: OAuth2Config.Provider) -> Array:
	return _filter_sessions(OAuth2Config.Provider.keys()[p_provider])


func remove_all_active_sessions() -> void:
	_clear_by_prefix("session:")


func remove_active_sessions(p_provider: OAuth2Config.Provider) -> void:
	_clear_by_prefix("session:%s:" % OAuth2Config.Provider.keys()[p_provider])


# ═════════════════════════════════════════════════════════════════════════════
# Internal — browser dispatch (developer never calls these)
# ═════════════════════════════════════════════════════════════════════════════


func _dispatch_in_app(auth_url: String) -> void:
	if OS.has_feature("ios"):
		# ASWebAuthenticationSession needs only the URI scheme (e.g. "mygame"
		# from "mygame://auth/callback") to intercept the redirect internally.
		# IMPORTANT: split on ":" (colon only), not "://".
		#
		# Standard redirect URIs use "://"  e.g. "mygame://auth/callback"
		# Google reverse-client-ID uses ":/" e.g. "com.googleusercontent.apps.XXX:/path"
		#
		# split("://") finds no delimiter in the single-slash form and returns
		# the entire URI string as parts[0].  ASWebAuthenticationSession is
		# then given the full URI as its callbackURLScheme, never matches the
		# redirect, and the consent screen loops indefinitely on every Continue.
		#
		# split(":") always yields the scheme as the first token regardless of
		# whether one or two slashes follow the colon.
		var scheme := _redirect_uri.split(":")[0]
		_plugin_singleton.start_auth_session(auth_url, scheme, ios_ephemeral_browser_session)
	else:
		# Android: Chrome Custom Tab.  The redirect travels through the Android
		# intent system and arrives via _on_deeplink_received() below, exactly
		# as it does in EXTERNAL mode — no special handling in developer code.
		_plugin_singleton.launch_custom_tab(auth_url, _state)


# ═════════════════════════════════════════════════════════════════════════════
# Internal — callback handlers (developer never calls these)
# ═════════════════════════════════════════════════════════════════════════════


## Handles redirect URIs arriving through the Deeplink node.
## Used by: EXTERNAL mode (both platforms) and IN_APP on Android.
func _on_deeplink_received(url_obj: DeeplinkUrl) -> void:
	# Android Chrome Custom Tab path: delegate state validation to Java.
	#
	# Java's validate_and_consume_custom_tab_state() compares the incoming
	# state parameter against _expectedState (written at launch_custom_tab time
	# and immune to GDScript signal races).  It returns true exactly once per
	# session — on the first matching call it clears _expectedState so that
	# subsequent callers (other Deeplink nodes that also received the redirect
	# signal) get false and are silently ignored.
	#
	# Only nodes with _using_in_app_browser == true enter this branch.
	# Nodes in EXTERNAL mode (Discord, GitHub etc.) have _using_in_app_browser
	# == false and fall through to the _process_auth_params path below, where
	# they produce a harmless state-mismatch log and do nothing further.
	if (
		_using_in_app_browser
		and _plugin_singleton
		and _plugin_singleton.has_method("validate_and_consume_custom_tab_state")
	):
		var params := _parse_query_string(url_obj.get_query())
		if not params.has("code"):
			var frag_params := _parse_query_string(url_obj.get_fragment())
			for key in frag_params:
				params[key] = frag_params[key]

		var incoming_state := params.get("state", "") as String
		var code := params.get("code", "") as String

		if _plugin_singleton.validate_and_consume_custom_tab_state(incoming_state):
			# Java validated the state — call _exchange_code directly, bypassing
			# GDScript's _state check which is unreliable for the Custom Tab path.
			if not code.is_empty():
				_state = ""
				_exchange_code(code)
			else:
				auth_error.emit("Android Custom Tab callback contained no authorization code")
		# validate_and_consume returned false: wrong node or state already consumed.
		# Silently return — this is expected for the other Deeplink nodes.
		return

	# EXTERNAL mode on both platforms (and IN_APP fallback when plugin is absent):
	# use GDScript's own _state for CSRF validation.
	var params := _parse_query_string(url_obj.get_query())
	if not params.has("code"):
		var frag_params := _parse_query_string(url_obj.get_fragment())
		if frag_params.has("code"):
			for key in frag_params:
				params[key] = frag_params[key]

	_process_auth_params(params)


## Handles the completion block result from ASWebAuthenticationSession (iOS).
## [param callback_url] is the full redirect URI including query parameters.
func _on_auth_session_completed(callback_url: String) -> void:
	# Split path from query string.
	var url_parts := callback_url.split("?", false, 1)
	var raw_query := url_parts[1] if url_parts.size() > 1 else ""

	# Separate query string from optional fragment.
	var query := raw_query
	var fragment := ""
	var frag_idx := raw_query.find("#")
	if frag_idx != -1:
		query = raw_query.left(frag_idx)
		fragment = raw_query.substr(frag_idx + 1)

	var params := _parse_query_string(query)
	if not params.has("code") and not fragment.is_empty():
		var frag_params := _parse_query_string(fragment)
		for key in frag_params:
			params[key] = frag_params[key]

	_process_auth_params(params)


func _on_auth_session_cancelled() -> void:
	_state = ""
	auth_cancelled.emit()


func _on_auth_session_error(error_msg: String) -> void:
	_state = ""
	auth_error.emit(error_msg)


## Shared response handler for all callback sources.
## Validates state, checks for provider errors, starts the code exchange.
func _process_auth_params(params: Dictionary) -> void:
	var incoming_state: String = params.get("state", "")

	# Discard callbacks that do not belong to the current authorization attempt.
	if _state.is_empty() or _state != incoming_state:
		GmpLogger.log_info("Ignoring callback — state mismatch")
		return

	if params.has("error"):
		auth_error.emit(params.get("error_description", "Unknown OAuth Error"))
		_state = ""
		return

	var code: String = params.get("code", "")
	if code.is_empty():
		auth_error.emit("Authorization callback contained no code parameter")
		_state = ""
		return

	_state = ""
	_exchange_code(code)


# ═════════════════════════════════════════════════════════════════════════════
# Internal — token exchange
# ═════════════════════════════════════════════════════════════════════════════


func _exchange_code(code: String) -> void:
	var config: ProviderConfig = _get_current_config()

	var body_params := {
		"client_id": _client_id,
		"grant_type": "authorization_code",
		"code": code,
		"redirect_uri": _redirect_uri,
	}

	if not _client_secret.is_empty():
		body_params["client_secret"] = _client_secret

	if config.is_pkce_enabled():
		body_params["code_verifier"] = _code_verifier

	var query_string := ""
	for key in body_params:
		query_string += "%s=%s&" % [key, body_params[key].uri_encode()]

	_http_request.request(
		config.get_token_endpoint(),
		["Content-Type: application/x-www-form-urlencoded", "Accept: application/json"],
		HTTPClient.METHOD_POST,
		query_string
	)


func _on_token_request_completed(result, response_code, _headers, body) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code >= 400:
		auth_error.emit("Token exchange failed. HTTP %d" % response_code)
		return

	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		auth_error.emit("Failed to parse token response")
		return

	var data = json.get_data()
	if data.has("error"):
		auth_error.emit(data.get("error_description", "Token Error"))
		return

	_save_tokens_securely(data)
	auth_success.emit(data)


# ═════════════════════════════════════════════════════════════════════════════
# Internal — secure storage
# ═════════════════════════════════════════════════════════════════════════════


func _save_tokens_securely(data: Dictionary) -> void:
	if data.has("id_token"):
		var payload := _decode_jwt_payload_safe(data["id_token"])
		if payload.has("sub"):
			_save_tokens_for_session(data, payload["sub"])
		elif payload.has("email"):
			_save_tokens_for_session(data, payload["email"])
		else:
			GmpLogger.log_info("id_token present but no 'sub' or 'email' claim — call save_session() manually.")
	else:
		GmpLogger.log_info("No id_token in response — call save_session() manually.")


func _save_tokens_for_session(data: Dictionary, s_id: String) -> void:
	if not _plugin_singleton:
		return
	var prefix := "session:%s:%s:" % [OAuth2Config.Provider.keys()[provider], s_id]

	if data.has("access_token"):
		_plugin_singleton.save_token(prefix + "access_token", data["access_token"])
	if data.has("refresh_token"):
		_plugin_singleton.save_token(prefix + "refresh_token", data["refresh_token"])
	if data.has("expires_in"):
		var expiry := int(Time.get_unix_time_from_system()) + int(data["expires_in"])
		_plugin_singleton.save_token(prefix + "expires_at", str(expiry))


# ═════════════════════════════════════════════════════════════════════════════
# Internal — session queries
# ═════════════════════════════════════════════════════════════════════════════


func _filter_sessions(filter_provider: String) -> Array:
	if not _plugin_singleton:
		return []
	var unique: Dictionary = {}
	for key: String in _plugin_singleton.get_all_keys():
		if key.begins_with("session:"):
			var parts := key.split(":")  # ["session", PROVIDER, ID, FIELD]
			if parts.size() >= 4:
				var p_name: String = parts[1]
				var s_id: String = parts[2]
				if filter_provider.is_empty() or p_name == filter_provider:
					unique[p_name + ":" + s_id] = {"provider": p_name, "session_id": s_id}
	return unique.values()


func _clear_by_prefix(prefix: String) -> void:
	if not _plugin_singleton:
		return
	for key: String in _plugin_singleton.get_all_keys():
		if key.begins_with(prefix):
			_plugin_singleton.delete_token(key)


# ═════════════════════════════════════════════════════════════════════════════
# Internal — provider configuration
# ═════════════════════════════════════════════════════════════════════════════


func _get_current_config() -> ProviderConfig:
	var cfg := OAuth2Config.get_config(provider)
	if provider == OAuth2Config.Provider.CUSTOM:
		cfg.set_auth_endpoint(provider_auth_endpoint)
		cfg.set_token_endpoint(provider_token_endpoint)
		cfg.set_scopes(provider_scopes)
		cfg.set_pkce_enabled(provider_pkce_enabled)
		cfg.set_params(provider_parameters)
	if provider_domain.is_empty():
		if cfg.get_auth_endpoint().contains("%s") or cfg.get_token_endpoint().contains("%s"):
			GmpLogger.log_error("Provider domain is required for endpoint interpolation!")
	else:
		cfg.set_domain(provider_domain)
	return cfg


# ═════════════════════════════════════════════════════════════════════════════
# Internal — utilities
# ═════════════════════════════════════════════════════════════════════════════


func _decode_jwt_payload_safe(jwt: String) -> Dictionary:
	var parts := jwt.split(".")
	if parts.size() < 2:
		return {}
	var b64 := parts[1].replace("-", "+").replace("_", "/")
	while b64.length() % 4 != 0:
		b64 += "="
	var json_str := Marshalls.base64_to_utf8(b64)
	return JSON.parse_string(json_str) if json_str else {}


func _parse_query_string(query: String) -> Dictionary:
	var res: Dictionary = {}
	for pair in query.split("&"):
		var parts := pair.split("=")
		if parts.size() == 2:
			res[parts[0]] = parts[1].uri_decode()
	return res


# ═════════════════════════════════════════════════════════════════════════════
# Editor — property visibility
# ═════════════════════════════════════════════════════════════════════════════


func _validate_property(property: Dictionary) -> void:
	match property.name:
		"ios_ephemeral_browser_session":
			if browser_mode != BrowserMode.IN_APP:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"provider_domain":
			if provider == OAuth2Config.Provider.CUSTOM or provider == OAuth2Config.Provider.AUTH0:
				property.usage = PROPERTY_USAGE_DEFAULT
			else:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		_:
			if property.name.begins_with("provider_") and property.name != "provider_domain":
				if provider != OAuth2Config.Provider.CUSTOM:
					property.usage = PROPERTY_USAGE_READ_ONLY | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
			elif property.name.ends_with("_secret"):
				property.usage = PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_SECRET


func _set_provider(value: OAuth2Config.Provider) -> void:
	if provider != OAuth2Config.Provider.CUSTOM and value == OAuth2Config.Provider.CUSTOM:
		_reset_provider_configuration()
	elif value != OAuth2Config.Provider.CUSTOM:
		_set_provider_configuration(value)
	provider = value
	notify_property_list_changed()


func _set_provider_domain(value: String) -> void:
	if not auth_endpoint_format.is_empty() and not value.is_empty():
		provider_auth_endpoint = auth_endpoint_format % provider_domain
	if not token_endpoint_format.is_empty() and not value.is_empty():
		provider_token_endpoint = token_endpoint_format % provider_domain
	provider_domain = value


func _reset_provider_configuration() -> void:
	provider_auth_endpoint = ""
	provider_token_endpoint = ""
	provider_domain = ""
	provider_scopes = []
	provider_pkce_enabled = true
	provider_parameters = {}
	auth_endpoint_format = ""
	token_endpoint_format = ""


func _set_provider_configuration(a_provider: OAuth2Config.Provider) -> void:
	var cfg: ProviderConfig = OAuth2Config.get_config(a_provider)
	if cfg.get_auth_endpoint().contains("%s"):
		auth_endpoint_format = cfg.get_auth_endpoint()
		provider_auth_endpoint = ""
	else:
		provider_auth_endpoint = cfg.get_auth_endpoint()
	if cfg.get_token_endpoint().contains("%s"):
		token_endpoint_format = cfg.get_token_endpoint()
		provider_token_endpoint = ""
	else:
		provider_token_endpoint = cfg.get_token_endpoint()
	provider_domain = ""
	provider_scopes = cfg.get_scopes()
	provider_pkce_enabled = cfg.is_pkce_enabled()
	provider_parameters = cfg.get_params()
