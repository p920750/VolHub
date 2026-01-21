# Supabase Setup Guide for VolHub

This guide will help you set up Supabase for your VolHub Flutter application.

## Step 1: Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up or log in to your account
3. Click "New Project"
4. Fill in your project details:
   - **Name**: VolHub (or any name you prefer)
   - **Database Password**: Create a strong password (save it securely)
   - **Region**: Choose the region closest to your users
5. Click "Create new project" and wait for it to be set up (takes 1-2 minutes)

## Step 2: Get Your Supabase Credentials

1. In your Supabase project dashboard, go to **Settings** → **API**
2. You'll find two important values:
   - **Project URL**: Something like `https://xxxxxxxxxxxxx.supabase.co`
   - **anon/public key**: A long JWT token starting with `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

## Step 3: Configure Your App

1. Open `lib/config/supabase_config.dart`
2. Replace the placeholder values:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_URL';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```
   With your actual values:
   ```dart
   static const String supabaseUrl = 'https://xxxxxxxxxxxxx.supabase.co';
   static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
   ```

## Step 4: Set Up Authentication

### Email Authentication (Already Configured)

The app is already set up for email/password authentication. Users can:
- Sign up with email and password
- Sign in with email and password
- Reset password via email

### Enable Email Authentication in Supabase

1. Go to **Authentication** → **Providers** in your Supabase dashboard
2. Make sure **Email** is enabled
3. Configure email templates if needed (optional)

## Step 5: Set Up Database Tables (Optional)

If you want to store user profiles, you can create a `profiles` table:

1. Go to **Table Editor** in Supabase dashboard
2. Click "New Table"
3. Name it `profiles`
4. Add columns:
   - `id` (uuid, primary key, references auth.users)
   - `full_name` (text)
   - `email` (text)
   - `created_at` (timestamp, default: now())
   - `updated_at` (timestamp, default: now())

5. Enable Row Level Security (RLS) and create policies:
   ```sql
   -- Users can read their own profile
   CREATE POLICY "Users can view own profile"
   ON profiles FOR SELECT
   USING (auth.uid() = id);

   -- Users can update their own profile
   CREATE POLICY "Users can update own profile"
   ON profiles FOR UPDATE
   USING (auth.uid() = id);

   -- Users can insert their own profile
   CREATE POLICY "Users can insert own profile"
   ON profiles FOR INSERT
   WITH CHECK (auth.uid() = id);
   ```

## Step 6: Test Your Setup

1. Run your Flutter app: `flutter run`
2. Try signing up with a new email
3. Check your email for the verification link (if email confirmation is enabled)
4. Try signing in with your credentials
5. Test the forgot password feature

## Features Implemented

✅ **Authentication**
- Sign up with email/password
- Sign in with email/password
- Sign out
- Password reset via email

✅ **User Management**
- Get current user
- Check authentication status
- Listen to auth state changes

✅ **Profile Management** (if you set up the profiles table)
- Get user profile
- Update user profile

## Security Notes

⚠️ **Important**: 
- Never commit your `service_role` key to version control
- The `anon` key is safe to use in client-side code
- For production, consider using environment variables for sensitive data
- Always enable Row Level Security (RLS) on your database tables

## Troubleshooting

### "Invalid API key" error
- Double-check your Supabase URL and anon key in `supabase_config.dart`
- Make sure there are no extra spaces or quotes

### "Email not confirmed" error
- Go to Authentication → Settings in Supabase dashboard
- Check if "Enable email confirmations" is enabled
- If enabled, users must verify their email before signing in

### Password reset not working
- Check your Supabase project's email settings
- Make sure SMTP is configured (or use Supabase's default email service)
- Check spam folder for reset emails

## Next Steps

- Set up social authentication (Google, Facebook, etc.)
- Create additional database tables for your app
- Implement real-time subscriptions
- Add file storage for user avatars

For more information, visit the [Supabase Flutter Documentation](https://supabase.com/docs/guides/flutter).

