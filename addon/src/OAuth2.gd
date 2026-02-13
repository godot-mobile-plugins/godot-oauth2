#
# © 2025-present https://github.com/cengiz-pz
#

@tool
@icon("icon.png")
class_name OAuth2 extends Node

## Emitted when the authentication flow is initiated.
## This is usually triggered right before opening the external browser or web view.
signal auth_started

## Emitted when authentication completes successfully.
## @param token_data A Dictionary containing access token, refresh token,
## expiration data, and any provider-specific fields.
signal auth_success(token_data: Dictionary)

## Emitted when an authentication error occurs.
## @param error_msg A human-readable error message describing the failure.
signal auth_error(error_msg: String)

## Emitted when the user cancels the authentication flow
## (for example, by closing the browser or denying consent).
signal auth_cancelled


## Name used to register this plugin as an Engine singleton.
## Access it via `Engine.get_singleton(PLUGIN_SINGLETON_NAME)`.
const PLUGIN_SINGLETON_NAME: String = "@pluginName@"


@export_category("Provider Configuration")

## OAuth2 provider preset to use.
## Changing this may automatically populate provider-specific endpoints and defaults.
@export var provider: OAuth2Config.Provider = OAuth2Config.Provider.GOOGLE: set = _set_provider


@export_group("Settings","provider_")

## Authorization endpoint URL for the OAuth2 provider.
## This is where the user is redirected to grant consent.
@export var provider_auth_endpoint: String = ""

## Token endpoint URL for the OAuth2 provider.
## Used to exchange the authorization code for access tokens.
@export var provider_token_endpoint: String = ""

## Domain used by Auth0 or custom OAuth2 tenants.
## Example: `my-tenant.auth0.com`
@export var provider_domain: String = "": set = _set_provider_domain

## OAuth2 scopes requested during authentication.
## Example: ["openid", "profile", "email"]
@export var provider_scopes: PackedStringArray = []

## Enables PKCE (Proof Key for Code Exchange).
## Strongly recommended for public clients such as games and desktop apps.
@export var provider_pkce_enabled: bool = true

## Additional provider-specific parameters to include
## in the authorization or token requests.
@export var provider_parameters: Dictionary = {}


@export_category("Client Configuration")


@export_group("Android","android_")

## OAuth2 Client ID issued by the provider for the Android platform.
@export var android_client_id: String = ""

## OAuth2 Client Secret issued by the provider for the Android platform.
## Avoid using this in client-side applications unless absolutely required.
@export var android_client_secret: String = ""

## Redirect URI registered with the OAuth2 provider for the Android platform.
## Typically uses a custom scheme handled via deep linking.
@export var android_redirect_uri: String = "mygame://auth/callback"

## Path to the Deeplink node responsible for handling redirect callbacks.
## This node should emit events when the redirect URI is opened.
@export_node_path("Deeplink") var android_deeplink_path: NodePath


@export_group("iOS","ios_")

## OAuth2 Client ID issued by the provider for the iOS platform.
@export var ios_client_id: String = ""

## OAuth2 Client Secret issued by the provider for the iOS platform.
## Avoid using this in client-side applications unless absolutely required.
@export var ios_client_secret: String = ""

## Redirect URI registered with the OAuth2 provider for the iOS platform.
## Typically uses a custom scheme handled via deep linking.
@export var ios_redirect_uri: String = "mygame://auth/callback"

## Path to the Deeplink node responsible for handling redirect callbacks.
## This node should emit events when the redirect URI is opened.
@export_node_path("Deeplink") var ios_deeplink_path: NodePath


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

func _ready() -> void:
	if Engine.is_editor_hint(): return

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

	if _deeplink_path:
		_deeplink_node = get_node(_deeplink_path)

	if _deeplink_node:
		initialize(_deeplink_node)
	else:
		log_warn("Deeplink node not found")


func initialize(a_deeplink_node: Deeplink) -> void:
	_deeplink_node = a_deeplink_node

	if not _deeplink_node.deeplink_received.is_connected(_on_deeplink_received):
		_deeplink_node.deeplink_received.connect(_on_deeplink_received)

	_setup_http()
	_setup_native_plugin()


func _setup_http() -> void:
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_token_request_completed)


func _setup_native_plugin() -> void:
	if Engine.has_singleton(PLUGIN_SINGLETON_NAME):
		_plugin_singleton = Engine.get_singleton(PLUGIN_SINGLETON_NAME)
	else:
		log_warn("OAuth2: Native SecureStorage plugin not found. Tokens will not be persisted securely.")

# Public API

