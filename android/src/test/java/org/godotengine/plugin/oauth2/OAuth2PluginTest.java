//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.oauth2;

import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;

import org.godotengine.godot.Godot;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.quality.Strictness;
import org.mockito.junit.jupiter.MockitoSettings;

import java.nio.charset.StandardCharsets;
import java.security.KeyStore;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import javax.crypto.Cipher;
import javax.crypto.SecretKey;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.clearInvocations;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for {@link OAuth2Plugin}.
 *
 * <h3>Architecture notes</h3>
 * <ul>
 *   <li>{@code cleanup_expired_tokens()} is called inside the constructor via {@code super()},
 *       so {@link TestableOAuth2Plugin} overrides {@code getActivity()} using a {@code static}
 *       field ({@link #staticActivity}) that can be set <em>before</em> construction – Java's
 *       dynamic dispatch means the override fires even during the super-constructor call.</li>
 *   <li>Android-only statics ({@code android.util.Base64}, {@code android.util.Log},
 *       {@code KeyStore.getInstance("AndroidKeyStore")}) are replaced with
 *       {@link MockedStatic} instances that delegate to standard-JVM equivalents.</li>
 *   <li>A real 256-bit AES key is generated per test, allowing genuine AES/GCM
 *       encrypt-decrypt round-trips without the Android KeyStore provider.</li>
 * </ul>
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT) // setUp stubs are not used by every test
@DisplayName("OAuth2Plugin")
class OAuth2PluginTest {

	// -- Constants mirrored from the plugin (they are private there) -----------

	private static final String PREFS_NAME       = "oauth2_secure_store";
	private static final String KEY_ALIAS        = "oauth2_master_key";
	private static final String ANDROID_KS       = "AndroidKeyStore";
	private static final int    GCM_TAG_BITS     = 128;

	// -- Static activity holder – readable by the inner subclass via dynamic
	//    dispatch even while super() is still running. ------------------------
	private static Activity staticActivity;

	// -- Mocks injected by Mockito ---------------------------------------------

	@Mock private Godot                    mockGodot;
	@Mock private Activity                 mockActivity;
	@Mock private SharedPreferences        mockPrefs;
	@Mock private SharedPreferences.Editor mockEditor;

	// -- Test state -------------------------------------------------------------

	private OAuth2Plugin       plugin;
	private SecretKey          testKey;
	private KeyStore           mockKeyStore;

	private MockedStatic<KeyStore>            mockedKeyStore;
	private MockedStatic<android.util.Base64> mockedBase64;
	private MockedStatic<android.util.Log>    mockedLog;

	// ═════════════════════════════════════════════════════════════════════════
	// Inner test-double subclass
	// ═════════════════════════════════════════════════════════════════════════

	/**
	 * Overrides {@code getActivity()} so tests can control the returned value
	 * without depending on the real Godot/Android runtime. The override is
	 * picked up by the virtual dispatch table before {@code super()} returns,
	 * which means {@code cleanup_expired_tokens()} already sees our mock.
	 */
	static class TestableOAuth2Plugin extends OAuth2Plugin {
		TestableOAuth2Plugin(Godot godot) {
			super(godot);
		}

		@Override
		public Activity getActivity() {
			return staticActivity;
		}
	}

	// ═════════════════════════════════════════════════════════════════════════
	// Fixtures / helpers
	// ═════════════════════════════════════════════════════════════════════════

	/** Generates a real AES-256 key using the standard JVM provider. */
	private static SecretKey generateAesKey() throws Exception {
		javax.crypto.KeyGenerator kg = javax.crypto.KeyGenerator.getInstance("AES");
		kg.init(256);
		return kg.generateKey();
	}

	/**
	 * Encrypts {@code value} using the real AES/GCM key and formats the result
	 * in the same {@code "<iv-b64>:<ciphertext-b64>"} shape the plugin uses –
	 * but with {@code java.util.Base64} because {@code android.util.Base64} is
	 * mocked to delegate to it.
	 */
	private String encryptWithKey(String value) throws Exception {
		Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
		cipher.init(Cipher.ENCRYPT_MODE, testKey);
		byte[] iv         = cipher.getIV();
		byte[] cipherText = cipher.doFinal(value.getBytes(StandardCharsets.UTF_8));
		return java.util.Base64.getEncoder().encodeToString(iv)
				+ ":"
				+ java.util.Base64.getEncoder().encodeToString(cipherText);
	}

	// ═════════════════════════════════════════════════════════════════════════
	// Lifecycle
	// ═════════════════════════════════════════════════════════════════════════

	@BeforeEach
	void setUp() throws Exception {
		testKey        = generateAesKey();
		staticActivity = mockActivity;

		// -- 1. Silence android.util.Log --------------------------------------
		mockedLog = mockStatic(android.util.Log.class);

		// -- 2. Redirect android.util.Base64 → java.util.Base64 --------------
		mockedBase64 = mockStatic(android.util.Base64.class);

		mockedBase64.when(() -> android.util.Base64
						.encodeToString(any(byte[].class), anyInt()))
				.thenAnswer(inv ->
						java.util.Base64.getEncoder()
								.encodeToString(inv.getArgument(0)));

		mockedBase64.when(() -> android.util.Base64
						.decode(any(String.class), anyInt()))
				.thenAnswer(inv ->
						java.util.Base64.getDecoder()
								.decode((String) inv.getArgument(0)));

		// -- 3. Stub KeyStore to return our real AES key ----------------------
		mockKeyStore = mock(KeyStore.class);
		mockedKeyStore = mockStatic(KeyStore.class);

		mockedKeyStore.when(() -> KeyStore.getInstance(ANDROID_KS))
					.thenReturn(mockKeyStore);
		doNothing().when(mockKeyStore).load(null);
		when(mockKeyStore.containsAlias(KEY_ALIAS)).thenReturn(true);

		KeyStore.SecretKeyEntry mockEntry = mock(KeyStore.SecretKeyEntry.class);
		when(mockKeyStore.getEntry(KEY_ALIAS, null)).thenReturn(mockEntry);
		when(mockEntry.getSecretKey()).thenReturn(testKey);

		// -- 4. Wire up SharedPreferences chain ------------------------------
		when(mockActivity.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE))
				.thenReturn(mockPrefs);
		when(mockPrefs.getAll()).thenReturn(Collections.emptyMap());
		when(mockPrefs.getString(anyString(), isNull())).thenReturn(null);
		when(mockPrefs.edit()).thenReturn(mockEditor);
		lenient().when(mockEditor.putString(anyString(), anyString())).thenReturn(mockEditor);
		lenient().when(mockEditor.remove(anyString())).thenReturn(mockEditor);

		// -- 5. Instantiate the plugin under test -----------------------------
		plugin = new TestableOAuth2Plugin(mockGodot);
	}

	@AfterEach
	void tearDown() {
		if (mockedKeyStore != null) {
			mockedKeyStore.close();
		}
		if (mockedBase64  != null) {
			mockedBase64.close();
		}
		if (mockedLog     != null) {
			mockedLog.close();
		}
	}

	// ═════════════════════════════════════════════════════════════════════════
	// Test groups
	// ═════════════════════════════════════════════════════════════════════════

	// -------------------------------------------------------------------------
	@Nested
	@DisplayName("getPluginName()")
	class PluginNameTest {

		@Test
		@DisplayName("returns the simple class name")
		void returnsClassName() {
			assertEquals("OAuth2Plugin", plugin.getPluginName());
		}
	}

	// -------------------------------------------------------------------------
	@Nested
	@DisplayName("get_all_keys()")
	class GetAllKeysTest {

		@Test
		@DisplayName("returns empty array when activity is null")
		void returnsEmptyArray_whenActivityIsNull() {
			staticActivity = null;
			clearInvocations(mockPrefs);

			OAuth2Plugin nullPlugin = new TestableOAuth2Plugin(mockGodot);

			assertArrayEquals(new String[0], nullPlugin.get_all_keys());
			verify(mockPrefs, never()).getAll();
		}

		@Test
		@DisplayName("returns empty array when SharedPreferences has no entries")
		void returnsEmptyArray_whenPrefsEmpty() {
			when(mockPrefs.getAll()).thenReturn(Collections.emptyMap());

			assertArrayEquals(new String[0], plugin.get_all_keys());
		}

		@Test
		@DisplayName("returns all stored keys")
		void returnsAllStoredKeys() {
			Map<String, Object> stored = new LinkedHashMap<>();
			stored.put("session:GOOGLE:user1:access_token",  "enc1");
			stored.put("session:GOOGLE:user1:refresh_token", "enc2");
			stored.put("session:GOOGLE:user1:expires_at",    "enc3");
			Mockito.doReturn(stored).when(mockPrefs).getAll();

			String[] keys = plugin.get_all_keys();

			assertEquals(3, keys.length);
			assertTrue(Arrays.asList(keys).containsAll(stored.keySet()),
					"All stored keys must be returned");
		}
	}

	// -------------------------------------------------------------------------
	@Nested
	@DisplayName("save_token()")
	class SaveTokenTest {

		@Test
		@DisplayName("does nothing when activity is null")
		void doesNothing_whenActivityIsNull() {
			staticActivity = null;
			OAuth2Plugin nullPlugin = new TestableOAuth2Plugin(mockGodot);

			nullPlugin.save_token("anyKey", "anyValue");

			verify(mockPrefs, never()).edit();
		}

		@Test
		@DisplayName("stores an encrypted string under the provided key")
		void storesEncryptedValueUnderKey() {
			plugin.save_token("tokenKey", "secretValue");

			verify(mockEditor).putString(eq("tokenKey"), anyString());
			verify(mockEditor).apply();
		}

		@Test
		@DisplayName("stored value is not the plaintext original")
		void storedValueDiffersFromPlaintext() {
			ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);

			plugin.save_token("tokenKey", "secretValue");

			verify(mockEditor).putString(eq("tokenKey"), captor.capture());
			assertNotEquals("secretValue", captor.getValue(),
					"Plaintext must not be stored as-is");
		}

		@Test
		@DisplayName("encrypted output contains the IV:ciphertext delimiter")
		void storedValueContainsIvDelimiter() {
			ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);

			plugin.save_token("tokenKey", "secretValue");

			verify(mockEditor).putString(eq("tokenKey"), captor.capture());
			assertTrue(captor.getValue().contains(":"),
					"Stored format must be '<iv>:<ciphertext>'");
		}

		@Test
		@DisplayName("does not write to prefs when encryption returns null")
		void doesNotWritePrefs_whenEncryptionFails() throws Exception {
			// Force getSecretKey() to throw so encrypt() returns null
			when(mockKeyStore.getEntry(KEY_ALIAS, null))
					.thenThrow(new RuntimeException("KeyStore unavailable"));

			plugin.save_token("tokenKey", "secretValue");

			verify(mockEditor, never()).putString(anyString(), anyString());
		}
	}

	// -------------------------------------------------------------------------
	@Nested
	@DisplayName("get_token()")
	class GetTokenTest {

		@Test
		@DisplayName("returns empty string when activity is null")
		void returnsEmpty_whenActivityIsNull() {
			staticActivity = null;
			OAuth2Plugin nullPlugin = new TestableOAuth2Plugin(mockGodot);

			assertEquals("", nullPlugin.get_token("anyKey"));
		}

		@Test
		@DisplayName("returns empty string when key is absent from prefs")
		void returnsEmpty_whenKeyAbsent() {
			when(mockPrefs.getString("missingKey", null)).thenReturn(null);

			assertEquals("", plugin.get_token("missingKey"));
		}

		@Test
		@DisplayName("returns the decrypted plaintext for a known key")
		void returnsDecryptedPlaintext() throws Exception {
			String plaintext  = "my_access_token_abc123";
			String encrypted  = encryptWithKey(plaintext);
			when(mockPrefs.getString("accessToken", null)).thenReturn(encrypted);

			assertEquals(plaintext, plugin.get_token("accessToken"));
		}

		@Test
		@DisplayName("returns empty string when stored value is an empty string")
		void returnsEmpty_whenStoredValueIsEmpty() {
			when(mockPrefs.getString("emptyKey", null)).thenReturn("");

			assertEquals("", plugin.get_token("emptyKey"));
		}

		@Test
		@DisplayName("returns empty string when stored value has no colon separator")
		void returnsEmpty_whenNoColonInStoredValue() {
			// decrypt() guard: parts.length != 2
			when(mockPrefs.getString("badKey", null)).thenReturn("thereisnoseparatorhere");

			assertEquals("", plugin.get_token("badKey"));
		}

		@Test
		@DisplayName("returns empty string when stored value has extra colon segments")
		void returnsEmpty_whenTooManyColonSegments() {
			// Split would yield three parts, failing the length == 2 check
			when(mockPrefs.getString("badKey", null)).thenReturn("part1:part2:part3");

			assertEquals("", plugin.get_token("badKey"));
		}

		@Test
		@DisplayName("returns empty string when ciphertext cannot be decrypted")
		void returnsEmpty_whenDecryptionFails() {
			// Valid-looking format but ciphertext is garbage for the key
			when(mockPrefs.getString("corruptKey", null))
					.thenReturn("aGVsbG8=:d29ybGQ="); // real b64, wrong content

			assertEquals("", plugin.get_token("corruptKey"));
		}
	}

	// -------------------------------------------------------------------------
	@Nested
	@DisplayName("delete_token()")
	class DeleteTokenTest {

		@Test
		@DisplayName("does nothing when activity is null")
		void doesNothing_whenActivityIsNull() {
			staticActivity = null;
			OAuth2Plugin nullPlugin = new TestableOAuth2Plugin(mockGodot);

			nullPlugin.delete_token("anyKey");

			verify(mockPrefs, never()).edit();
		}

		@Test
		@DisplayName("removes the key from SharedPreferences")
		void removesKeyFromPrefs() {
			plugin.delete_token("tokenKey");

			verify(mockEditor).remove("tokenKey");
			verify(mockEditor).apply();
		}

		@Test
		@DisplayName("calls remove with the exact key provided")
		void removesExactKey() {
			ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);

			plugin.delete_token("session:GOOGLE:user1:access_token");

			verify(mockEditor).remove(captor.capture());
			assertEquals("session:GOOGLE:user1:access_token", captor.getValue());
		}
	}

	// -------------------------------------------------------------------------
	@Nested
	@DisplayName("save_token / get_token round-trip")
	class RoundTripTest {

		@Test
		@DisplayName("get_token returns the original value after save_token")
		void saveAndGet_returnsSameValue() throws Exception {
			String original = "super_secret_refresh_token_42";

			// Capture what was stored
			ArgumentCaptor<String> storedCaptor = ArgumentCaptor.forClass(String.class);
			plugin.save_token("rtKey", original);
			verify(mockEditor).putString(eq("rtKey"), storedCaptor.capture());

			// Feed the captured encrypted blob back into get_token
			when(mockPrefs.getString("rtKey", null)).thenReturn(storedCaptor.getValue());
			String retrieved = plugin.get_token("rtKey");

			assertEquals(original, retrieved,
					"Round-trip must reproduce the original plaintext");
		}

		@Test
		@DisplayName("different plaintext values produce different ciphertexts")
		void differentPlaintexts_produceDifferentCiphertexts() {
			ArgumentCaptor<String> captor1 = ArgumentCaptor.forClass(String.class);
			ArgumentCaptor<String> captor2 = ArgumentCaptor.forClass(String.class);

			plugin.save_token("key1", "tokenAlpha");
			verify(mockEditor).putString(eq("key1"), captor1.capture());

			plugin.save_token("key2", "tokenBeta");
			verify(mockEditor).putString(eq("key2"), captor2.capture());

			assertNotEquals(captor1.getValue(), captor2.getValue());
		}
	}

	// -------------------------------------------------------------------------
	@Nested
	@DisplayName("cleanup_expired_tokens() [called in constructor]")
	class CleanupExpiredTokensTest {

		/**
		 * Constructs a fresh plugin after overriding {@code mockPrefs.getAll()}
		 * with the supplied map.  setUp already built one plugin (with an empty
		 * map), so we reset the editor's invocation counts before each scenario
		 * to keep verify() calls unambiguous.
		 */
		private OAuth2Plugin buildPluginWithPrefs(Map<String, Object> prefs) {
			clearInvocations(mockEditor, mockPrefs);
			Mockito.doReturn(prefs).when(mockPrefs).getAll();
			return new TestableOAuth2Plugin(mockGodot);
		}

		@Test
		@DisplayName("skips cleanup entirely when activity is null")
		void skipsCleanup_whenActivityIsNull() {
			staticActivity = null;
			clearInvocations(mockPrefs);

			assertDoesNotThrow(() -> new TestableOAuth2Plugin(mockGodot));
			verify(mockPrefs, never()).getAll();
		}

		@Test
		@DisplayName("removes all keys belonging to an expired session")
		void removesAllKeysForExpiredSession() throws Exception {
			String prefix    = "session:GOOGLE:expiredUser:";
			String expiredTs = String.valueOf(System.currentTimeMillis() / 1000 - 3_600);

			Map<String, Object> prefs = new LinkedHashMap<>();
			prefs.put(prefix + "expires_at",    encryptWithKey(expiredTs));
			prefs.put(prefix + "access_token",  encryptWithKey("tok"));
			prefs.put(prefix + "refresh_token", encryptWithKey("ref"));

			buildPluginWithPrefs(prefs);

			verify(mockEditor).remove(prefix + "expires_at");
			verify(mockEditor).remove(prefix + "access_token");
			verify(mockEditor).remove(prefix + "refresh_token");
			verify(mockEditor, atLeastOnce()).apply();
		}

		@Test
		@DisplayName("does not remove keys for a session that has not yet expired")
		void keepsKeysForValidSession() throws Exception {
			String prefix   = "session:GOOGLE:validUser:";
			String futureTs = String.valueOf(System.currentTimeMillis() / 1000 + 3_600);

			Map<String, Object> prefs = new LinkedHashMap<>();
			prefs.put(prefix + "expires_at",   encryptWithKey(futureTs));
			prefs.put(prefix + "access_token", encryptWithKey("validTok"));

			buildPluginWithPrefs(prefs);

			verify(mockEditor, never()).remove(anyString());
			verify(mockEditor, never()).apply();
		}

		@Test
		@DisplayName("ignores entries whose key does not end with ':expires_at'")
		void ignoresEntriesWithoutExpiresAtSuffix() throws Exception {
			Map<String, Object> prefs = new LinkedHashMap<>();
			prefs.put("session:GOOGLE:user1:access_token",  encryptWithKey("tok1"));
			prefs.put("session:GOOGLE:user1:refresh_token", encryptWithKey("ref1"));

			buildPluginWithPrefs(prefs);

			verify(mockEditor, never()).remove(anyString());
		}

		@Test
		@DisplayName("handles a non-numeric expiry value without throwing")
		void handlesMalformedExpiryValue() throws Exception {
			String prefix = "session:GOOGLE:badUser:";
			Map<String, Object> prefs = new LinkedHashMap<>();
			prefs.put(prefix + "expires_at", encryptWithKey("not_a_number"));

			assertDoesNotThrow(() -> buildPluginWithPrefs(prefs));
			verify(mockEditor, never()).remove(anyString());
		}

		@Test
		@DisplayName("handles a completely invalid (non-base64) encrypted value without throwing")
		void handlesGarbageEncryptedValue() {
			Map<String, Object> prefs = new LinkedHashMap<>();
			prefs.put("session:GOOGLE:badUser:expires_at", "%%%invalid%%%");

			assertDoesNotThrow(() -> buildPluginWithPrefs(prefs));
		}

		@Test
		@DisplayName("removes expired session while keeping a concurrent valid session")
		void removesExpiredAndKeepsValid_whenMultipleSessions() throws Exception {
			String expiredPfx = "session:GOOGLE:expiredUser:";
			String validPfx   = "session:GOOGLE:validUser:";
			String expiredTs  = String.valueOf(System.currentTimeMillis() / 1000 - 3_600);
			String futureTs   = String.valueOf(System.currentTimeMillis() / 1000 + 3_600);

			Map<String, Object> prefs = new LinkedHashMap<>();
			prefs.put(expiredPfx + "expires_at",   encryptWithKey(expiredTs));
			prefs.put(expiredPfx + "access_token",  encryptWithKey("expiredTok"));
			prefs.put(validPfx   + "expires_at",   encryptWithKey(futureTs));
			prefs.put(validPfx   + "access_token",  encryptWithKey("validTok"));

			buildPluginWithPrefs(prefs);

			// Expired session entries removed
			verify(mockEditor).remove(expiredPfx + "expires_at");
			verify(mockEditor).remove(expiredPfx + "access_token");

			// Valid session entries untouched
			verify(mockEditor, never()).remove(validPfx + "expires_at");
			verify(mockEditor, never()).remove(validPfx + "access_token");
		}

		@Test
		@DisplayName("calls apply() once per expired session group, not once per key")
		void callsApplyOncePerExpiredGroup() throws Exception {
			String prefix    = "session:GOOGLE:oneSession:";
			String expiredTs = String.valueOf(System.currentTimeMillis() / 1000 - 100);

			Map<String, Object> prefs = new LinkedHashMap<>();
			prefs.put(prefix + "expires_at",   encryptWithKey(expiredTs));
			prefs.put(prefix + "access_token", encryptWithKey("tok"));
			prefs.put(prefix + "id_token",     encryptWithKey("id"));

			buildPluginWithPrefs(prefs);

			// apply() is called exactly once for the single expired group
			verify(mockEditor, Mockito.times(1)).apply();
		}

		@Test
		@DisplayName("plugin is fully constructed even when cleanup removes entries")
		void pluginIsNotNull_afterCleanupWithRemovals() throws Exception {
			String prefix    = "session:GOOGLE:user:";
			String expiredTs = String.valueOf(System.currentTimeMillis() / 1000 - 1);

			Map<String, Object> prefs = new LinkedHashMap<>();
			prefs.put(prefix + "expires_at",   encryptWithKey(expiredTs));
			prefs.put(prefix + "access_token", encryptWithKey("tok"));

			assertNotNull(buildPluginWithPrefs(prefs));
		}
	}
}
