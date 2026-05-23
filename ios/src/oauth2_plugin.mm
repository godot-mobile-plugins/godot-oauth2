//
// © 2025-present https://github.com/cengiz-pz
//

#import "oauth2_plugin.h"

#import <AuthenticationServices/AuthenticationServices.h>
#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <UIKit/UIKit.h>

OAuth2Plugin *OAuth2Plugin::instance = NULL;

// ═══════════════════════════════════════════════════════════════════════════
// Presentation-context provider (iOS 13+)
//
// ASWebAuthenticationSession requires an ASWebAuthenticationPresentationContextProviding
// object so it knows which UIWindow to attach its browser sheet to.
// This helper resolves the active window at presentation time.
// ═══════════════════════════════════════════════════════════════════════════

API_AVAILABLE(ios(13.0))
@interface _OAuth2PresentationContextProvider : NSObject <ASWebAuthenticationPresentationContextProviding>
@end

@implementation _OAuth2PresentationContextProvider

- (ASPresentationAnchor)presentationAnchorForWebAuthenticationSession:(ASWebAuthenticationSession *)session {
	// iOS 15+: resolve through the connected scene graph.
	if (@available(iOS 15.0, *)) {
		for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
			if (scene.activationState == UISceneActivationStateForegroundActive) {
				UIWindow *w = scene.windows.firstObject;
				if (w) {
					return w;
				}
			}
		}
	}

	// iOS 13–14 fallback.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	UIWindow *kw = UIApplication.sharedApplication.keyWindow;
	if (kw) {
		return kw;
	}
	return UIApplication.sharedApplication.windows.firstObject;
#pragma clang diagnostic pop
}

@end

// ═══════════════════════════════════════════════════════════════════════════
// Module-level session storage
//
// Strong references prevent ARC from releasing the session and its context
// provider before the completion block fires.
// ═══════════════════════════════════════════════════════════════════════════

static ASWebAuthenticationSession *sAuthSession API_AVAILABLE(ios(12.0)) = nil;
static _OAuth2PresentationContextProvider *sPresentationContext API_AVAILABLE(ios(13.0)) = nil;

// ═══════════════════════════════════════════════════════════════════════════
// Plugin method and signal registration
// ═══════════════════════════════════════════════════════════════════════════

void OAuth2Plugin::_bind_methods() {
	// -- Signals ------------------------------------------------------------

	// Emitted when ASWebAuthenticationSession delivers the redirect URI through
	// its completion block.  callback_url is the full redirect URI including
	// the authorization code and state as query parameters.
	ADD_SIGNAL(MethodInfo("auth_session_completed", PropertyInfo(Variant::STRING, "callback_url")));

	// Emitted when the user dismisses the browser sheet without authenticating
	// (maps to ASWebAuthenticationSessionErrorCodeCanceledLogin).
	ADD_SIGNAL(MethodInfo("auth_session_cancelled"));

	// Emitted for unrecoverable errors other than user cancellation.
	ADD_SIGNAL(MethodInfo("auth_session_error", PropertyInfo(Variant::STRING, "error_message")));

	// -- In-app browser -----------------------------------------------------
	ClassDB::bind_method(
			D_METHOD("start_auth_session", "url", "callback_scheme", "ephemeral"), &OAuth2Plugin::start_auth_session);
	ClassDB::bind_method(D_METHOD("cancel_auth_session"), &OAuth2Plugin::cancel_auth_session);

	// -- Keychain / token storage -------------------------------------------
	ClassDB::bind_method(D_METHOD("get_all_keys"), &OAuth2Plugin::get_all_keys);
	ClassDB::bind_method(D_METHOD("save_token", "key", "value"), &OAuth2Plugin::save_token);
	ClassDB::bind_method(D_METHOD("get_token", "key"), &OAuth2Plugin::get_token);
	ClassDB::bind_method(D_METHOD("delete_token", "key"), &OAuth2Plugin::delete_token);
}

