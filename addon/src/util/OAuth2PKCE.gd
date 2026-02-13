#
# © 2025-present https://github.com/cengiz-pz
#

class_name OAuth2PKCE extends RefCounted

static func generate_verifier() -> String:
	var chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
	var verifier = ""
	for i in range(128):
		verifier += chars[randi() % chars.length()]
	return verifier

static func generate_challenge(verifier: String) -> String:
	var context = HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(verifier.to_utf8_buffer())
	var hash_bytes = context.finish()
	return Marshalls.raw_to_base64(hash_bytes)\
		.replace("+", "-")\
		.replace("/", "_")\
		.replace("=", "") # Base64URL no padding
