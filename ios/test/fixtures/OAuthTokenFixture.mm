//
// © 2025-present https://github.com/cengiz-pz
//

#import "OAuthTokenFixture.h"

// ---------------------------------------------------------------------------
// A 4 096-character filler built once at load time.
// ---------------------------------------------------------------------------
static NSString *sLongToken = nil;

__attribute__((constructor))
static void buildLongToken(void) {
    NSMutableString *buf = [NSMutableString stringWithCapacity:4096];
    NSString *chunk = @"abcdefghijklmnopqrstuvwxyz0123456789";
    while (buf.length < 4096) {
        [buf appendString:chunk];
    }
    sLongToken = [[buf substringToIndex:4096] copy];
}

// ---------------------------------------------------------------------------

@implementation OAuthTokenFixture

// ---------------------------------------------------------------------------
#pragma mark - Token values
// ---------------------------------------------------------------------------

+ (NSString *)sampleAccessToken {
    // Realistic three-part JWT structure; payload/signature are fictional.
    return @"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6InRlc3Qta2V5LTEifQ"
            ".eyJzdWIiOiJ1c2VyX3Rlc3QxMjMiLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJpYXQiOjE2MDAwMDAwMDB9"
            ".FAKE_SIGNATURE_FOR_TESTING_ONLY";
}

+ (NSString *)sampleRefreshToken {
    // Google-style opaque refresh token.
    return @"1//0gFAKE_REFRESH_TOKEN-L9IrI8zn_TESTING_ONLY_QSuOW_jklmnop";
}

+ (NSString *)sampleIdToken {
    return @"eyJhbGciOiJSUzI1NiIsImtpZCI6InRlc3Qta2V5LTIifQ"
            ".eyJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20iLCJzdWIiOiJ1c2VyX3Rlc3QxMjMifQ"
            ".FAKE_ID_TOKEN_SIGNATURE";
}

+ (NSString *)unicodeToken {
    return @"тест_токен_😀🔐✅_日本語テスト_emoji_test";
}

+ (NSString *)longToken {
    return sLongToken;
}

// ---------------------------------------------------------------------------
#pragma mark - Key name segments
// ---------------------------------------------------------------------------

+ (NSString *)accessTokenSegment  { return @"access_token"; }
+ (NSString *)refreshTokenSegment { return @"refresh_token"; }
+ (NSString *)idTokenSegment      { return @"id_token"; }
+ (NSString *)expiresAtSegment    { return @"expires_at"; }

// ---------------------------------------------------------------------------
#pragma mark - Prefixed keys
// ---------------------------------------------------------------------------

+ (NSString *)googleTokenGroupPrefix { return @"google:user_test123:"; }

+ (NSString *)googleAccessTokenKey  {
    return [self.googleTokenGroupPrefix stringByAppendingString:self.accessTokenSegment];
}
+ (NSString *)googleRefreshTokenKey {
    return [self.googleTokenGroupPrefix stringByAppendingString:self.refreshTokenSegment];
}
+ (NSString *)googleIdTokenKey {
    return [self.googleTokenGroupPrefix stringByAppendingString:self.idTokenSegment];
}
+ (NSString *)googleExpiresAtKey {
    return [self.googleTokenGroupPrefix stringByAppendingString:self.expiresAtSegment];
}

// ---------------------------------------------------------------------------
#pragma mark - Expiry helpers
// ---------------------------------------------------------------------------

+ (long)futureExpiresAt {
    return (long)[[NSDate date] timeIntervalSince1970] + 3600; // 1 h from now
}

+ (long)pastExpiresAt {
    return (long)[[NSDate date] timeIntervalSince1970] - 3600; // 1 h ago
}

+ (NSString *)futureExpiresAtString {
    return [NSString stringWithFormat:@"%ld", [self futureExpiresAt]];
}

+ (NSString *)pastExpiresAtString {
    return [NSString stringWithFormat:@"%ld", [self pastExpiresAt]];
}

// ---------------------------------------------------------------------------
#pragma mark - Composite helpers
// ---------------------------------------------------------------------------

+ (NSDictionary<NSString *, NSString *> *)validTokenGroupWithPrefix:(NSString *)prefix {
    return @{
        [prefix stringByAppendingString:self.accessTokenSegment]  : self.sampleAccessToken,
        [prefix stringByAppendingString:self.refreshTokenSegment] : self.sampleRefreshToken,
        [prefix stringByAppendingString:self.idTokenSegment]      : self.sampleIdToken,
        [prefix stringByAppendingString:self.expiresAtSegment]    : self.futureExpiresAtString,
    };
}

+ (NSDictionary<NSString *, NSString *> *)expiredTokenGroupWithPrefix:(NSString *)prefix {
    return @{
        [prefix stringByAppendingString:self.accessTokenSegment]  : self.sampleAccessToken,
        [prefix stringByAppendingString:self.refreshTokenSegment] : self.sampleRefreshToken,
        [prefix stringByAppendingString:self.idTokenSegment]      : self.sampleIdToken,
        [prefix stringByAppendingString:self.expiresAtSegment]    : self.pastExpiresAtString,
    };
}

@end
