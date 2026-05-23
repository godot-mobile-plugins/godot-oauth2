//
// © 2025-present https://github.com/cengiz-pz
//

#import "OAuth2InMemoryKeychainBackend.h"

@implementation OAuth2InMemoryKeychainBackend {
	// Primary store: account string → raw value bytes.
	NSMutableDictionary<NSString *, NSData *> *_store;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		_store = [NSMutableDictionary dictionary];
	}
	return self;
}

// ---------------------------------------------------------------------------
#pragma mark - OAuth2KeychainBackend
// ---------------------------------------------------------------------------

/**
 * Stores @c kSecValueData under @c kSecAttrAccount.
 *
 * The caller (OAuth2KeychainService) always issues a deleteItem: before addItem:,
 * so we never need to check for duplicates.  We return errSecDuplicateItem
 * defensively if somehow the same account arrives twice, matching the real
 * Security.framework behaviour when the prior delete was skipped.
 */
- (OSStatus)addItem:(NSDictionary *)attrs {
	NSString *account = attrs[(__bridge id)kSecAttrAccount];
	NSData *data = attrs[(__bridge id)kSecValueData];

	if (!account || !data) {
		return errSecParam;
	}

	if (_store[account]) {
		return errSecDuplicateItem;
	}

	_store[account] = [data copy];
	return errSecSuccess;
}

/**
 * Handles two query shapes that OAuth2KeychainService issues:
 *
 *  1. Single-item data fetch
 *       kSecAttrAccount = <key>
 *       kSecReturnData  = @YES
 *       kSecMatchLimit  = kSecMatchLimitOne
 *     → sets *result to CFDataRef of the stored value, or errSecItemNotFound
 *
 *  2. Full attribute listing
 *       kSecReturnAttributes = @YES
 *       kSecMatchLimit       = kSecMatchLimitAll
 *     → sets *result to CFArrayRef of dicts, each with kSecAttrAccount, or
 *       errSecItemNotFound when the store is empty
 */
- (OSStatus)copyMatching:(NSDictionary *)query result:(CFTypeRef _Nullable *)result {
	BOOL returnData = [query[(__bridge id)kSecReturnData] boolValue];
	BOOL returnAttributes = [query[(__bridge id)kSecReturnAttributes] boolValue];
	NSString *account = query[(__bridge id)kSecAttrAccount];

	// --- Shape 1: single-item data fetch ---
	if (returnData && account) {
		NSData *data = _store[account];
		if (!data) {
			return errSecItemNotFound;
		}
		if (result) {
			*result = (__bridge_retained CFTypeRef)[data copy];
		}
		return errSecSuccess;
	}

	// --- Shape 2: full attribute listing ---
	if (returnAttributes) {
		if (_store.count == 0) {
			return errSecItemNotFound;
		}
		NSMutableArray<NSDictionary *> *items = [NSMutableArray arrayWithCapacity:_store.count];
		for (NSString *key in _store) {
			[items addObject:@{ (__bridge id)kSecAttrAccount : key }];
		}
		if (result) {
			*result = (__bridge_retained CFTypeRef)[items copy];
		}
		return errSecSuccess;
	}

	return errSecItemNotFound;
}

/**
 * Removes the item identified by @c kSecAttrAccount.
 * Returns errSecItemNotFound when the account is absent — not an error from
 * the caller's perspective, matching Security.framework semantics.
 */
- (OSStatus)deleteItem:(NSDictionary *)query {
	NSString *account = query[(__bridge id)kSecAttrAccount];

	if (!account) {
		return errSecParam;
	}

	if (!_store[account]) {
		return errSecItemNotFound;
	}

	[_store removeObjectForKey:account];
	return errSecSuccess;
}

// ---------------------------------------------------------------------------
#pragma mark - Helpers
// ---------------------------------------------------------------------------

- (void)reset {
	[_store removeAllObjects];
}

- (NSUInteger)count {
	return _store.count;
}

@end
