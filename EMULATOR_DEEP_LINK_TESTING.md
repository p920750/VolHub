# Testing Deep Links on Android Emulator

This guide explains how to test password reset deep links on Android emulators.

## Problem

When you click a password reset link in Gmail on an emulator, you might see a blank screen because:
1. Deep links work differently on emulators vs physical devices
2. The browser/email app on emulator might not properly handle custom URL schemes
3. The app needs to be running or properly configured to handle the deep link

## Solution: Test Deep Links Manually Using ADB

You can test deep links directly using Android Debug Bridge (ADB) commands.

### Step 1: Make Sure Your App is Running

1. Start your Flutter app on the emulator:
   ```bash
   flutter run
   ```

2. Or install the app first:
   ```bash
   flutter install
   ```

### Step 2: Test the Reset Password Deep Link

Open a terminal/command prompt and run:

**For Android Emulator:**
```bash
adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://reset-password?access_token=test_token&refresh_token=test_refresh&type=recovery"
```

**Simpler version (without auth params):**
```bash
adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://reset-password"
```

### Step 3: Test with Full Supabase URL (Simulating Real Email Link)

When Supabase sends a password reset email, the link looks like this:
```
https://your-project.supabase.co/auth/v1/verify?token=xxx&type=recovery&redirect_to=io.supabase.volhub://reset-password
```

To simulate this on emulator, you can:

1. **Copy the actual reset link from your email**
2. **Extract the token and parameters**
3. **Test with ADB using the full URL format:**

```bash
adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://reset-password#access_token=YOUR_ACCESS_TOKEN&refresh_token=YOUR_REFRESH_TOKEN&expires_in=3600&token_type=bearer&type=recovery"
```

**Note:** Replace `YOUR_ACCESS_TOKEN` and `YOUR_REFRESH_TOKEN` with actual tokens from the email link.

### Step 4: Alternative - Use Chrome Browser on Emulator

1. Open Chrome browser on your emulator
2. Type in the address bar: `io.supabase.volhub://reset-password`
3. Press Enter
4. It should ask which app to open - select your app

### Step 5: Testing the Full Flow

1. **Request a password reset** from your app (running on emulator)
2. **Check your email** (on your laptop/computer, not emulator)
3. **Copy the reset link** from the email
4. **Extract the URL parameters** from the link
5. **Use ADB to simulate clicking the link:**

```bash
# First, get the full URL from your email
# It will look like: https://xxx.supabase.co/auth/v1/verify?token=xxx&type=recovery&redirect_to=io.supabase.volhub://reset-password

# Extract the token and build the deep link with auth params
adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://reset-password#access_token=TOKEN_FROM_EMAIL&refresh_token=REFRESH_TOKEN&type=recovery"
```

## Quick Test Commands

### Test 1: Simple Deep Link (No Auth Params)
```bash
adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://reset-password"
```
**Expected:** App should open and show reset password page (but might show "Invalid or Expired Link" since no session)

### Test 2: With Mock Auth Params
```bash
adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://reset-password#access_token=mock_token&refresh_token=mock_refresh&type=recovery"
```
**Expected:** App should open and try to process the session

### Test 3: Test Other Deep Links
```bash
# Email confirmation
adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://email-confirm"

# OAuth callback
adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://login-callback"
```

## Troubleshooting

### "App not found" or "No app can handle this"
- Make sure your app is installed on the emulator
- Verify the intent filter is in `AndroidManifest.xml`
- Rebuild and reinstall the app: `flutter clean && flutter run`

### Blank Screen Appears
- Check the app logs: `flutter logs` or `adb logcat | grep flutter`
- Make sure the deep link handler in `main.dart` is working
- Verify the route `/reset-password` exists in your routes

### Deep Link Works but Shows "Invalid Session"
- This is expected if you're testing without real Supabase tokens
- Request a real password reset and use the actual tokens from the email
- The session needs to be processed by Supabase first

### How to Get Real Tokens from Email

1. Request password reset from your app
2. Check your email
3. The link will be something like:
   ```
   https://xxx.supabase.co/auth/v1/verify?token=abc123&type=recovery&redirect_to=io.supabase.volhub://reset-password
   ```
4. When you click this link normally, Supabase processes it and redirects to:
   ```
   io.supabase.volhub://reset-password#access_token=real_token&refresh_token=real_refresh&...
   ```
5. Copy that redirected URL and use it in ADB command

## Alternative: Use a Web Redirect Page

If deep links don't work well on emulator, you can create a simple HTML page that redirects:

1. Create `web/reset-redirect.html`:
   ```html
   <!DOCTYPE html>
   <html>
   <head>
       <script>
           // Get URL parameters
           const urlParams = new URLSearchParams(window.location.search);
           const redirectTo = urlParams.get('redirect_to') || 'io.supabase.volhub://reset-password';
           // Redirect to deep link
           window.location.href = redirectTo;
       </script>
   </head>
   <body>
       <p>Redirecting...</p>
   </body>
   </html>
   ```

2. Configure Supabase to redirect to: `http://localhost:port/reset-redirect.html?redirect_to=io.supabase.volhub://reset-password`

But this is more complex - using ADB is simpler for testing.

## For iOS Simulator

If you're using iOS Simulator, you can test deep links by:

1. Opening Safari in the simulator
2. Typing: `io.supabase.volhub://reset-password`
3. Press Enter
4. It should open your app

Or use:
```bash
xcrun simctl openurl booted "io.supabase.volhub://reset-password"
```

## Summary

- **For development/testing:** Use ADB commands to simulate deep links
- **For production:** Deep links will work automatically when users click email links on their phones
- **The blank screen issue** happens because emulators don't always handle custom URL schemes from email apps properly
- **Solution:** Test manually with ADB commands or use a physical device for final testing

