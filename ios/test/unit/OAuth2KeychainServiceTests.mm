//
// © 2026-present https://github.com/cengiz-pz
//

// XCTest suite for OAuth2KeychainService.
//
// Every test uses OAuth2InMemoryKeychainBackend injected via -initWithBackend:
// so that no Keychain daemon entitlement is required.  The in-memory backend
// faithfully reproduces the Security.framework status codes that
// OAuth2KeychainService branches on (errSecSuccess, errSecItemNotFound,
// errSecDuplicateItem), making all service logic fully exercisable.
//
// Isolation strategy
// ------------------
// Each test gets a freshly allocated service + backend pair in setUp, so every
// test starts from an empty store with zero shared state.  No UUID prefixes or
// tearDown cleanup are needed.
//

#import <XCTest/XCTest.h>

#import "oauth2_keychain_service.h"
#import "OAuth2InMemoryKeychainBackend.h"
#import "OAuthTokenFixture.h"

// ---------------------------------------------------------------------------
#pragma mark - Convenience category
// ---------------------------------------------------------------------------

@interface OAuth2KeychainService (TestHelpers)

/** Saves every key→value pair in @p group into the service. */
- (void)saveTokenGroup:(NSDictionary<NSString *, NSString *> *)group;

/** YES iff every key in @p group is absent from the service. */
- (BOOL)tokenGroupIsFullyDeleted:(NSDictionary<NSString *, NSString *> *)group;

/** YES iff every key in @p group is present with the expected value. */
- (BOOL)tokenGroupIsFullyPresent:(NSDictionary<NSString *, NSString *> *)group;

@end

@implementation OAuth2KeychainService (TestHelpers)

- (void)saveTokenGroup:(NSDictionary<NSString *, NSString *> *)group {
    [group enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *val, BOOL *stop) {
        [self saveToken:val forKey:key];
    }];
}

- (BOOL)tokenGroupIsFullyDeleted:(NSDictionary<NSString *, NSString *> *)group {
    for (NSString *key in group) {
        if ([self getTokenForKey:key] != nil) return NO;
    }
    return YES;
}

- (BOOL)tokenGroupIsFullyPresent:(NSDictionary<NSString *, NSString *> *)group {
    for (NSString *key in group) {
        if (![[self getTokenForKey:key] isEqualToString:group[key]]) return NO;
    }
    return YES;
}

@end

// ---------------------------------------------------------------------------
#pragma mark - Test class
// ---------------------------------------------------------------------------

@interface OAuth2KeychainServiceTests : XCTestCase
@property (nonatomic, strong) OAuth2InMemoryKeychainBackend *backend;
@property (nonatomic, strong) OAuth2KeychainService         *service;
@end

@implementation OAuth2KeychainServiceTests

// ---------------------------------------------------------------------------
#pragma mark - XCTestCase lifecycle
// ---------------------------------------------------------------------------

- (void)setUp {
    [super setUp];
    // Fresh backend + service for every test — no shared state whatsoever.
    self.backend = [[OAuth2InMemoryKeychainBackend alloc] init];
    self.service = [[OAuth2KeychainService alloc] initWithBackend:self.backend];
}

- (void)tearDown {
    self.service = nil;
    self.backend = nil;
    [super tearDown];
}

// ===========================================================================
#pragma mark - saveToken:forKey: / getTokenForKey:   (round-trip)
// ===========================================================================

- (void)testSaveAndGetToken_basicRoundTrip {
    [self.service saveToken:OAuthTokenFixture.sampleAccessToken forKey:@"access_token"];
    XCTAssertEqualObjects([self.service getTokenForKey:@"access_token"],
                          OAuthTokenFixture.sampleAccessToken);
}

- (void)testSaveToken_returnsYES_onSuccess {
    BOOL result = [self.service saveToken:@"value" forKey:@"k1"];
    XCTAssertTrue(result, @"-saveToken:forKey: must return YES on success");
}

