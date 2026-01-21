# Fixing Google Sign-In on Mobile Emulator

## Common Issues and Solutions

### Issue 1: OAuth Callback Not Processing Session

**Problem:** After signing in with Google, the app doesn't recognize you're logged in.

**Solution:** ✅ **FIXED** - The code now properly processes the OAuth session from the deep link URL. The fix ensures that when the OAuth callback is received, the session is extracted and processed before navigation.

### Issue 2: "Redirect URI Mismatch" Error

**Problem:** Google shows an error saying the redirect URI doesn't match.

**Solution:**
1. **Check Supabase Dashboard:**
   - Go to **Authentication** → **URL Configuration**
   - Make sure `io.supabase.volhub://login-callback` is in the **Redirect URLs** list
   - Click **Save**

2. **Check Google Cloud Console:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Navigate to **APIs & Services** → **Credentials**
   - Find your OAuth 2.0 Client ID (the one used for Supabase)
   - Click **Edit**
   - In **Authorized redirect URIs**, make sure you have:
     ```
     https://YOUR_PROJECT.supabase.co/auth/v1/callback
     ```
   - Replace `YOUR_PROJECT` with your actual Supabase project subdomain
   - Click **Save**

### Issue 3: Deep Link Not Opening App After Google Sign-In

**Problem:** After signing in with Google, the browser doesn't redirect back to your app.

**Solution:**
1. **Verify AndroidManifest.xml:**
   - The deep link should be configured (already done in your project)
   - Check that `android/app/src/main/AndroidManifest.xml` has the intent filter for `io.supabase.volhub://login-callback`

2. **Test the deep link manually:**
   ```bash
   adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://login-callback"
   ```
   - This should open your app
   - If it doesn't, rebuild the app: `flutter clean && flutter run`

3. **Check if app is installed:**
   - Make sure the app is installed on the emulator
   - Run: `flutter install` or `flutter run`

### Issue 4: "OAuth Client Not Found" Error

**Problem:** Google shows an error about OAuth client not being found.

**Solution:**
1. **Verify Google Provider in Supabase:**
   - Go to Supabase Dashboard → **Authentication** → **Providers**
   - Find **Google** and make sure it's **Enabled**
   - Verify **Client ID** and **Client Secret** are correctly entered
   - Click **Save**

2. **Check Google Cloud Console:**
   - Make sure Google+ API is enabled
   - Go to **APIs & Services** → **Library**
   - Search for "Google+ API" or "Google Identity"
   - Make sure it's enabled

### Issue 5: App Opens But User Not Logged In

**Problem:** The app opens after Google sign-in, but the user is not authenticated.

**Solution:**
1. **Check the logs:**
   ```bash
   flutter logs
   ```
   - Look for "Processing OAuth session from URL..."
   - Check for any error messages

2. **Verify session processing:**
   - The fix ensures the session is processed from the URL
   - If you see errors in logs, check:
     - Is the redirect URL correct in Supabase?
     - Are the auth parameters present in the deep link?

3. **Test with a real device:**
   - Emulators sometimes have issues with OAuth flows
   - Try on a physical Android device if possible

### Issue 6: Browser Opens But Shows Error Page

**Problem:** When clicking "Continue with Google", the browser opens but shows an error.

**Solution:**
1. **Check internet connection:**
   - Make sure the emulator has internet access
   - Test by opening Chrome in the emulator

2. **Check Google OAuth credentials:**
   - Verify Client ID and Secret in Supabase dashboard
   - Make sure they're from the correct Google Cloud project

3. **Check OAuth consent screen:**
   - In Google Cloud Console, go to **APIs & Services** → **OAuth consent screen**
   - Make sure it's configured (at least for testing)
   - Add test users if needed

## Step-by-Step Verification

### 1. Verify Supabase Configuration

```bash
# Check your Supabase project URL
# It should be in: lib/config/supabase_config.dart
```

1. Go to Supabase Dashboard → **Authentication** → **URL Configuration**
2. Verify these URLs are in **Redirect URLs**:
   - `io.supabase.volhub://login-callback`
   - `io.supabase.volhub://email-confirm`
   - `io.supabase.volhub://reset-password`
3. Click **Save**

### 2. Verify Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Go to **APIs & Services** → **Credentials**
4. Find your OAuth 2.0 Client ID
5. Verify **Authorized redirect URIs** includes:
   ```
   https://YOUR_PROJECT.supabase.co/auth/v1/callback
   ```

### 3. Verify Android Configuration

1. Check `android/app/src/main/AndroidManifest.xml`
2. Verify intent filter exists for `io.supabase.volhub://login-callback`
3. Rebuild if needed: `flutter clean && flutter run`

### 4. Test the Flow

1. **Run the app:**
   ```bash
   flutter run
   ```

2. **Click "Continue with Google"**

3. **Expected behavior:**
   - Browser/Chrome opens (or Google sign-in page)
   - You sign in with Google
   - Browser redirects back to your app
   - App processes the session
   - You're logged in

4. **Check logs:**
   ```bash
   flutter logs
   ```
   - Look for: "Processing login-callback deep link"
   - Look for: "Processing OAuth session from URL..."
   - Look for: "OAuth session processed successfully"

## Debugging Commands

### Test Deep Link Manually
```bash
# Test if deep link works
adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://login-callback"
```

### Check App Logs
```bash
# View Flutter logs
flutter logs

# View Android logs
adb logcat | grep flutter
```

### Check Installed Apps
```bash
# List installed packages
adb shell pm list packages | grep volhub
```

### Clear App Data (if needed)
```bash
# Clear app data and cache
adb shell pm clear com.example.main_volhub
```

## Common Error Messages

### "redirect_uri_mismatch"
- **Cause:** Redirect URI in Google Console doesn't match Supabase
- **Fix:** Add `https://YOUR_PROJECT.supabase.co/auth/v1/callback` to Google Console

### "access_denied"
- **Cause:** User cancelled the sign-in or OAuth consent screen issue
- **Fix:** Check OAuth consent screen configuration in Google Cloud Console

### "invalid_client"
- **Cause:** Client ID or Secret is incorrect
- **Fix:** Verify credentials in Supabase Dashboard → Authentication → Providers → Google

### "Deep link not handled"
- **Cause:** AndroidManifest.xml not configured or app not installed
- **Fix:** Rebuild app: `flutter clean && flutter run`

## Testing on Physical Device

If emulator issues persist, test on a physical Android device:

1. **Enable USB debugging** on your phone
2. **Connect phone** to your computer
3. **Run:**
   ```bash
   flutter devices  # Should show your phone
   flutter run -d <device-id>
   ```

Physical devices handle OAuth flows more reliably than emulators.

## Additional Notes

- **Emulator limitations:** Some emulators have issues with OAuth flows, especially with deep linking
- **Chrome Custom Tabs:** The OAuth flow uses Chrome Custom Tabs on Android, which should work on most emulators
- **Network issues:** Make sure emulator has internet access
- **Time sync:** Make sure emulator time is synced (OAuth tokens are time-sensitive)

## Still Having Issues?

1. **Check all configuration files:**
   - Supabase Dashboard settings
   - Google Cloud Console settings
   - AndroidManifest.xml
   - main.dart (deep link handling)

2. **Review logs carefully:**
   - Look for specific error messages
   - Check both Flutter logs and Android logs

3. **Test on physical device:**
   - Emulators can have quirks with OAuth
   - Physical devices are more reliable

4. **Verify step by step:**
   - Test deep link manually first
   - Then test OAuth flow
   - Check each step in the process

