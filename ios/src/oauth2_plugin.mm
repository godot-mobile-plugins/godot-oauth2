//
// © 2025-present https://github.com/cengiz-pz
//

#import "oauth2_plugin.h"

#import <Foundation/Foundation.h>
#import <Security/Security.h>


OAuth2Plugin* OAuth2Plugin::instance = NULL;

void OAuth2Plugin::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_all_keys"), &OAuth2Plugin::get_all_keys);
	ClassDB::bind_method(D_METHOD("save_token", "key", "value"), &OAuth2Plugin::save_token);
	ClassDB::bind_method(D_METHOD("get_token", "key"), &OAuth2Plugin::get_token);
	ClassDB::bind_method(D_METHOD("delete_token", "key"), &OAuth2Plugin::delete_token);
}

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
			if (account) key_list.append(String([account UTF8String]));
		}
	}
	return key_list;
}

void OAuth2Plugin::save_token(String key, String value) {
	NSString *nKey = [NSString stringWithUTF8String:key.utf8().get_data()];
	NSString *nValue = [NSString stringWithUTF8String:value.utf8().get_data()];
	NSData *data = [nValue dataUsingEncoding:NSUTF8StringEncoding];

	NSDictionary *query = @{
		(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
		(__bridge id)kSecAttrAccount : nKey,
		(__bridge id)kSecValueData : data
	};

	SecItemDelete((__bridge CFDictionaryRef)query); // Delete existing
	SecItemAdd((__bridge CFDictionaryRef)query, nil);
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
	OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);

	if (status == errSecSuccess) {
		NSData *data = (__bridge_transfer NSData *)result;
		NSString *val = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		return String([val UTF8String]);
	}
	return String("");
}

void OAuth2Plugin::delete_token(String key) {
	NSString *nKey = [NSString stringWithUTF8String:key.utf8().get_data()];
	NSDictionary *query = @{
		(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
		(__bridge id)kSecAttrAccount : nKey
	};
	SecItemDelete((__bridge CFDictionaryRef)query);
}

void OAuth2Plugin::cleanup_expired_tokens() {
	PackedStringArray keys = get_all_keys();
	long currentTime = [[NSDate date] timeIntervalSince1970];
	for (int i = 0; i < keys.size(); i++) {
		if (keys[i].ends_with(":expires_at")) {
			String val = get_token(keys[i]);
			if (val.to_int() < currentTime) {
				// Use rfind() instead of find_last()
				int last_colon_pos = keys[i].rfind(":"); 
				if (last_colon_pos != -1) {
					String prefix = keys[i].substr(0, last_colon_pos + 1);
					for (int j = 0; j < keys.size(); j++) {
						if (keys[j].begins_with(prefix)) {
							delete_token(keys[j]);
						}
					}
				}
			}
		}
	}
}

OAuth2Plugin *OAuth2Plugin::get_singleton() {
	return instance;
}

OAuth2Plugin::OAuth2Plugin() {
	instance = this;
	cleanup_expired_tokens();
}

OAuth2Plugin::~OAuth2Plugin() {
	if (instance == this) {
		instance = NULL;
	}
}