- (void)testSaveToken_overwritesPreviousValue {
    [self.service saveToken:@"first"                          forKey:@"k"];
    [self.service saveToken:OAuthTokenFixture.sampleRefreshToken forKey:@"k"];
    XCTAssertEqualObjects([self.service getTokenForKey:@"k"], OAuthTokenFixture.sampleRefreshToken,
                          @"Second save must replace the first value");
}

- (void)testSaveToken_overwrite_storeCountRemainsOne {
    // Overwriting must replace — not accumulate — the entry.
    [self.service saveToken:@"v1" forKey:@"k"];
    [self.service saveToken:@"v2" forKey:@"k"];
    XCTAssertEqual(self.backend.count, (NSUInteger)1);
}

- (void)testSaveToken_idempotentForSameValue {
    NSString *value = OAuthTokenFixture.sampleAccessToken;
    [self.service saveToken:value forKey:@"k"];
    [self.service saveToken:value forKey:@"k"]; // identical second write
    XCTAssertEqualObjects([self.service getTokenForKey:@"k"], value);
}

- (void)testGetToken_nonExistentKey_returnsNil {
    XCTAssertNil([self.service getTokenForKey:@"ghost"]);
}

// ---------------------------------------------------------------------------
// Edge-case values
// ---------------------------------------------------------------------------

- (void)testSaveAndGetToken_emptyString {
    [self.service saveToken:@"" forKey:@"empty"];
    XCTAssertEqualObjects([self.service getTokenForKey:@"empty"], @"",
                          @"An empty string must survive a round-trip");
}

- (void)testSaveAndGetToken_unicodeValue {
    [self.service saveToken:OAuthTokenFixture.unicodeToken forKey:@"unicode"];
    XCTAssertEqualObjects([self.service getTokenForKey:@"unicode"],
                          OAuthTokenFixture.unicodeToken,
                          @"Unicode value must survive UTF-8 encode/decode");
}

- (void)testSaveAndGetToken_largeValue {
    [self.service saveToken:OAuthTokenFixture.longToken forKey:@"big"];
    NSString *retrieved = [self.service getTokenForKey:@"big"];
    XCTAssertEqual(retrieved.length, (NSUInteger)4096);
    XCTAssertEqualObjects(retrieved, OAuthTokenFixture.longToken);
}

- (void)testSaveAndGetToken_jwtAccessToken {
    [self.service saveToken:OAuthTokenFixture.sampleAccessToken forKey:@"jwt_access"];
    XCTAssertEqualObjects([self.service getTokenForKey:@"jwt_access"],
                          OAuthTokenFixture.sampleAccessToken);
}

- (void)testSaveAndGetToken_jwtIdToken {
    [self.service saveToken:OAuthTokenFixture.sampleIdToken forKey:@"jwt_id"];
    XCTAssertEqualObjects([self.service getTokenForKey:@"jwt_id"],
                          OAuthTokenFixture.sampleIdToken);
}

- (void)testMultipleDistinctKeys_doNotInterfere {
    [self.service saveToken:@"alpha" forKey:@"k1"];
    [self.service saveToken:@"beta"  forKey:@"k2"];
    [self.service saveToken:@"gamma" forKey:@"k3"];
    XCTAssertEqualObjects([self.service getTokenForKey:@"k1"], @"alpha");
    XCTAssertEqualObjects([self.service getTokenForKey:@"k2"], @"beta");
    XCTAssertEqualObjects([self.service getTokenForKey:@"k3"], @"gamma");
}

// ===========================================================================
#pragma mark - deleteTokenForKey:
// ===========================================================================

- (void)testDeleteToken_removesEntry {
    [self.service saveToken:OAuthTokenFixture.sampleRefreshToken forKey:@"refresh"];
    XCTAssertTrue([self.service deleteTokenForKey:@"refresh"]);
    XCTAssertNil([self.service getTokenForKey:@"refresh"],
                 @"Token must be absent after deletion");
}