// ═══════════════════════════════════════════════════════════════════════════
// In-app browser – ASWebAuthenticationSession
// ═══════════════════════════════════════════════════════════════════════════

void OAuth2Plugin::start_auth_session(String p_url, String p_callback_scheme, bool p_ephemeral) {
	NSString *urlStr = [NSString stringWithUTF8String:p_url.utf8().get_data()];
	NSString *schemeStr = [NSString stringWithUTF8String:p_callback_scheme.utf8().get_data()];

	NSURL *authURL = [NSURL URLWithString:urlStr];
	if (!authURL) {
		emit_signal("auth_session_error", String("Invalid authorization URL"));
		return;
	}

	// Raw pointer capture for the block.  The plugin singleton has process
	// lifetime so this pointer remains valid for the entire session duration.
	OAuth2Plugin *self = this;

	if (@available(iOS 12.0, *)) {
		// Lazily initialize the presentation context provider (iOS 13+).
		if (@available(iOS 13.0, *)) {
			if (!sPresentationContext) {
				sPresentationContext = [[_OAuth2PresentationContextProvider alloc] init];
			}
		}

		sAuthSession = [[ASWebAuthenticationSession alloc]
					  initWithURL:authURL
				callbackURLScheme:schemeStr
				completionHandler:^(NSURL *callbackURL, NSError *error) {
					// Immediately release the session so the OS can clean up resources.
					sAuthSession = nil;

					if (error) {
						if (error.code == ASWebAuthenticationSessionErrorCodeCanceledLogin) {
							// User-initiated dismissal: report as cancellation, not error.
							dispatch_async(dispatch_get_main_queue(), ^{
								self->emit_signal("auth_session_cancelled");
							});
						} else {
							String errMsg([error.localizedDescription UTF8String]);
							dispatch_async(dispatch_get_main_queue(), ^{
								self->emit_signal("auth_session_error", errMsg);
							});
						}
						return;
					}

					if (callbackURL) {
						String callbackStr([callbackURL.absoluteString UTF8String]);
						// Dispatch to the main queue so emit_signal runs on Godot's
						// main thread.  Godot's SceneTree runs on the main thread on
						// iOS, making dispatch_get_main_queue() the correct choice.
						dispatch_async(dispatch_get_main_queue(), ^{
							self->emit_signal("auth_session_completed", callbackStr);
						});
					} else {
						dispatch_async(dispatch_get_main_queue(), ^{
							self->emit_signal("auth_session_error", String("Session completed with no callback URL"));
						});
					}
				}];

		if (@available(iOS 13.0, *)) {
			sAuthSession.presentationContextProvider = sPresentationContext;

			// Ephemeral (private) mode: no cookie or credential sharing with
			// Safari.  SSO (non-ephemeral) reuses the user's existing browser
			// session so they skip the login form when already signed in.
			sAuthSession.prefersEphemeralWebBrowserSession = p_ephemeral;
		}

		BOOL started = [sAuthSession start];
		if (!started) {
			sAuthSession = nil;
			emit_signal("auth_session_error", String("ASWebAuthenticationSession failed to start"));
		}

	} else {
		// Unreachable if the Xcode deployment target is iOS 12+.
		emit_signal("auth_session_error", String("ASWebAuthenticationSession requires iOS 12 or later"));
	}
}

void OAuth2Plugin::cancel_auth_session() {
	if (@available(iOS 12.0, *)) {
		if (sAuthSession) {
			[sAuthSession cancel];
			sAuthSession = nil;
			// Do NOT emit auth_session_cancelled here: the cancellation was
			// app-initiated.  GDScript's cancel_auth() emits auth_cancelled on
			// the OAuth2 node directly after calling this method.
		}
	}
}

// ═══════════════════════════════════════════════════════════════════════════
// Keychain / secure token storage
// ═══════════════════════════════════════════════════════════════════════════

