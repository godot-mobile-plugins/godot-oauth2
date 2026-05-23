//
// © 2025-present https://github.com/cengiz-pz
//

#ifndef oauth2_keychain_service_h
#define oauth2_keychain_service_h

#import <Foundation/Foundation.h>
#import <Security/Security.h>

NS_ASSUME_NONNULL_BEGIN

// ---------------------------------------------------------------------------
#pragma mark - OAuth2KeychainBackend protocol
// ---------------------------------------------------------------------------

/**
 * Abstracts the three Security-framework calls used by OAuth2KeychainService.
 *
 * Production code uses OAuth2SystemKeychainBackend (the real Security.framework).
 * The XCTest target injects OAuth2InMemoryKeychainBackend, an in-process fake
 * that bypasses the Keychain daemon entirely — no entitlements required.
 */
@protocol OAuth2KeychainBackend <NSObject>

/**
 * Corresponds to SecItemAdd. Caller has already deleted any pre-existing item,
 * so this is always a fresh insert.
 */
- (OSStatus)addItem:(NSDictionary *)attrs;

/**
 * Corresponds to SecItemCopyMatching.
 * @p result is set on errSecSuccess; untouched otherwise.
 */
- (OSStatus)copyMatching:(NSDictionary *)query result:(CFTypeRef _Nullable *_Nullable)result;

/**
 * Corresponds to SecItemDelete.
 * Must return errSecItemNotFound (not an error) when the item is absent.
 */
- (OSStatus)deleteItem:(NSDictionary *)query;

@end

// ---------------------------------------------------------------------------
#pragma mark - System (production) backend
// ---------------------------------------------------------------------------

/**
 * Thin pass-through to the real Security.framework.
 * This is the default backend used by -[OAuth2KeychainService init].
 */
@interface OAuth2SystemKeychainBackend : NSObject <OAuth2KeychainBackend>
@end

// ---------------------------------------------------------------------------
#pragma mark - OAuth2KeychainService
// ---------------------------------------------------------------------------

/**
 * Encapsulates all keychain operations performed by the OAuth2 Godot plugin.
 *
 * Keeping this logic in a plain ObjC class with no Godot-type dependencies lets
 * the XCTest target instantiate and exercise it directly without a live engine.
 * Injecting a backend via -initWithBackend: lets tests run without any Keychain
 * daemon entitlement.
 */
@interface OAuth2KeychainService : NSObject

/** Uses the real Security.framework backend. Suitable for production. */
- (instancetype)init;

/**
 * Designated initialiser for testing.
 * Pass an OAuth2InMemoryKeychainBackend (or any mock) to avoid the Keychain daemon.
 */
- (instancetype)initWithBackend:(id<OAuth2KeychainBackend>)backend NS_DESIGNATED_INITIALIZER;

/** Returns every kSecAttrAccount value stored under kSecClassGenericPassword. */
- (NSArray<NSString *> *)getAllKeys;

/**
 * Persists @p value in the Keychain under @p key, overwriting any existing entry.
 * @return YES on success, NO on failure.
 */
- (BOOL)saveToken:(NSString *)value forKey:(NSString *)key;

/**
 * Retrieves the value stored under @p key.
 * @return The stored string, or nil if the key does not exist.
 */
- (nullable NSString *)getTokenForKey:(NSString *)key;

/**
 * Deletes the entry for @p key.
 * @return YES on success OR when the key was already absent.
 */
- (BOOL)deleteTokenForKey:(NSString *)key;

/**
 * Scans all stored keys for entries ending in ":expires_at" whose timestamp is
 * in the past, then deletes every sibling key sharing the same prefix.
 */
- (void)cleanupExpiredTokens;

@end

NS_ASSUME_NONNULL_END

#endif /* oauth2_keychain_service_h */
