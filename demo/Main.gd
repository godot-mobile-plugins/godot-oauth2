#
# © 2025-present https://github.com/cengiz-pz
#

extends Node

const GOOGLE_CLIENT_ID_ANDROID = "854928845060-441ot0moa19jlif3farnu2413u0o17hq.apps.googleusercontent.com"
const GOOGLE_ANDROID_REVERSED_ID = "com.googleusercontent.apps.854928845060-441ot0moa19jlif3farnu2413u0o17hq"
const GOOGLE_CLIENT_ID_IOS = "854928845060-kjgra3jv1o8gbbf44jino23r95f26seu.apps.googleusercontent.com"
const GOOGLE_IOS_REVERSED_ID = "com.googleusercontent.apps.854928845060-kjgra3jv1o8gbbf44jino23r95f26seu"
const DISCORD_CLIENT_ID = "1452145666771128534"
const GITHUB_CLIENT_ID = "Ov23lic9l6wvOe0ykb76"
const APP_REDIRECT_URI = "oauth2demo://auth/callback"

@onready var google_oauth2_node: OAuth2 = $GoogleOAuth2
@onready var discord_oauth2_node: OAuth2 = $DiscordOAuth2
@onready var github_oauth2_node: OAuth2 = $GitHubOAuth2
@onready var status_label: Label = $CanvasLayer/MainContainer/VBoxContainer/StatusHBoxContainer/ValueLabel
@onready var google_button: Button = $CanvasLayer/MainContainer/VBoxContainer/GoogleButton
@onready var discord_button: Button = $CanvasLayer/MainContainer/VBoxContainer/DiscordButton
@onready var github_button: Button = $CanvasLayer/MainContainer/VBoxContainer/GithubButton
@onready var logout_button: Button = $CanvasLayer/MainContainer/VBoxContainer/LogoutButton
@onready var _label := $CanvasLayer/MainContainer/VBoxContainer/RichTextLabel as RichTextLabel
@onready var _android_texture_rect := %AndroidTextureRect as TextureRect
@onready var _ios_texture_rect := %iOSTextureRect as TextureRect

var _google_client_id: String
var _active_texture_rect: TextureRect


func _ready() -> void:
	if OS.has_feature("ios"):
		_android_texture_rect.hide()
		_active_texture_rect = _ios_texture_rect
		_google_client_id = GOOGLE_CLIENT_ID_IOS
	else:
		_ios_texture_rect.hide()
		_active_texture_rect = _android_texture_rect
		_google_client_id = GOOGLE_CLIENT_ID_ANDROID

	var active_users: PackedStringArray = []

	# Check Google Sessions
	var g_sessions = google_oauth2_node.get_active_sessions(OAuth2Config.Provider.GOOGLE)
	for s in g_sessions:
		active_users.append("Google(%s)" % s["session_id"])
		_print_to_screen("Recovered Google Session: %s" % s["session_id"])

	# Check Discord Sessions
	var d_sessions = discord_oauth2_node.get_active_sessions(OAuth2Config.Provider.DISCORD)
	for s in d_sessions:
		active_users.append("Discord(%s)" % s["session_id"])
		_print_to_screen("Recovered Discord Session: %s" % s["session_id"])

	# Check GitHub Sessions
	var gh_sessions = github_oauth2_node.get_active_sessions(OAuth2Config.Provider.GITHUB)
	for s in gh_sessions:
		active_users.append("GitHub(%s)" % s["session_id"])
		_print_to_screen("Recovered GitHub Session: %s" % s["session_id"])

	if active_users.is_empty():
		status_label.text = "Please Log In"
	else:
		status_label.text = "Logged in: %s" % ", ".join(active_users)


# UI Button Handlers


func _on_google_button_pressed() -> void:
	google_oauth2_node.authorize()


func _on_discord_button_pressed() -> void:
	discord_oauth2_node.authorize()


func _on_github_button_pressed() -> void:
	github_oauth2_node.authorize()


func _on_logout_button_pressed() -> void:
	google_oauth2_node.remove_all_active_sessions()
	discord_oauth2_node.remove_all_active_sessions()
	github_oauth2_node.remove_all_active_sessions()
	status_label.text = "Logged out (All sessions cleared)."


# --- Signal Callbacks ---


func _on_google_o_auth_2_auth_started() -> void:
	status_label.text = "Opening Google OAuth on browser..."
	google_button.disabled = true


func _on_google_o_auth_2_auth_error(error_msg: String) -> void:
	status_label.text = "Google Error: %s" % error_msg
	_print_to_screen("Google OAuth2 Error: " + error_msg, true)
	google_button.disabled = false


func _on_google_o_auth_2_auth_success(token_data: Dictionary) -> void:
	status_label.text = "Google Login Successful!"
	google_button.disabled = false
	_print_token_debug(token_data)
	_fetch_user_profile(OAuth2Config.Provider.GOOGLE, token_data, google_oauth2_node)


func _on_discord_o_auth_2_auth_started() -> void:
	status_label.text = "Opening Discord OAuth on browser..."
	discord_button.disabled = true


