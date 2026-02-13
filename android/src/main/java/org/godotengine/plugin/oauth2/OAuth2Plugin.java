//
// © 2025-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.oauth2;

import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.util.Base64;
import android.util.Log;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

import java.nio.charset.StandardCharsets;
import java.security.KeyStore;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;


public class OAuth2Plugin extends GodotPlugin {
	public static final String CLASS_NAME = OAuth2Plugin.class.getSimpleName();
	static final String LOG_TAG = "godot::" + CLASS_NAME;

	private static final String PREFS_NAME = "oauth2_secure_store";
	private static final String KEY_ALIAS = "oauth2_master_key";
	private static final String ANDROID_KEY_STORE = "AndroidKeyStore";
	private static final int AES_MODE_BIT = 256;
	private static final int GCM_TAG_LENGTH = 128;

	private SharedPreferences securePrefs;

	public OAuth2Plugin(Godot godot) {
		super(godot);
		cleanup_expired_tokens(); // Clear expired tokens on startup
	}

	@Override
	public String getPluginName() {
		return CLASS_NAME;
	}

	private SecretKey getSecretKey() throws Exception {
		KeyStore keyStore = KeyStore.getInstance(ANDROID_KEY_STORE);
		keyStore.load(null);

		if (!keyStore.containsAlias(KEY_ALIAS)) {
			KeyGenerator keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEY_STORE);
			KeyGenParameterSpec keyGenParameterSpec = new KeyGenParameterSpec.Builder(
					KEY_ALIAS,
					KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
					.setBlockModes(KeyProperties.BLOCK_MODE_GCM)
					.setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
					.setKeySize(AES_MODE_BIT)
					.build();
			keyGenerator.init(keyGenParameterSpec);
			return keyGenerator.generateKey();
		}
		return ((KeyStore.SecretKeyEntry) keyStore.getEntry(KEY_ALIAS, null)).getSecretKey();
	}

	private void cleanup_expired_tokens() {
		Activity activity = getActivity();
		if (activity == null) return;
		SharedPreferences prefs = activity.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
		Map<String, ?> allEntries = prefs.getAll();
		long currentTime = System.currentTimeMillis() / 1000;

		for (Map.Entry<String, ?> entry : allEntries.entrySet()) {
			String key = entry.getKey();
			if (key.endsWith(":expires_at")) {
				String decryptedVal = decrypt((String) entry.getValue());
				try {
					if (Long.parseLong(decryptedVal) < currentTime) {
						// Extract prefix (e.g., "session:GOOGLE:user123:") and remove all associated keys
						String prefix = key.substring(0, key.lastIndexOf(":") + 1);
						SharedPreferences.Editor editor = prefs.edit();
						for (String k : allEntries.keySet()) {
							if (k.startsWith(prefix)) editor.remove(k);
						}
						editor.apply();
					}
				} catch (Exception e) { Log.e(LOG_TAG, "Cleanup error", e); }
			}
		}
	}

	private String encrypt(String plainText) {
		try {
			SecretKey secretKey = getSecretKey();
			Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
			cipher.init(Cipher.ENCRYPT_MODE, secretKey);
			byte[] iv = cipher.getIV();
			byte[] encryption = cipher.doFinal(plainText.getBytes(StandardCharsets.UTF_8));

			String ivStr = Base64.encodeToString(iv, Base64.NO_WRAP);
			String encStr = Base64.encodeToString(encryption, Base64.NO_WRAP);
			return ivStr + ":" + encStr; // Store IV and CipherText together
		} catch (Exception e) {
			Log.e(LOG_TAG, "Encryption failed", e);
			return null;
		}
	}

	private String decrypt(String encryptedText) {
		try {
			if (encryptedText == null || encryptedText.isEmpty()) return "";
			String[] parts = encryptedText.split(":");
			if (parts.length != 2) return "";

			byte[] iv = Base64.decode(parts[0], Base64.NO_WRAP);
			byte[] encryptedData = Base64.decode(parts[1], Base64.NO_WRAP);

			SecretKey secretKey = getSecretKey();
			Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
			GCMParameterSpec spec = new GCMParameterSpec(GCM_TAG_LENGTH, iv);
			cipher.init(Cipher.DECRYPT_MODE, secretKey, spec);

			byte[] decoded = cipher.doFinal(encryptedData);
			return new String(decoded, StandardCharsets.UTF_8);
		} catch (Exception e) {
			Log.e(LOG_TAG, "Decryption failed", e);
			return "";
		}
	}

	@UsedByGodot
	public String[] get_all_keys() {
		Activity activity = getActivity();
		if (activity == null) return new String[0];
		SharedPreferences prefs = activity.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
		return prefs.getAll().keySet().toArray(new String[0]);
	}

	@UsedByGodot
	public void save_token(String key, String value) {
		Activity activity = getActivity();
		if (activity == null) return;

		String encryptedValue = encrypt(value);
		if (encryptedValue != null) {
			SharedPreferences prefs = activity.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
			prefs.edit().putString(key, encryptedValue).apply();
		}
	}

	@UsedByGodot
	public String get_token(String key) {
		Activity activity = getActivity();
		if (activity == null) return "";

		SharedPreferences prefs = activity.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
		String encryptedValue = prefs.getString(key, null);
		
		if (encryptedValue == null) return "";
		return decrypt(encryptedValue);
	}

	@UsedByGodot
	public void delete_token(String key) {
		Activity activity = getActivity();
		if (activity == null) return;

		SharedPreferences prefs = activity.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
		prefs.edit().remove(key).apply();
	}
}
