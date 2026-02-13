#
# © 2025-present https://github.com/cengiz-pz
#

class_name ProviderConfig extends RefCounted

const AUTH_ENDPOINT_PROPERTY: String = "auth_endpoint"
const TOKEN_ENDPOINT_PROPERTY: String = "token_endpoint"
const DOMAIN_PROPERTY: String = "domain"
const SCOPES_PROPERTY: String = "scopes"
const PKCE_ENABLED_PROPERTY: String = "pkce_enabled"
const PARAMS_PROPERTY: String = "params"

const DEFAULT_DATA: Dictionary = {
	SCOPES_PROPERTY: [],
	PARAMS_PROPERTY: {}
}

var _data: Dictionary


func _init(a_data: Dictionary = DEFAULT_DATA.duplicate()):
	_data = a_data


func get_auth_endpoint() -> String:
	if not _data.has(AUTH_ENDPOINT_PROPERTY):
		return ""

	return _data[AUTH_ENDPOINT_PROPERTY] if not _data.has(DOMAIN_PROPERTY) \
			else _data[AUTH_ENDPOINT_PROPERTY] % _data[DOMAIN_PROPERTY]


func set_auth_endpoint(a_auth_endpoint: String) -> void:
	_data[AUTH_ENDPOINT_PROPERTY] = a_auth_endpoint


func get_token_endpoint() -> String:
	if not _data.has(TOKEN_ENDPOINT_PROPERTY):
		return ""

	return _data[TOKEN_ENDPOINT_PROPERTY] if not _data.has(DOMAIN_PROPERTY) \
			else _data[TOKEN_ENDPOINT_PROPERTY] % _data[DOMAIN_PROPERTY]


func set_token_endpoint(a_token_endpoint: String) -> void:
	_data[TOKEN_ENDPOINT_PROPERTY] = a_token_endpoint


func set_domain(a_domain: String) -> void:
	_data[DOMAIN_PROPERTY] = a_domain


func get_scopes() -> Array:
	return _data[SCOPES_PROPERTY] if _data.has(SCOPES_PROPERTY) else []


func set_scopes(a_scopes: Array) -> void:
	_data[SCOPES_PROPERTY] = a_scopes


func is_pkce_enabled() -> bool:
	return _data[PKCE_ENABLED_PROPERTY] if _data.has(PKCE_ENABLED_PROPERTY) else false


func set_pkce_enabled(a_is_enabled: bool) -> void:
	_data[PKCE_ENABLED_PROPERTY] = a_is_enabled


func get_params() -> Dictionary:
	return _data[PARAMS_PROPERTY] if _data.has(PARAMS_PROPERTY) else {}


func set_params(a_params: Dictionary) -> void:
	_data[PARAMS_PROPERTY] = a_params