PackedStringArray OAuth2Plugin::get_all_keys() {
	PackedStringArray key_list;

	NSDictionary *query = @{
		(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
		(__bridge id)kSecReturnAttributes : @YES,
		(__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitAll
	};

	CFTypeRef result = NULL;
	if (SecItemCopyMatching((__bridge CFDictionaryRef)query, &result) == errSecSuccess) {
		for (NSDictionary *item in (__bridge_transfer NSArray *)result) {
			NSString *account = item[(__bridge id)kSecAttrAccount];
			if (account) {
				key_list.append(String([account UTF8String]));
			}
		}
	}
	return key_list;
}

void OAuth2Plugin::save_token(String key, String value) {
	NSString *nKey = [NSString stringWithUTF8String:key.utf8().get_data()];
	NSString *nValue = [NSString stringWithUTF8String:value.utf8().get_data()];
	NSData *data = [nValue dataUsingEncoding:NSUTF8StringEncoding];

	// Delete any pre-existing item first to avoid errSecDuplicateItem.
	NSDictionary *deleteQuery =
			@{ (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrAccount : nKey };
	SecItemDelete((__bridge CFDictionaryRef)deleteQuery);

	NSDictionary *addAttrs = @{
		(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
		(__bridge id)kSecAttrAccount : nKey,
		(__bridge id)kSecValueData : data,
		(__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleWhenUnlocked
	};
	SecItemAdd((__bridge CFDictionaryRef)addAttrs, nil);
}

String OAuth2Plugin::get_token(String key) {
	NSString *nKey = [NSString stringWithUTF8String:key.utf8().get_data()];

	NSDictionary *query = @{
		(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
		(__bridge id)kSecAttrAccount : nKey,
		(__bridge id)kSecReturnData : @YES,
		(__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitOne
	};

	CFTypeRef result = NULL;
	if (SecItemCopyMatching((__bridge CFDictionaryRef)query, &result) == errSecSuccess) {
		NSData *data = (__bridge_transfer NSData *)result;
		NSString *val = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		return String([val UTF8String]);
	}
	return String("");
}

void OAuth2Plugin::delete_token(String key) {
	NSString *nKey = [NSString stringWithUTF8String:key.utf8().get_data()];
	NSDictionary *query =
			@{ (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrAccount : nKey };
	SecItemDelete((__bridge CFDictionaryRef)query);
}

void OAuth2Plugin::cleanup_expired_tokens() {
	PackedStringArray keys = get_all_keys();
	long currentTime = (long)[[NSDate date] timeIntervalSince1970];

	for (int i = 0; i < keys.size(); i++) {
		if (!keys[i].ends_with(":expires_at")) {
			continue;
		}

		String val = get_token(keys[i]);
		if (val.to_int() >= currentTime) {
			continue;
		}

		int last_colon = keys[i].rfind(":");
		if (last_colon == -1) {
			continue;
		}

		String prefix = keys[i].substr(0, last_colon + 1);
		for (int j = 0; j < keys.size(); j++) {
			if (keys[j].begins_with(prefix)) {
				delete_token(keys[j]);
			}
		}
	}
}

// ═══════════════════════════════════════════════════════════════════════════
// Singleton lifecycle
// ═══════════════════════════════════════════════════════════════════════════

OAuth2Plugin *OAuth2Plugin::get_singleton() {
	return instance;
}

OAuth2Plugin::OAuth2Plugin() {
	instance = this;
	cleanup_expired_tokens();
}

OAuth2Plugin::~OAuth2Plugin() {
	// Cancel any in-flight ASWebAuthenticationSession to prevent the completion
	// block from invoking emit_signal on a destroyed object.
	if (@available(iOS 12.0, *)) {
		if (sAuthSession) {
			[sAuthSession cancel];
			sAuthSession = nil;
		}
	}
	if (instance == this) {
		instance = NULL;
	}
}