- (void)testDeleteToken_returnsYES_forAbsentKey {
    // Store is empty; delete must return YES (errSecItemNotFound → success).
    BOOL result = [self.service deleteTokenForKey:@"never_existed"];
    XCTAssertTrue(result,
                  @"Deleting an absent key must return YES (errSecItemNotFound is a success condition)");
}

- (void)testDeleteToken_doesNotThrow_forAbsentKey {
    XCTAssertNoThrow([self.service deleteTokenForKey:@"safe_delete"]);
}

- (void)testDeleteToken_isIdempotent {
    [self.service saveToken:@"value" forKey:@"k"];
    XCTAssertTrue([self.service deleteTokenForKey:@"k"]);  // removes item
    XCTAssertTrue([self.service deleteTokenForKey:@"k"]);  // already gone — still YES
}

- (void)testDeleteToken_doesNotRemoveSiblingKey {
    [self.service saveToken:@"value_a" forKey:@"sibling_a"];
    [self.service saveToken:@"value_b" forKey:@"sibling_b"];
    [self.service deleteTokenForKey:@"sibling_a"];
    XCTAssertNil([self.service getTokenForKey:@"sibling_a"], @"Deleted key must be absent");
    XCTAssertEqualObjects([self.service getTokenForKey:@"sibling_b"], @"value_b",
                          @"Sibling key must be unaffected");
}

- (void)testDeleteToken_reducesBackendCount {
    [self.service saveToken:@"v1" forKey:@"k1"];
    [self.service saveToken:@"v2" forKey:@"k2"];
    [self.service deleteTokenForKey:@"k1"];
    XCTAssertEqual(self.backend.count, (NSUInteger)1);
}

// ===========================================================================
#pragma mark - getAllKeys
// ===========================================================================

- (void)testGetAllKeys_emptyStore_returnsEmptyArray {
    NSArray<NSString *> *keys = [self.service getAllKeys];
    XCTAssertNotNil(keys);
    XCTAssertEqual(keys.count, (NSUInteger)0);
}

- (void)testGetAllKeys_includesSavedKey {
    [self.service saveToken:@"value" forKey:@"listed_key"];
    XCTAssertTrue([[self.service getAllKeys] containsObject:@"listed_key"]);
}

- (void)testGetAllKeys_excludesDeletedKey {
    [self.service saveToken:@"value" forKey:@"deleted_key"];
    [self.service deleteTokenForKey:@"deleted_key"];
    XCTAssertFalse([[self.service getAllKeys] containsObject:@"deleted_key"]);
}

- (void)testGetAllKeys_countMatchesInserts {
    [self.service saveToken:@"v1" forKey:@"k1"];
    [self.service saveToken:@"v2" forKey:@"k2"];
    [self.service saveToken:@"v3" forKey:@"k3"];
    XCTAssertEqual([self.service getAllKeys].count, (NSUInteger)3);
}

- (void)testGetAllKeys_includesAllMembersOfGroup {
    NSDictionary *group = [OAuthTokenFixture validTokenGroupWithPrefix:@"google:user1:"];
    [self.service saveTokenGroup:group];
    NSArray<NSString *> *keys = [self.service getAllKeys];
    for (NSString *k in group) {
        XCTAssertTrue([keys containsObject:k], @"getAllKeys must list '%@'", k);
    }
}

- (void)testGetAllKeys_doesNotDuplicate_afterOverwrite {
    [self.service saveToken:@"v1" forKey:@"k"];
    [self.service saveToken:@"v2" forKey:@"k"]; // overwrite

    NSArray<NSString *> *keys = [self.service getAllKeys];
    NSUInteger count = 0;
    for (NSString *k in keys) { if ([k isEqualToString:@"k"]) count++; }
    XCTAssertEqual(count, (NSUInteger)1,
                   @"A key must appear exactly once even after overwrite");
}

