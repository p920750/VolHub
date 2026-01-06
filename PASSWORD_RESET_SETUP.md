# Password Reset Setup Guide

This guide explains how to fix the "localhost error" when clicking password reset links in Gmail on your phone.

## Problem

When you click the password reset link in Gmail on your phone, you see a "localhost refused to connect" error. This happens because:

1. The redirect URL is not properly configured in Supabase dashboard
2. Supabase needs to know where to redirect users after they click the reset link

## Solution

You need to add the password reset redirect URL to your Supabase project settings.

## Step 1: Configure Redirect URL in Supabase Dashboard

1. Go to your Supabase project dashboard: https://supabase.com/dashboard
2. Select your project
3. Navigate to **Authentication** → **URL Configuration**
4. In the **Redirect URLs** section, add the following URL:
   ```
   io.supabase.volhub://reset-password
   ```
5. Click **Save**

**Important:** Make sure this URL is added along with your other redirect URLs (like `io.supabase.volhub://email-confirm` and `io.supabase.volhub://login-callback`).

## Step 2: Verify Email Template (Optional)

1. Go to **Authentication** → **Email Templates** in Supabase dashboard
2. Click on **Reset Password** template
3. Make sure the redirect URL in the template uses the `{{ .ConfirmationURL }}` variable
4. The template should automatically use the redirect URL you configured

## Step 3: Test Password Reset

1. Run your Flutter app on your phone: `flutter run`
2. Go to the "Forgot Password" page
3. Enter your email and click "Send Reset Link"
4. Check your email (Gmail) on your phone
5. Click the password reset link
6. The app should open automatically and show the "Reset Password" page
7. Enter your new password and confirm it
8. You should be redirected to the login page

## How It Works

1. When a user requests password reset, the app calls `SupabaseService.resetPassword()` with `redirectTo: 'io.supabase.volhub://reset-password'`
2. Supabase sends an email with a reset link
3. When the user clicks the link on their phone:
   - The link goes to Supabase's servers first
   - Supabase processes the reset token
   - Supabase redirects to `io.supabase.volhub://reset-password` (the deep link)
   - The phone recognizes the deep link and opens your app
4. The app handles the deep link in `main.dart` and navigates to the `ResetPasswordPage`
5. The user enters their new password and it gets updated

## Troubleshooting

### "localhost refused to connect" still appears
- Make sure you've added `io.supabase.volhub://reset-password` to the Redirect URLs in Supabase dashboard
- Make sure you clicked **Save** after adding the URL
- Try requesting a new password reset link after adding the URL

### App doesn't open when clicking the link
- Make sure the deep link is properly configured in your Android/iOS app configuration
- For Android: Check `android/app/src/main/AndroidManifest.xml` for deep link configuration
- For iOS: Check `ios/Runner/Info.plist` for URL scheme configuration
- Make sure the app is installed on your phone

### Link opens but shows "Invalid or Expired Link"
- The reset link might have expired (they typically expire after 1 hour)
- Request a new password reset link
- Make sure you're clicking the link within the expiration time

### Link works on laptop but not on phone/emulator
- This is expected! The deep link `io.supabase.volhub://reset-password` is designed for mobile devices
- On laptop/web, it would use a different redirect URL
- **For emulator testing:** See `EMULATOR_DEEP_LINK_TESTING.md` for instructions on testing deep links using ADB commands
- **For physical device:** Make sure you're testing on the actual mobile device where the app is installed

### Blank screen when clicking link on emulator
- Emulators don't always handle deep links from email apps properly
- Use ADB commands to test deep links manually (see `EMULATOR_DEEP_LINK_TESTING.md`)
- Or test on a physical device for the most accurate behavior

## Additional Notes

- Password reset links typically expire after 1 hour for security reasons
- Each reset link can only be used once
- If you need to reset your password again, request a new link
- The redirect URL must match exactly what's configured in Supabase dashboard

