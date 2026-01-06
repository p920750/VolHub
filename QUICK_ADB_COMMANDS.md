# Quick ADB Commands for Your Setup

Since your Android SDK is at `C:\Android\Sdk`, use these commands:

## Step 1: Check if Emulator is Running

```powershell
C:\Android\Sdk\platform-tools\adb.exe devices
```

**Expected output if emulator is running:**
```
List of devices attached
emulator-5554    device
```

**If you see "List of devices attached" with nothing below:**
- Start your emulator first
- Or run `flutter run` which will start the emulator

## Step 2: Test Reset Password Deep Link

Once your emulator is running and your app is installed, run:

```powershell
C:\Android\Sdk\platform-tools\adb.exe shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://reset-password"
```

This should open your app and navigate to the Reset Password page!

## Step 3: Test with Auth Tokens (After Requesting Real Reset)

After requesting a password reset from your app, use the tokens from the email:

```powershell
C:\Android\Sdk\platform-tools\adb.exe shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://reset-password#access_token=YOUR_TOKEN&refresh_token=YOUR_REFRESH_TOKEN&type=recovery"
```

## Quick Reference - All Commands

```powershell
# Check devices
C:\Android\Sdk\platform-tools\adb.exe devices

# Test reset password (simple)
C:\Android\Sdk\platform-tools\adb.exe shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://reset-password"

# Test email confirmation
C:\Android\Sdk\platform-tools\adb.exe shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://email-confirm"

# View logs
C:\Android\Sdk\platform-tools\adb.exe logcat | findstr flutter
```

## Make It Easier: Create an Alias

To avoid typing the full path every time, create a PowerShell alias:

**For current session only:**
```powershell
function adb { & "C:\Android\Sdk\platform-tools\adb.exe" $args }
```

Now you can just use:
```powershell
adb devices
adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://reset-password"
```

**To make it permanent**, add the function to your PowerShell profile:
```powershell
# Open profile
notepad $PROFILE

# Add this line:
function adb { & "C:\Android\Sdk\platform-tools\adb.exe" $args }

# Save and reload
. $PROFILE
```

## Troubleshooting

### "List of devices attached" (but no devices listed)
- Make sure your emulator is running
- Start emulator from Android Studio or run `flutter run`

### "App doesn't open"
- Make sure your app is installed: `flutter install`
- Rebuild the app: `flutter clean && flutter run`

### "No app can handle this"
- Verify the intent filter is in `AndroidManifest.xml`
- Rebuild the app after making changes

