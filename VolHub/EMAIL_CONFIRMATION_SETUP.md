# Email Confirmation Setup Guide

This guide explains how to configure email confirmation redirect URLs in Supabase so that users see a success message instead of "localhost refused to connect" when they confirm their email.

## Problem

When users click the email confirmation link, they might see "localhost refused to connect" because Supabase doesn't know where to redirect them after email confirmation.

## Solution

Configure the redirect URL in your Supabase dashboard to point to your app's deep link.

## Step 1: Configure Redirect URL in Supabase Dashboard

1. Go to your Supabase project dashboard: https://supabase.com/dashboard
2. Select your project
3. Navigate to **Authentication** → **URL Configuration**
4. In the **Redirect URLs** section, add the following URL:
   ```
   io.supabase.volhub://email-confirm
   ```
5. Click **Save**

## Step 2: Verify Email Template (Optional)

1. Go to **Authentication** → **Email Templates**
2. Click on **Confirm signup** template
3. Make sure the redirect URL in the template uses the `{{ .ConfirmationURL }}` variable
4. The template should automatically use the redirect URL you configured

## Step 3: Test Email Confirmation

1. Run your Flutter app: `flutter run`
2. Create a new account with a valid email
3. Check your email for the confirmation link
4. Click the confirmation link
5. The app should open and show the "Email Verified!" success page

## How It Works

1. When a user signs up, the app calls `SupabaseService.signUp()` with `emailRedirectTo: 'io.supabase.volhub://email-confirm'`
2. Supabase sends an email with a confirmation link
3. When the user clicks the link, it opens the app via the deep link
4. The app handles the deep link in `main.dart` and navigates to the `EmailConfirmPage`
5. The `EmailConfirmPage` verifies the email and shows a success message

## Troubleshooting

### "localhost refused to connect" still appears
- Make sure you've added `io.supabase.volhub://email-confirm` to the Redirect URLs in Supabase dashboard
- Verify that the deep link is configured in `AndroidManifest.xml` (Android) and `Info.plist` (iOS)
- Check that you've run `flutter pub get` after adding the `app_links` package

### App doesn't open when clicking email link
- Verify deep linking is configured correctly:
  - Android: Check `android/app/src/main/AndroidManifest.xml` has the intent filter
  - iOS: Check `ios/Runner/Info.plist` has the URL scheme
- Test the deep link manually:
  - Android: `adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://email-confirm"`
  - iOS: Open Safari and type `io.supabase.volhub://email-confirm`

### Email verification page shows error
- Make sure the Supabase client is properly initialized
- Check that the session is being retrieved correctly from the URL
- Verify the user's email is actually confirmed in Supabase dashboard

## Additional Notes

- The redirect URL `io.supabase.volhub://email-confirm` is a deep link that opens your app
- You can customize this URL scheme, but make sure it matches in:
  - Supabase dashboard redirect URLs
  - `supabase_service.dart` (in `signUp` method)
  - `AndroidManifest.xml` (Android)
  - `Info.plist` (iOS)
  - `main.dart` (deep link handling)

## Security

- Never commit your Supabase service role key to version control
- The redirect URL should be unique to your app to prevent conflicts
- Consider using environment variables for the redirect URL in production

