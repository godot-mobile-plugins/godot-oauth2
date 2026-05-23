//
// © 2025-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.oauth2;

import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.Intent;
import android.net.Uri;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.util.Base64;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.browser.customtabs.CustomTabColorSchemeParams;
import androidx.browser.customtabs.CustomTabsIntent;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.nio.charset.StandardCharsets;
import java.security.KeyStore;
import java.util.Map;
import java.util.Set;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;


public class OAuth2Plugin extends GodotPlugin {
	public static final String CLASS_NAME = OAuth2Plugin.class.getSimpleName();
	static final String LOG_TAG = "godot::" + CLASS_NAME;

	// -- Secure-storage constants ----------------------------------------------

	private static final String PREFS_NAME        = "oauth2_secure_store";
	private static final String KEY_ALIAS         = "oauth2_master_key";
	private static final String ANDROID_KEY_STORE = "AndroidKeyStore";
	private static final int    AES_MODE_BIT      = 256;
	private static final int    GCM_TAG_LENGTH    = 128;

	// -- Signal names ----------------------------------------------------------

	private static final String SIGNAL_SESSION_COMPLETED = "auth_session_completed";
	private static final String SIGNAL_SESSION_CANCELLED = "auth_session_cancelled";
	private static final String SIGNAL_SESSION_ERROR     = "auth_session_error";

	// -- In-app browser state --------------------------------------------------

	/**
	 * Tracks whether a Chrome Custom Tab is currently open and awaiting the
	 * OAuth2 redirect URI.
	 *
	 * Set by {@link #launch_custom_tab(String, String)}; cleared by
	 * {@link #notify_custom_tab_redirect_received()} on success or by
	 * {@link #cancel_auth_session()} on an explicit developer-initiated cancel.
	 *
	 * <p>Automatic back-button / close-button detection via
	 * {@code ActivityLifecycleCallbacks} was intentionally removed. The
	 * transparent {@code DeeplinkActivity} causes {@code GodotApp.onResume()}
	 * to fire <em>before</em> {@code DeeplinkActivity.onCreate()} processes the
	 * deeplink, so any lifecycle-based cancellation signal would clear the PKCE
	 * state before the authorization code arrived on the Godot thread.
	 * Android cancellation is therefore only signalled by explicit
	 * {@code OAuth2.cancel_auth()} calls from GDScript.
	 */
	private volatile boolean customTabOpen = false;

	/**
	 * Stores the PKCE state parameter passed to {@link #launch_custom_tab}
	 * so that {@link #_on_deeplink_received} can restore GDScript's
	 * {@code _state} if it was cleared by a signal race before the Godot
	 * thread processed the redirect.  Cleared by
	 * {@link #notify_custom_tab_redirect_received()} once the redirect
	 * is delivered to GDScript.
	 */
	private volatile String expectedState = null;


	// ═════════════════════════════════════════════════════════════════════════
	// Construction
	// ═════════════════════════════════════════════════════════════════════════

	public OAuth2Plugin(Godot godot) {
		super(godot);
		cleanup_expired_tokens();
	}


	// ═════════════════════════════════════════════════════════════════════════
	// Plugin identity
	// ═════════════════════════════════════════════════════════════════════════

	@Override
	@NonNull
	public String getPluginName() {
		return CLASS_NAME;
	}


	@NonNull
	@Override
	public Set<SignalInfo> getPluginSignals() {
		return Set.of(
				new SignalInfo(SIGNAL_SESSION_COMPLETED),
				new SignalInfo(SIGNAL_SESSION_CANCELLED),
				new SignalInfo(SIGNAL_SESSION_ERROR, String.class)
		);
	}

	// ═════════════════════════════════════════════════════════════════════════
	// In-App Browser — Chrome Custom Tabs
	// ═════════════════════════════════════════════════════════════════════════

