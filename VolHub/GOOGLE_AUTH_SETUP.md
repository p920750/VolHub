# Google Authentication Setup Guide for VolHub

This guide will help you enable Google OAuth authentication in your Supabase project and Flutter app.

## Step 1: Create Google OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the **Google+ API**:
   - Go to **APIs & Services** → **Library**
   - Search for "Google+ API"
   - Click **Enable**

4. Create OAuth 2.0 credentials:
   - Go to **APIs & Services** → **Credentials**
   - Click **Create Credentials** → **OAuth client ID**
   - If prompted, configure the OAuth consent screen first:
     - Choose **External** user type
     - Fill in app name, support email, developer contact
     - Add scopes: `email`, `profile`
     - Add test users (optional for testing)

5. Create OAuth client IDs:
   - **Web application** (for Supabase):
     - Name: "VolHub Web"
     - Authorized redirect URIs: 
       - `https://qvnqlfgifuerdqebbvol.supabase.co/auth/v1/callback`
       - (Replace with your Supabase project URL) 
   
   - **Android application** (for Flutter Android):
     - Name: "VolHub Android"
     - Package name: Check your `android/app/build.gradle` for `applicationId`
     - SHA-1 certificate fingerprint: Get it using:
       ```bash
       # For debug keystore
       keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
       
       # For release keystore (if you have one)
       keytool -list -v -keystore android/app/keystore.jks -alias your-alias
       ```
   
   - **iOS application** (for Flutter iOS):
     - Name: "VolHub iOS"
     - Bundle ID: Check your `ios/Runner.xcodeproj` or `ios/Runner/Info.plist`

6. **Save the Client ID and Client Secret** - You'll need these for Supabase

## Step 2: Configure Google Provider in Supabase

1. Go to your Supabase project dashboard
2. Navigate to **Authentication** → **Providers**
3. Find **Google** in the list and click to expand
4. Enable Google provider
5. Enter your Google OAuth credentials:
   - **Client ID (for OAuth)**: Your Google Web Client ID
   - **Client Secret (for OAuth)**: Your Google Web Client Secret
6. Click **Save**

## Step 3: Configure Redirect URLs in Supabase

1. In Supabase dashboard, go to **Authentication** → **URL Configuration**
2. Add your redirect URLs:
   - `io.supabase.volhub://login-callback` (for mobile deep linking)
   - `com.volhub.app://login-callback` (alternative, if different)
   - Your custom domain callback URL (if using web)

## Step 4: Configure Deep Linking in Flutter

### For Android:

1. Open `android/app/src/main/AndroidManifest.xml`
2. Add intent filter inside the `<activity>` tag:
   ```xml
   <activity
       android:name=".MainActivity"
       ...>
       <!-- Existing intent filters -->
       
       <!-- Deep linking for OAuth callback -->
       <intent-filter>
           <action android:name="android.intent.action.VIEW" />
           <category android:name="android.intent.category.DEFAULT" />
           <category android:name="android.intent.category.BROWSABLE" />
           <data
               android:scheme="io.supabase.volhub"
               android:host="login-callback" />
       </intent-filter>
   </activity>
   ```

### For iOS:

1. Open `ios/Runner/Info.plist`
2. Add URL scheme:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleTypeRole</key>
           <string>Editor</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>io.supabase.volhub</string>
           </array>
       </dict>
   </array>
   ```

## Step 5: Handle OAuth Callback in Flutter (Optional)

For better deep linking support, you can add the `app_links` package:

1. Add to `pubspec.yaml`:
   ```yaml
   dependencies:
     app_links: ^6.4.1
   ```

2. Update `main.dart` to handle deep links:
   ```dart
   import 'package:app_links/app_links.dart';
   
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     
     await Supabase.initialize(...);
     
     // Handle deep links for OAuth
     final appLinks = AppLinks();
     appLinks.uriLinkStream.listen((uri) {
       if (uri.toString().contains('login-callback')) {
         Supabase.instance.client.auth.getSessionFromUrl(uri);
       }
     });
     
     runApp(MyApp());
   }
   ```

3. Run `flutter pub get`

## Step 6: Test Google Authentication

1. Run your app: `flutter run`
2. Click "Continue with Google" button
3. You should be redirected to Google sign-in page
4. After signing in, you'll be redirected back to your app
5. Check if the user is authenticated

## Troubleshooting

### "Redirect URI mismatch" error
- Make sure the redirect URI in Google Console matches exactly with Supabase
- Check that the deep link scheme matches in AndroidManifest.xml and Info.plist

### "OAuth client not found" error
- Verify your Client ID and Client Secret in Supabase dashboard
- Make sure Google+ API is enabled in Google Cloud Console

### Deep link not working
- Check that the URL scheme is correctly configured
- Test the deep link manually: `adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://login-callback"`

### User not redirected back to app
- Verify redirect URLs in Supabase dashboard
- Check that the deep link scheme matches in all configuration files

## Security Notes

⚠️ **Important**:
- Never commit your OAuth Client Secret to version control
- Use environment variables for sensitive credentials in production
- Regularly rotate your OAuth credentials
- Enable 2FA on your Google Cloud Console account

## Additional Resources

- [Supabase OAuth Documentation](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Google OAuth Setup](https://developers.google.com/identity/protocols/oauth2)
- [Flutter Deep Linking](https://docs.flutter.dev/development/ui/navigation/deep-linking)
