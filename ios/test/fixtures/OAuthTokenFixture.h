//
// © 2025-present https://github.com/cengiz-pz
//

#ifndef OAuthTokenFixture_h
#define OAuthTokenFixture_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * OAuthTokenFixture provides canonical, reusable test data for the OAuth2 plugin
 * unit-test suite.  All values are realistic but completely fictional — they never
 * represent real credentials.
 *
 * Token values use a plausible JWT-like structure so serialisation round-trips
 * exercise the same code paths as production data.
 *
 * Key constants follow the same colon-delimited prefix scheme that the plugin
 * uses in production (e.g. "google:user_123:access_token"), which is what
 * cleanupExpiredTokens relies on.
 */
@interface OAuthTokenFixture : NSObject

// ---------------------------------------------------------------------------
#pragma mark - Token values
// ---------------------------------------------------------------------------

/** A plausible but fictional JWT access token (~200 chars). */
@property (class, nonatomic, readonly) NSString *sampleAccessToken;

/** A plausible refresh token in Google's opaque format. */
@property (class, nonatomic, readonly) NSString *sampleRefreshToken;

/** A plausible but fictional JWT id_token. */
@property (class, nonatomic, readonly) NSString *sampleIdToken;

/** An access token with Unicode characters to stress-test encoding. */
@property (class, nonatomic, readonly) NSString *unicodeToken;

/** A 4 096-character string that exercises large value storage. */
@property (class, nonatomic, readonly) NSString *longToken;

// ---------------------------------------------------------------------------
#pragma mark - Key name segments
// ---------------------------------------------------------------------------

/** Bare key segment for access tokens: @"access_token" */
@property (class, nonatomic, readonly) NSString *accessTokenSegment;

/** Bare key segment for refresh tokens: @"refresh_token" */
@property (class, nonatomic, readonly) NSString *refreshTokenSegment;

/** Bare key segment for id tokens: @"id_token" */
@property (class, nonatomic, readonly) NSString *idTokenSegment;

/**
 * Bare key segment for expiry timestamps: @"expires_at"
 * Must end with exactly this string for cleanupExpiredTokens to recognise it.
 */
@property (class, nonatomic, readonly) NSString *expiresAtSegment;

// ---------------------------------------------------------------------------
#pragma mark - Prefixed keys (provider:user:<segment>)
// ---------------------------------------------------------------------------

/** @"google:user_test123:access_token" */
@property (class, nonatomic, readonly) NSString *googleAccessTokenKey;

/** @"google:user_test123:refresh_token" */
@property (class, nonatomic, readonly) NSString *googleRefreshTokenKey;

/** @"google:user_test123:id_token" */
@property (class, nonatomic, readonly) NSString *googleIdTokenKey;

/** @"google:user_test123:expires_at" */
@property (class, nonatomic, readonly) NSString *googleExpiresAtKey;

/** The shared colon-terminated prefix for the google:user_test123 group. */
@property (class, nonatomic, readonly) NSString *googleTokenGroupPrefix;

// ---------------------------------------------------------------------------
#pragma mark - Expiry helpers
// ---------------------------------------------------------------------------

/**
 * Unix timestamp one hour in the future.
 * Tokens with this value should survive cleanupExpiredTokens.
 */
+ (long)futureExpiresAt;

/**
 * Unix timestamp one hour in the past.
 * Tokens with this value should be removed by cleanupExpiredTokens.
 */
+ (long)pastExpiresAt;

/** String representation of +futureExpiresAt suitable for storing in the Keychain. */
+ (NSString *)futureExpiresAtString;

/** String representation of +pastExpiresAt suitable for storing in the Keychain. */
+ (NSString *)pastExpiresAtString;

// ---------------------------------------------------------------------------
#pragma mark - Composite helpers
// ---------------------------------------------------------------------------

/**
 * Returns a dictionary representing one complete, still-valid token group:
 *   key → value pairs ready to be written with -[OAuth2KeychainService saveToken:forKey:].
 *
 * Keys use the supplied @p prefix, e.g. @"google:user_test123:".
 */
+ (NSDictionary<NSString *, NSString *> *)validTokenGroupWithPrefix:(NSString *)prefix;

/**
 * Returns a dictionary representing one complete, expired token group.
 * Keys use the supplied @p prefix.
 */
+ (NSDictionary<NSString *, NSString *> *)expiredTokenGroupWithPrefix:(NSString *)prefix;

@end

NS_ASSUME_NONNULL_END

#endif /* OAuthTokenFixture_h */