func authorize() -> void:
	var config: ProviderConfig = _get_current_config()
	if config.get_auth_endpoint().is_empty() or _client_id.is_empty():
		auth_error.emit("Configuration Invalid: Missing endpoint or client_id")
		return

	auth_started.emit()

	# State & PKCE
	_state = OAuth2PKCE.generate_verifier().left(32) # Simple random string
	var params = config.get_params()

	params["client_id"] = _client_id
	params["redirect_uri"] = _redirect_uri
	params["response_type"] = "code"
	params["state"] = _state
	params["scope"] = " ".join(config.get_scopes())

	if config.is_pkce_enabled():
		_code_verifier = OAuth2PKCE.generate_verifier()
		var challenge = OAuth2PKCE.generate_challenge(_code_verifier)
		params["code_challenge"] = challenge
		params["code_challenge_method"] = "S256"

	# Build URL
	var query_parts = []
	for key in params:
		query_parts.append("%s=%s" % [key.uri_encode(), str(params[key]).uri_encode()])

	var auth_url = config.get_auth_endpoint() + "?" + "&".join(query_parts)

	# Launch external browser
	OS.shell_open(auth_url)

## Manually saves a session. Use this if the provider does not support OIDC (no id_token)
## or if you wish to use a custom session ID (e.g. username) instead of the subject ID.
func save_session(token_data: Dictionary, session_id: String) -> void:
	_save_tokens_securely_for_session(token_data, session_id)

## Returns the access token for the first active session found, or empty string.
func get_stored_token() -> String:
	var sessions = get_active_sessions(provider)
	if sessions.size() > 0:
		return get_stored_token_for(provider, sessions[0]["session_id"])
	return ""

## Retrieves a specific token for a provider and session.
func get_stored_token_for(p_provider: OAuth2Config.Provider, s_id: String) -> String:
	if _plugin_singleton:
		var prefix = "session:%s:%s:" % [OAuth2Config.Provider.keys()[p_provider], s_id]
		return _plugin_singleton.get_token(prefix + "access_token")
	return ""

func clear_tokens() -> void:
	remove_active_sessions(provider)

# Session Management API

func get_all_active_sessions() -> Array:
	return _filter_sessions("")

func get_active_sessions(p_provider: OAuth2Config.Provider) -> Array:
	return _filter_sessions(OAuth2Config.Provider.keys()[p_provider])

func remove_all_active_sessions() -> void:
	_clear_by_prefix("session:")

func remove_active_sessions(p_provider: OAuth2Config.Provider) -> void:
	_clear_by_prefix("session:%s:" % OAuth2Config.Provider.keys()[p_provider])

# Helper to parse keys and return session dictionaries
func _filter_sessions(filter_provider: String) -> Array:
	var sessions = []
	if not _plugin_singleton: return sessions
	
	var all_keys = _plugin_singleton.get_all_keys()
	var unique_sessions = {} 

	for key in all_keys:
		if key.begins_with("session:"):
			var parts = key.split(":") # [session, PROVIDER, ID, TYPE]
			if parts.size() >= 4:
				var p_name = parts[1]
				var s_id = parts[2]
				if filter_provider == "" or p_name == filter_provider:
					unique_sessions[p_name + ":" + s_id] = {"provider": p_name, "session_id": s_id}
	
	return unique_sessions.values()

func _clear_by_prefix(prefix: String) -> void:
	if not _plugin_singleton: return
	for key in _plugin_singleton.get_all_keys():
		if key.begins_with(prefix):
			_plugin_singleton.delete_token(key)

# Internal Logic

func _get_current_config() -> ProviderConfig:
	var __config = OAuth2Config.get_config(provider)
	if provider == OAuth2Config.Provider.CUSTOM:
		__config.set_auth_endpoint(provider_auth_endpoint)
		__config.set_token_endpoint(provider_token_endpoint)
		__config.set_scopes(provider_scopes)
		__config.set_pkce_enabled(provider_pkce_enabled)
		__config.set_params(provider_parameters)
	if provider_domain.is_empty():
		if __config.get_auth_endpoint().contains("%s") or __config.get_token_endpoint().contains("%s"):
			log_error("Provider domain cannot be empty as it is required for interpolation into endpoints!")
	else:
		__config.set_domain(provider_domain)
	return __config


func _on_deeplink_received(url_obj: DeeplinkUrl) -> void:
	var query = url_obj.get_query()
	var fragment = url_obj.get_fragment()
	var params = _parse_query_string(query)

	# Handle cases where code might be in the fragment
	if not params.has("code"):
		var fragment_params = _parse_query_string(fragment)
		if fragment_params.has("code"):
			# Merge fragment parameters into params if code is found
			for key in fragment_params:
				params[key] = fragment_params[key]

	# State Validation: if not waiting for a login (_state is empty) OR the state is
	# for a different session, then silently return.
	var incoming_state = params.get("state", "")
	if _state.is_empty() or _state != incoming_state:
		log_info("%s skipping deeplink as state doesn't match" % get_path())
		return 

	# Handle actual Errors from the provider
	if params.has("error"):
		auth_error.emit(params.get("error_description", "Unknown OAuth Error"))
		_state = "" # Clear state after handling
		return

	# Success: Proceed to exchange code for token
	var code = params.get("code")
	_state = "" # Clear state as it's no longer needed
	_exchange_code(code)