	/**
	 * Launches a Chrome Custom Tab for the given authorization URL.
	 *
	 * <p>Called automatically by {@code OAuth2.gd} when
	 * {@code browser_mode == IN_APP} on Android.  Developers never call this
	 * directly.
	 *
	 * <p>The redirect URI is delivered to the existing Deeplink node via
	 * Android's intent system, identical to EXTERNAL mode.
	 * The {@code state} parameter is stored in {@link #expectedState} so
	 * that {@code _on_deeplink_received} in GDScript can recover the PKCE
	 * state if it was cleared by a signal race before the Godot thread
	 * processed the redirect.
	 */
	@UsedByGodot
	public void launch_custom_tab(@NonNull String url, @NonNull String state) {
		Activity activity = getActivity();
		if (activity == null) {
			Log.e(LOG_TAG, "launch_custom_tab: Activity unavailable");
			emitSignal(SIGNAL_SESSION_ERROR, "Activity unavailable");
			return;
		}

		activity.runOnUiThread(() -> {
			try {
				CustomTabsIntent intent = new CustomTabsIntent.Builder()
						.setShowTitle(true)
						.setDefaultColorSchemeParams(
								new CustomTabColorSchemeParams.Builder().build())
						.setStartAnimations(activity,
								android.R.anim.slide_in_left,
								android.R.anim.slide_out_right)
						.setExitAnimations(activity,
								android.R.anim.slide_in_left,
								android.R.anim.slide_out_right)
						.build();

				expectedState = state;
				customTabOpen = true;
				// FLAG_ACTIVITY_NO_HISTORY prevents Chrome's CustomTabActivity
				// from being retained in Chrome's back stack after the OAuth2
				// redirect fires.  Without this flag, Chrome's task can resurface
				// after DeeplinkActivity handles the redirect, causing the
				// authorization screen to reappear (the 'signing back in' loop).
				intent.intent.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY);
				intent.launchUrl(activity, Uri.parse(url));

			} catch (Exception e) {
				customTabOpen = false;
				Log.e(LOG_TAG, "launch_custom_tab: failed", e);
				emitSignal(SIGNAL_SESSION_ERROR,
						e.getMessage() != null ? e.getMessage()
								: "Unknown error launching Custom Tab");
			}
		});
	}

	/**
	 * Clears the Custom Tab tracking flag when a redirect URI arrives via the
	 * Deeplink node (i.e. authentication succeeded).
	 *
	 * <p>Called automatically by {@code OAuth2.gd}'s {@code _on_deeplink_received()}.
	 * Developers never call this directly.
	 */
	/**
	 * Legacy helper — clears the Custom Tab tracking flags when the redirect
	 * URI is received.  In current usage the primary redirect handler is
	 * {@link #validate_and_consume_custom_tab_state(String)}, which performs
	 * state validation and foreground restore in a single atomic call.
	 * This method is retained for backward compatibility.
	 */
	@UsedByGodot
	public void notify_custom_tab_redirect_received() {
		customTabOpen = false;
		expectedState = null;
	}

	/**
	 * Returns the PKCE state value stored when
	 * {@link #launch_custom_tab(String, String)} was called, or an empty
	 * string if no Custom Tab session is in progress.
	 *
	 * <p>Called from {@code OAuth2.gd}'s {@code _on_deeplink_received()} to
	 * restore GDScript's {@code _state} when it has been cleared by a signal
	 * race before the deeplink was processed on the Godot thread.
	 */
	@UsedByGodot
	public String get_expected_state() {
		return expectedState != null ? expectedState : "";
	}

	/**
	 * Atomically validates the PKCE state parameter from the OAuth2 redirect
	 * URI against the expected state stored when
	 * {@link #launch_custom_tab(String, String)} was called.
	 *
	 * <p>Returns {@code true} exactly once per Custom Tab session: on the
	 * first call where {@code incomingState} matches {@code expectedState}.
	 * Matching clears {@code expectedState} immediately so that subsequent
	 * callers (e.g. other Deeplink nodes that also received the redirect
	 * signal) return {@code false} and are silently ignored.
	 *
	 * <p>This method is called from {@code _on_deeplink_received()} in
	 * {@code OAuth2.gd} only for nodes whose {@code browser_mode} is IN_APP
	 * ({@code _using_in_app_browser == true}).  Nodes in EXTERNAL mode use
	 * GDScript's own {@code _state} variable for CSRF validation instead.
	 *
	 * @param incomingState The state parameter extracted from the redirect URI
	 *                      query string.
	 * @return {@code true} if the state matched and was consumed;
	 *         {@code false} if there is no pending session, the state was
	 *         already consumed, or the state did not match.
	 */
	@UsedByGodot
	public boolean validate_and_consume_custom_tab_state(@NonNull String incomingState) {
		if (expectedState == null
				|| expectedState.isEmpty()
				|| incomingState.isEmpty()
				|| !expectedState.equals(incomingState)) {
			return false;
		}
		// Consume: clear state so duplicate callers find nothing.
		expectedState = null;
		customTabOpen = false;
		// Move the Godot task to the foreground so Chrome's task is
		// backgrounded after the redirect is handled.
		Activity activity = getActivity();
		if (activity != null) {
			activity.runOnUiThread(() -> {
				Intent i = activity.getPackageManager().getLaunchIntentForPackage(activity.getPackageName());
				if (i != null) {
					// FLAG_ACTIVITY_NEW_TASK   – promotes the Godot task to the foreground
					//                            over Chrome's separate task.
					// FLAG_ACTIVITY_CLEAR_TOP  – clears any stale activities above GodotApp
					//                            in the task (none expected, but defensive).
					// FLAG_ACTIVITY_SINGLE_TOP – reuses the existing GodotApp instance via
					//                            onNewIntent rather than creating a new one.
					i.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK
							| Intent.FLAG_ACTIVITY_CLEAR_TOP
							| Intent.FLAG_ACTIVITY_SINGLE_TOP);
					activity.startActivity(i);
				}
			});
		}
		return true;
	}

	/**
	 * Programmatically cancels an in-progress Custom Tab flow.
	 *
	 * <p>Called by {@code OAuth2.gd}'s {@code cancel_auth()} when the developer
	 * explicitly cancels authentication. Clears the tracking flag so internal
	 * state stays consistent. There is no Android API to close a Chrome Custom
	 * Tab from outside the tab itself; the user must dismiss it, after which the
	 * app returns to the foreground normally.
	 */
	@UsedByGodot
	public void cancel_auth_session() {
		customTabOpen = false;
		expectedState = null;
	}


	// ═════════════════════════════════════════════════════════════════════════
	// Secure storage
	// ═════════════════════════════════════════════════════════════════════════

	private SecretKey getSecretKey() throws Exception {
		KeyStore keyStore = KeyStore.getInstance(ANDROID_KEY_STORE);
		keyStore.load(null);

		if (!keyStore.containsAlias(KEY_ALIAS)) {
			KeyGenerator keyGenerator = KeyGenerator.getInstance(
					KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEY_STORE);
			KeyGenParameterSpec spec = new KeyGenParameterSpec.Builder(
					KEY_ALIAS,
					KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
					.setBlockModes(KeyProperties.BLOCK_MODE_GCM)
					.setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
					.setKeySize(AES_MODE_BIT)
					.build();
			keyGenerator.init(spec);
			return keyGenerator.generateKey();
		}
		return ((KeyStore.SecretKeyEntry) keyStore.getEntry(KEY_ALIAS, null)).getSecretKey();
	}

	private void cleanup_expired_tokens() {
		Activity activity = getActivity();
		if (activity == null) {
			return;
		}

		SharedPreferences prefs = activity.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
		Map<String, ?> allEntries = prefs.getAll();
		long currentTime = System.currentTimeMillis() / 1000;

		for (Map.Entry<String, ?> entry : allEntries.entrySet()) {
			String key = entry.getKey();
			if (key.endsWith(":expires_at")) {
				String decryptedVal = decrypt((String) entry.getValue());
				try {
					if (Long.parseLong(decryptedVal) < currentTime) {
						String prefix = key.substring(0, key.lastIndexOf(":") + 1);
						SharedPreferences.Editor editor = prefs.edit();
						for (String k : allEntries.keySet()) {
							if (k.startsWith(prefix)) {
								editor.remove(k);
							}
						}
						editor.apply();
					}
				} catch (Exception e) {
					Log.e(LOG_TAG, "Cleanup error", e);
				}
			}
		}
	}

	private String encrypt(String plainText) {
		try {
			Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
			cipher.init(Cipher.ENCRYPT_MODE, getSecretKey());
			byte[] iv  = cipher.getIV();
			byte[] enc = cipher.doFinal(plainText.getBytes(StandardCharsets.UTF_8));
			return Base64.encodeToString(iv, Base64.NO_WRAP)
					+ ":"
					+ Base64.encodeToString(enc, Base64.NO_WRAP);
		} catch (Exception e) {
			Log.e(LOG_TAG, "Encryption failed", e);
			return null;
		}
	}

	private String decrypt(String encryptedText) {
		try {
			if (encryptedText == null || encryptedText.isEmpty()) {
				return "";
			}
			String[] parts = encryptedText.split(":");
			if (parts.length != 2) {
				return "";
			}
			byte[] iv  = Base64.decode(parts[0], Base64.NO_WRAP);
			byte[] enc = Base64.decode(parts[1], Base64.NO_WRAP);
			Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
			cipher.init(Cipher.DECRYPT_MODE, getSecretKey(),
					new GCMParameterSpec(GCM_TAG_LENGTH, iv));
			return new String(cipher.doFinal(enc), StandardCharsets.UTF_8);
		} catch (Exception e) {
			Log.e(LOG_TAG, "Decryption failed", e);
			return "";
		}
	}

	@UsedByGodot
	public String[] get_all_keys() {
		Activity activity = getActivity();
		if (activity == null) {
			return new String[0];
		}
		return activity.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
				.getAll().keySet().toArray(new String[0]);
	}

	@UsedByGodot
	public void save_token(@NonNull String key, @NonNull String value) {
		Activity activity = getActivity();
		if (activity == null) {
			return;
		}
		String enc = encrypt(value);
		if (enc != null) {
			activity.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
					.edit().putString(key, enc).apply();
		}
	}

	@UsedByGodot
	public String get_token(@NonNull String key) {
		Activity activity = getActivity();
		if (activity == null) {
			return "";
		}
		String enc = activity.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
				.getString(key, null);
		return enc == null ? "" : decrypt(enc);
	}

	@UsedByGodot
	public void delete_token(@NonNull String key) {
		Activity activity = getActivity();
		if (activity == null) {
			return;
		}
		activity.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
				.edit().remove(key).apply();
	}
}
