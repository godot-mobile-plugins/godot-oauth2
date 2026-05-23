//
// © 2025-present https://github.com/cengiz-pz
//

#ifndef OAuth2InMemoryKeychainBackend_h
#define OAuth2InMemoryKeychainBackend_h

#import "oauth2_keychain_service.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * An in-process, in-memory fake that satisfies OAuth2KeychainBackend without
 * touching the Keychain daemon.
 *
 * Why this exists
 * ---------------
 * iOS XCTest bundles that run without a host application receive
 * errSecMissingEntitlement (-34018) for every Security.framework call,
 * regardless of what query attributes are supplied.  This backend sidesteps
 * that restriction entirely: all data lives in an NSMutableDictionary for the
 * lifetime of the test process.
 *
 * Fidelity
 * --------
 * The fake honours the same subset of query keys that OAuth2KeychainService
 * actually uses:
 *   kSecAttrAccount        — item identity (primary key)
 *   kSecAttrService        — accepted but not used for scoping (single service)
 *   kSecValueData          — raw bytes stored / returned
 *   kSecReturnData         — controls whether value bytes are returned
 *   kSecReturnAttributes   — controls whether attribute dictionaries are returned
 *   kSecMatchLimit         — kSecMatchLimitOne vs kSecMatchLimitAll
 *
 * Any key not in that set is silently ignored, matching Security.framework
 * behaviour for unknown attributes.
 *
 * Thread safety
 * -------------
 * Not thread-safe; XCTest runs each test method serially on the main thread
 * so no locking is required.
 */
@interface OAuth2InMemoryKeychainBackend : NSObject <OAuth2KeychainBackend>

/** Removes all stored items. Useful for resetting between tests if needed. */
- (void)reset;

/** Number of items currently stored. Useful for count assertions in tests. */
@property(nonatomic, readonly) NSUInteger count;

@end

NS_ASSUME_NONNULL_END

#endif /* OAuth2InMemoryKeychainBackend_h */