// ===========================================================================
#pragma mark - cleanupExpiredTokens
// ===========================================================================

- (void)testCleanupExpiredTokens_removesExpiredGroup {
    NSDictionary *group = [OAuthTokenFixture expiredTokenGroupWithPrefix:@"google:expired:"];
    [self.service saveTokenGroup:group];
    [self.service cleanupExpiredTokens];
    XCTAssertTrue([self.service tokenGroupIsFullyDeleted:group],
                  @"All keys in an expired group must be removed");
}

- (void)testCleanupExpiredTokens_preservesValidGroup {
    NSDictionary *group = [OAuthTokenFixture validTokenGroupWithPrefix:@"google:valid:"];
    [self.service saveTokenGroup:group];
    [self.service cleanupExpiredTokens];
    XCTAssertTrue([self.service tokenGroupIsFullyPresent:group],
                  @"All keys in a valid group must be preserved");
}

- (void)testCleanupExpiredTokens_mixedGroups_onlyRemovesExpired {
    NSDictionary *expiredGroup = [OAuthTokenFixture expiredTokenGroupWithPrefix:@"google:exp:"];
    NSDictionary *validGroup   = [OAuthTokenFixture validTokenGroupWithPrefix:@"google:val:"];
    [self.service saveTokenGroup:expiredGroup];
    [self.service saveTokenGroup:validGroup];

    [self.service cleanupExpiredTokens];

    XCTAssertTrue([self.service tokenGroupIsFullyDeleted:expiredGroup],
                  @"Expired group must be completely removed");
    XCTAssertTrue([self.service tokenGroupIsFullyPresent:validGroup],
                  @"Valid group must be completely preserved");
}

- (void)testCleanupExpiredTokens_noExpiresAtKey_leavesTokenIntact {
    // A token without any companion :expires_at key must never be removed.
    [self.service saveToken:OAuthTokenFixture.sampleAccessToken forKey:@"no_expiry:access_token"];
    [self.service cleanupExpiredTokens];
    XCTAssertEqualObjects([self.service getTokenForKey:@"no_expiry:access_token"],
                          OAuthTokenFixture.sampleAccessToken,
                          @"Token without :expires_at sibling must survive cleanup");
}

- (void)testCleanupExpiredTokens_isIdempotent {
    NSDictionary *group = [OAuthTokenFixture expiredTokenGroupWithPrefix:@"google:idem:"];
    [self.service saveTokenGroup:group];
    [self.service cleanupExpiredTokens];
    XCTAssertNoThrow([self.service cleanupExpiredTokens],
                     @"Second cleanup on an already-empty store must not throw");
    XCTAssertTrue([self.service tokenGroupIsFullyDeleted:group]);
}

- (void)testCleanupExpiredTokens_onlyExpiresAtKey_removesItself {
    // An :expires_at entry with no siblings should remove itself and not crash.
    NSString *key = @"loner:expires_at";
    [self.service saveToken:OAuthTokenFixture.pastExpiresAtString forKey:key];
    [self.service cleanupExpiredTokens];
    XCTAssertNil([self.service getTokenForKey:key],
                 @"A lone :expires_at key must remove itself on cleanup");
}

- (void)testCleanupExpiredTokens_multipleExpiredGroups_allRemoved {
    NSDictionary *g1 = [OAuthTokenFixture expiredTokenGroupWithPrefix:@"p:a:"];
    NSDictionary *g2 = [OAuthTokenFixture expiredTokenGroupWithPrefix:@"p:b:"];
    NSDictionary *g3 = [OAuthTokenFixture expiredTokenGroupWithPrefix:@"p:c:"];
    [self.service saveTokenGroup:g1];
    [self.service saveTokenGroup:g2];
    [self.service saveTokenGroup:g3];

    [self.service cleanupExpiredTokens];

    XCTAssertTrue([self.service tokenGroupIsFullyDeleted:g1]);
    XCTAssertTrue([self.service tokenGroupIsFullyDeleted:g2]);
    XCTAssertTrue([self.service tokenGroupIsFullyDeleted:g3]);
}