func _exchange_code(code: String) -> void:
	var config: ProviderConfig = _get_current_config()

	var body_params = {
		"client_id": _client_id,
		"grant_type": "authorization_code",
		"code": code,
		"redirect_uri": _redirect_uri
	}

	if not _client_secret.is_empty():
		body_params["client_secret"] = _client_secret

	if config.is_pkce_enabled():
		body_params["code_verifier"] = _code_verifier

	var query_string = ""
	for key in body_params:
		query_string += "%s=%s&" % [key, body_params[key].uri_encode()]

	var headers = [
		"Content-Type: application/x-www-form-urlencoded",
		"Accept: application/json" # Request a JSON response
	]

	_http_request.request(config.get_token_endpoint(), headers, HTTPClient.METHOD_POST, query_string)


func _on_token_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS or response_code >= 400:
		auth_error.emit("Token exchange failed. Code: %d" % response_code)
		return

	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	if error != OK:
		auth_error.emit("Failed to parse token response")
		return

	var data = json.get_data()
	if data.has("error"):
		auth_error.emit(data.get("error_description", "Token Error"))
		return

	# Try to save automatically if we can find a user ID in the token
	_save_tokens_securely(data)
	auth_success.emit(data)


# Handle auto-saving if id_token exists
func _save_tokens_securely(data: Dictionary) -> void:
	# Try to extract the Subject (sub) from id_token to use as session ID
	if data.has("id_token"):
		var id_token = data["id_token"]
		var payload = _decode_jwt_payload_safe(id_token)
		if payload.has("sub"):
			_save_tokens_securely_for_session(data, payload["sub"])
		elif payload.has("email"):
			_save_tokens_securely_for_session(data, payload["email"])
		else:
			log_info("id_token found but no 'sub' or 'email' claim. Session not auto-saved.")
	else:
		log_info("No id_token in response. Session not auto-saved. Please call save_session() manually.")

# Helper to decode JWT (copied here to avoid dependency on Main)
func _decode_jwt_payload_safe(jwt: String) -> Dictionary:
	var parts = jwt.split(".")
	if parts.size() < 2: return {}
	var payload_b64 = parts[1].replace("-", "+").replace("_", "/")
	while payload_b64.length() % 4 != 0: payload_b64 += "="
	var json_string = Marshalls.base64_to_utf8(payload_b64)
	return JSON.parse_string(json_string) if json_string else {}

func _save_tokens_securely_for_session(data: Dictionary, s_id: String) -> void:
	if not _plugin_singleton: return
	
	var provider_name = OAuth2Config.Provider.keys()[provider]
	var prefix = "session:%s:%s:" % [provider_name, s_id]
	
	if data.has("access_token"):
		_plugin_singleton.save_token(prefix + "access_token", data["access_token"])
	if data.has("refresh_token"):
		_plugin_singleton.save_token(prefix + "refresh_token", data["refresh_token"])
	
	if data.has("expires_in"):
		var expiry = int(Time.get_unix_time_from_system()) + int(data["expires_in"])
		_plugin_singleton.save_token(prefix + "expires_at", str(expiry))


func _parse_query_string(query: String) -> Dictionary:
	var res = {}
	var pairs = query.split("&")
	for pair in pairs:
		var parts = pair.split("=")
		if parts.size() == 2:
			res[parts[0]] = parts[1].uri_decode()
	return res


func _validate_property(property: Dictionary) -> void:
	if property.name.begins_with("provider_"):
		if property.name == "provider_domain":
			if provider == OAuth2Config.Provider.CUSTOM or provider == OAuth2Config.Provider.AUTH0:
				property.usage = PROPERTY_USAGE_DEFAULT
			else:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		else:
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
	var __config: ProviderConfig = OAuth2Config.get_config(a_provider)
	if __config.get_auth_endpoint().contains("%s"):
		auth_endpoint_format = __config.get_auth_endpoint()
		provider_auth_endpoint = ""
	else:
		provider_auth_endpoint = __config.get_auth_endpoint()
	if __config.get_token_endpoint().contains("%s"):
		token_endpoint_format = __config.get_token_endpoint()
		provider_token_endpoint = ""
	else:
		provider_token_endpoint = __config.get_token_endpoint()
	provider_domain = ""
	provider_scopes = __config.get_scopes()
	provider_pkce_enabled = __config.is_pkce_enabled()
	provider_parameters = __config.get_params()


static func log_error(a_description: String) -> void:
	push_error("%s: %s" % [PLUGIN_SINGLETON_NAME, a_description])


static func log_warn(a_description: String) -> void:
	push_warning("%s: %s" % [PLUGIN_SINGLETON_NAME, a_description])


static func log_info(a_description: String) -> void:
	print_rich("[color=lime]%s: INFO: %s[/color]" % [PLUGIN_SINGLETON_NAME, a_description])
