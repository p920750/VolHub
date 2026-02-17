# OAuth Redirect URL Setup Guide

This guide explains how to fix the "localhost error" when using Google login.

## Problem

When you press the Google login button, you might see a "localhost refused to connect" error. This happens because the redirect URLs are not properly configured in your Supabase dashboard.

## Solution

You need to add the redirect URLs to your Supabase project settings.

## Step 1: Configure Redirect URLs in Supabase Dashboard

1. Go to your Supabase project dashboard: https://supabase.com/dashboard
2. Select your project
3. Navigate to **Authentication** → **URL Configuration**
4. In the **Redirect URLs** section, add the following URLs (one per line):

   **For Mobile (Android/iOS):**
   ```
   io.supabase.volhub://login-callback
   ```

   **For Web:**
   ```
   http://localhost:*/auth/callback
   https://yourdomain.com/auth/callback
   ```
   
   Replace `yourdomain.com` with your actual web domain if you're deploying to production.

   **For Supabase default callback (recommended for web):**
   ```
   https://qvnqlfgifuerdqebbvol.supabase.co/auth/v1/callback
   ```
   
   (Replace with your actual Supabase project URL)

5. Click **Save**

## Step 2: Configure Google OAuth in Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Go to **APIs & Services** → **Credentials**
4. Find your OAuth 2.0 Client ID (the one you're using for Supabase)
5. Click **Edit**
6. In **Authorized redirect URIs**, add:
   ```
   https://qvnqlfgifuerdqebbvol.supabase.co/auth/v1/callback
   ```
   (Replace with your actual Supabase project URL)
7. Click **Save**

## Step 3: Verify Google Provider Settings in Supabase

1. In Supabase dashboard, go to **Authentication** → **Providers**
2. Find **Google** and click to expand
3. Make sure it's **Enabled**
4. Verify that your **Client ID** and **Client Secret** are correctly entered
5. Click **Save** if you made any changes

## Step 4: Test the Login

1. Run your app: `flutter run`
2. Click "Continue with Google" button
3. You should be redirected to Google sign-in page
4. After signing in, you should be redirected back to your app (not localhost)

## How It Works

- **Mobile**: The app uses deep links (`io.supabase.volhub://login-callback`) to redirect back to the app after OAuth
- **Web**: Supabase automatically handles the redirect using the configured callback URL
- The code now detects the platform and uses the appropriate redirect method

## Troubleshooting

### Still seeing "localhost refused to connect"

1. **Check Supabase Redirect URLs:**
   - Go to Authentication → URL Configuration
   - Make sure `io.supabase.volhub://login-callback` is added
   - Make sure your Supabase callback URL is added

2. **Check Google Cloud Console:**
   - Verify the redirect URI in Google Console matches your Supabase callback URL
   - The format should be: `https://YOUR_PROJECT.supabase.co/auth/v1/callback`

3. **Clear browser cache:**
   - If testing on web, clear your browser cache and cookies
   - Try in an incognito/private window

4. **Check the error message:**
   - Look at the full error URL in the browser
   - It might show which redirect URL is missing

### "Redirect URI mismatch" error

- This means the redirect URI in Google Console doesn't match what Supabase is sending
- Make sure both have: `https://YOUR_PROJECT.supabase.co/auth/v1/callback`

### App doesn't open after OAuth (mobile)

- Verify deep linking is configured in `AndroidManifest.xml` (Android) and `Info.plist` (iOS)
- Test the deep link manually:
  - Android: `adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://login-callback"`
  - iOS: Open Safari and type `io.supabase.volhub://login-callback`

## Additional Notes

- The code now automatically detects if you're running on web or mobile
- For web, it uses Supabase's default redirect handling
- For mobile, it uses the deep link scheme
- Make sure to add both redirect URLs to Supabase dashboard for full compatibility

## Security

- Never commit your OAuth Client Secret to version control
- Use environment variables for sensitive credentials in production
- Regularly rotate your OAuth credentials