func _on_discord_o_auth_2_auth_error(error_msg: String) -> void:
	status_label.text = "Discord Error: %s" % error_msg
	_print_to_screen("Discord OAuth2 Error: " + error_msg, true)
	discord_button.disabled = false


func _on_discord_o_auth_2_auth_success(token_data: Dictionary) -> void:
	status_label.text = "Discord Login Successful!"
	discord_button.disabled = false
	_print_token_debug(token_data)
	_fetch_user_profile(OAuth2Config.Provider.DISCORD, token_data, discord_oauth2_node)


func _on_github_o_auth_2_auth_started() -> void:
	status_label.text = "Opening GitHub OAuth on browser..."
	github_button.disabled = true


func _on_github_o_auth_2_auth_error(error_msg: String) -> void:
	status_label.text = "GitHub Error: %s" % error_msg
	_print_to_screen("GitHub OAuth2 Error: " + error_msg, true)
	github_button.disabled = false


func _on_github_o_auth_2_auth_success(token_data: Dictionary) -> void:
	status_label.text = "GitHub Login Successful!"
	github_button.disabled = false
	_print_token_debug(token_data)
	_fetch_user_profile(OAuth2Config.Provider.GITHUB, token_data, github_oauth2_node)


func _print_token_debug(token_data: Dictionary) -> void:
	var access_token = token_data.get("access_token")
	var refresh_token = token_data.get("refresh_token")
	var expires_in = token_data.get("expires_in")
	_print_to_screen("Access Token: %s" % access_token)
	_print_to_screen("Refresh Token: %s" % refresh_token)
	_print_to_screen("Expires In: %s" % str(expires_in))


# --- Profile Fetching & Session Saving ---


func _fetch_user_profile(provider: OAuth2Config.Provider, token_data: Dictionary, node_ref: OAuth2) -> void:
	var access_token = token_data.get("access_token", "")

	# Special Case: Apple (or Google/Auth0 w/ OIDC)
	# If id_token is present, the plugin *might* have auto-saved it using the 'sub' claim.
	# But we fetch profile anyway to show name.
	if provider == OAuth2Config.Provider.APPLE:
		var id_token = token_data.get("id_token", "")
		if id_token.is_empty():
			return
		var profile = _decode_jwt_payload(id_token)
		status_label.text = "Logged in as: " + profile.get("email", "Apple User")
		return

	# --- Standard Case: Google, GitHub, Discord ---
	var url = ""
	var headers = ["Authorization: Bearer %s" % access_token]

	match provider:
		OAuth2Config.Provider.GOOGLE:
			url = "https://www.googleapis.com/oauth2/v3/userinfo"
		OAuth2Config.Provider.GITHUB:
			url = "https://api.github.com/user"
			headers.append("User-Agent: Godot-OAuth2-App")
		OAuth2Config.Provider.DISCORD:
			url = "https://discord.com/api/users/@me"

	if url.is_empty():
		return

	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(
		func(result, code, _h, body):
			if result == HTTPRequest.RESULT_SUCCESS and code == 200:
				var json = JSON.parse_string(body.get_string_from_utf8())
				_print_to_screen("Profile Data: %s" % str(json))

				var unique_id = ""
				var display_name = ""

				if provider == OAuth2Config.Provider.GITHUB:
					unique_id = str(json.get("id"))  # Use numeric ID as stable key
					display_name = json.get("login", "GitHub User")
				elif provider == OAuth2Config.Provider.DISCORD:
					unique_id = str(json.get("id"))
					display_name = json.get("username", "Discord User")
				else:  # Google
					unique_id = json.get("sub", "")
					display_name = json.get("email", "User")

				status_label.text = "Logged in as: " + display_name

				# Manually save session using the fetched ID to ensure token is stored
				# against a known User ID
				if not unique_id.is_empty():
					node_ref.save_session(token_data, unique_id)
					_print_to_screen("Session saved for ID: " + unique_id)

			else:
				_print_to_screen("Failed to fetch profile. Code: %d" % code, true)
			http.queue_free()
	)
	http.request(url, headers)


# Helper to decode the payload of a JWT (like Apple's id_token)
func _decode_jwt_payload(jwt: String) -> Dictionary:
	var parts = jwt.split(".")
	if parts.size() < 2:
		return {}

	var payload_b64 = parts[1].replace("-", "+").replace("_", "/")

	while payload_b64.length() % 4 != 0:
		payload_b64 += "="

	var json_string = Marshalls.base64_to_utf8(payload_b64)
	return JSON.parse_string(json_string) if json_string else {}


func _print_to_screen(a_message: String, a_is_error: bool = false) -> void:
	if a_is_error:
		_label.push_color(Color.CRIMSON)

	_label.add_text("%s\n\n" % a_message)

	if a_is_error:
		_label.pop()
		printerr("Demo app:: " + a_message)
	else:
		print("Demo app:: " + a_message)

	_label.scroll_to_line(_label.get_line_count() - 1)