- (void)testCleanupExpiredTokens_doesNotRemoveGroupExpiringInFuture {
    // expires_at = now + 2 s — unambiguously in the future regardless of
    // when within the current second the test runs.
    NSString *prefix     = @"boundary:";
    NSString *expiresKey = [prefix stringByAppendingString:OAuthTokenFixture.expiresAtSegment];
    NSString *tokenKey   = [prefix stringByAppendingString:OAuthTokenFixture.accessTokenSegment];

    long nearFuture = (long)[[NSDate date] timeIntervalSince1970] + 2;
    [self.service saveToken:[NSString stringWithFormat:@"%ld", nearFuture] forKey:expiresKey];
    [self.service saveToken:OAuthTokenFixture.sampleAccessToken           forKey:tokenKey];

    [self.service cleanupExpiredTokens];

    XCTAssertNotNil([self.service getTokenForKey:tokenKey],
                    @"A token expiring in the future must not be removed");
}

- (void)testCleanupExpiredTokens_storeIsEmptyAfterward_forAllExpired {
    NSDictionary *group = [OAuthTokenFixture expiredTokenGroupWithPrefix:@"full:"];
    [self.service saveTokenGroup:group];
    [self.service cleanupExpiredTokens];
    XCTAssertEqual(self.backend.count, (NSUInteger)0,
                   @"Backend must be completely empty after all expired tokens are cleaned up");
}

// ===========================================================================
#pragma mark - Integration: full token lifecycle
// ===========================================================================

- (void)testFullLifecycle_saveRetrieveDelete {
    NSDictionary *group = [OAuthTokenFixture validTokenGroupWithPrefix:@"google:user1:"];

    // 1. Save all tokens.
    [self.service saveTokenGroup:group];

    // 2. Every token is readable.
    XCTAssertTrue([self.service tokenGroupIsFullyPresent:group]);

    // 3. getAllKeys lists all of them.
    NSArray<NSString *> *allKeys = [self.service getAllKeys];
    for (NSString *k in group) {
        XCTAssertTrue([allKeys containsObject:k], @"getAllKeys must list '%@'", k);
    }

    // 4. Delete each token individually.
    for (NSString *k in group) {
        XCTAssertTrue([self.service deleteTokenForKey:k]);
    }

    // 5. None remain.
    XCTAssertTrue([self.service tokenGroupIsFullyDeleted:group]);
    XCTAssertEqual(self.backend.count, (NSUInteger)0);
}

- (void)testFullLifecycle_expiredGroupCleanedOnCleanup {
    // Mirrors what the plugin constructor does: store an expired group, then
    // call cleanupExpiredTokens (which OAuth2Plugin::OAuth2Plugin() invokes).
    NSDictionary *group = [OAuthTokenFixture expiredTokenGroupWithPrefix:@"google:old:"];
    [self.service saveTokenGroup:group];
    [self.service cleanupExpiredTokens];
    XCTAssertTrue([self.service tokenGroupIsFullyDeleted:group],
                  @"Plugin-constructor cleanup must remove expired tokens on startup");
}

- (void)testFullLifecycle_refreshTokenAfterExpiry {
    // Simulate a token refresh: expired group is cleaned up, new group is saved.
    NSDictionary *oldGroup = [OAuthTokenFixture expiredTokenGroupWithPrefix:@"google:u:"];
    NSDictionary *newGroup = [OAuthTokenFixture validTokenGroupWithPrefix:@"google:u:"];

    [self.service saveTokenGroup:oldGroup];
    [self.service cleanupExpiredTokens]; // purge old
    [self.service saveTokenGroup:newGroup]; // write refreshed tokens

    XCTAssertTrue([self.service tokenGroupIsFullyPresent:newGroup],
                  @"Refreshed tokens must be fully readable after cleanup");
}

@end
