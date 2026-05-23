//
// © 2025-present https://github.com/cengiz-pz
//

#import "oauth2_keychain_service.h"
#import "oauth2_logger.h"

// The service attribute scopes every item so that getAllKeys only returns items
// owned by this plugin, not every generic-password item on the device.
static NSString *const kOAuth2KeychainService = @"org.godotengine.plugin.oauth2";

// ---------------------------------------------------------------------------
#pragma mark - OAuth2SystemKeychainBackend  (production — real Security.framework)
// ---------------------------------------------------------------------------

@implementation OAuth2SystemKeychainBackend

- (OSStatus)addItem:(NSDictionary *)attrs {
	return SecItemAdd((__bridge CFDictionaryRef)attrs, nil);
}

- (OSStatus)copyMatching:(NSDictionary *)query result:(CFTypeRef _Nullable *)result {
	return SecItemCopyMatching((__bridge CFDictionaryRef)query, result);
}

- (OSStatus)deleteItem:(NSDictionary *)query {
	return SecItemDelete((__bridge CFDictionaryRef)query);
}

@end

// ---------------------------------------------------------------------------
#pragma mark - OAuth2KeychainService
// ---------------------------------------------------------------------------

@implementation OAuth2KeychainService {
	id<OAuth2KeychainBackend> _backend;
}

- (instancetype)init {
	return [self initWithBackend:[[OAuth2SystemKeychainBackend alloc] init]];
}

- (instancetype)initWithBackend:(id<OAuth2KeychainBackend>)backend {
	self = [super init];
	if (self) {
		_backend = backend;
	}
	return self;
}

// ---------------------------------------------------------------------------
#pragma mark - getAllKeys
// ---------------------------------------------------------------------------

- (NSArray<NSString *> *)getAllKeys {
	NSMutableArray<NSString *> *keyList = [NSMutableArray array];

	NSDictionary *query = @{
		(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
		(__bridge id)kSecAttrService : kOAuth2KeychainService,
		(__bridge id)kSecReturnAttributes : @YES,
		(__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitAll
	};

	CFTypeRef result = NULL;
	OSStatus status = [_backend copyMatching:query result:&result];

	if (status == errSecSuccess) {
		for (NSDictionary *item in (__bridge_transfer NSArray *)result) {
			NSString *account = item[(__bridge id)kSecAttrAccount];
			if (account) {
				[keyList addObject:account];
			}
		}
	} else if (status != errSecItemNotFound) {
		os_log_error(oauth2_log, "OAuth2KeychainService: getAllKeys failed with status %d", (int)status);
	}

	return [keyList copy];
}

// ---------------------------------------------------------------------------
#pragma mark - saveToken:forKey:
// ---------------------------------------------------------------------------

- (BOOL)saveToken:(NSString *)value forKey:(NSString *)key {
	NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
	if (!data) {
		os_log_error(oauth2_log, "OAuth2KeychainService: saveToken – could not encode value for key '%{public}@'", key);
		return NO;
	}

	// Delete any pre-existing entry so the add never hits errSecDuplicateItem.
	NSDictionary *deleteQuery = @{
		(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
		(__bridge id)kSecAttrService : kOAuth2KeychainService,
		(__bridge id)kSecAttrAccount : key
	};
	[_backend deleteItem:deleteQuery]; // ignore result — missing is fine

	NSDictionary *addAttrs = @{
		(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
		(__bridge id)kSecAttrService : kOAuth2KeychainService,
		(__bridge id)kSecAttrAccount : key,
		(__bridge id)kSecValueData : data,
		(__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleWhenUnlocked
	};

	OSStatus status = [_backend addItem:addAttrs];
	if (status != errSecSuccess) {
		os_log_error(oauth2_log, "OAuth2KeychainService: saveToken failed for key '%{public}@' with status %d", key,
				(int)status);
		return NO;
	}
	return YES;
}

// ---------------------------------------------------------------------------
#pragma mark - getTokenForKey:
// ---------------------------------------------------------------------------

- (nullable NSString *)getTokenForKey:(NSString *)key {
	NSDictionary *query = @{
		(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
		(__bridge id)kSecAttrService : kOAuth2KeychainService,
		(__bridge id)kSecAttrAccount : key,
		(__bridge id)kSecReturnData : @YES,
		(__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitOne
	};

	CFTypeRef result = NULL;
	OSStatus status = [_backend copyMatching:query result:&result];

	if (status == errSecSuccess) {
		NSData *data = (__bridge_transfer NSData *)result;
		return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	}

	if (status != errSecItemNotFound) {
		os_log_error(oauth2_log, "OAuth2KeychainService: getToken failed for key '%{public}@' with status %d", key,
				(int)status);
	}
	return nil;
}

// ---------------------------------------------------------------------------
#pragma mark - deleteTokenForKey:
// ---------------------------------------------------------------------------

- (BOOL)deleteTokenForKey:(NSString *)key {
	NSDictionary *query = @{
		(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
		(__bridge id)kSecAttrService : kOAuth2KeychainService,
		(__bridge id)kSecAttrAccount : key
	};

	OSStatus status = [_backend deleteItem:query];

	if (status == errSecSuccess || status == errSecItemNotFound) {
		return YES;
	}

	os_log_error(oauth2_log, "OAuth2KeychainService: deleteToken failed for key '%{public}@' with status %d", key,
			(int)status);
	return NO;
}

// ---------------------------------------------------------------------------
#pragma mark - cleanupExpiredTokens
// ---------------------------------------------------------------------------

- (void)cleanupExpiredTokens {
	NSArray<NSString *> *keys = [self getAllKeys];
	long currentTime = (long)[[NSDate date] timeIntervalSince1970];

	for (NSString *key in keys) {
		if (![key hasSuffix:@":expires_at"]) {
			continue;
		}

		NSString *expiresAtValue = [self getTokenForKey:key];
		if (!expiresAtValue) {
			continue;
		}

		long expiresAt = (long)[expiresAtValue longLongValue];
		if (expiresAt >= currentTime) {
			continue;
		}

		NSRange lastColon = [key rangeOfString:@":" options:NSBackwardsSearch];
		if (lastColon.location == NSNotFound) {
			continue;
		}

		NSString *prefix = [key substringToIndex:lastColon.location + 1];

		os_log_debug(oauth2_log, "OAuth2KeychainService: cleaning up expired token group '%{public}@'", prefix);

		for (NSString *candidate in keys) {
			if ([candidate hasPrefix:prefix]) {
				[self deleteTokenForKey:candidate];
			}
		}
	}
}

@end
