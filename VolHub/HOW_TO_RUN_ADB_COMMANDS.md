# How to Run ADB Commands for Testing Deep Links

This guide shows you exactly how to run the ADB commands to test password reset deep links on your Android emulator.

## Prerequisites

1. **Android Emulator must be running**
   - Start your emulator from Android Studio, or
   - Run `flutter run` which will start the emulator automatically

2. **ADB (Android Debug Bridge) must be installed**
   - Usually comes with Android Studio
   - Or install Android SDK Platform Tools separately

3. **Your Flutter app should be installed on the emulator**
   - Run `flutter run` at least once to install the app

## Step-by-Step Instructions

### Step 1: Open Terminal/Command Prompt

**On Windows:**
- Press `Win + R`, type `cmd` and press Enter, OR
- Press `Win + X` and select "Terminal" or "Command Prompt", OR
- Open PowerShell

**On Mac/Linux:**
- Press `Cmd + Space`, type "Terminal" and press Enter, OR
- Open Terminal from Applications

### Step 2: Navigate to Your Project (Optional)

You don't need to be in your project folder, but it's good practice:
```bash
cd "C:\Users\Steve M Thomas\OneDrive\Documents\Visual Studio Code\.vscode\Flutter\Room_Mate\Volhub\main_volhub"
```

### Step 3: Check if ADB is Available

Test if ADB is installed and can see your emulator:
```bash
adb devices
```

**Expected output:**
```
List of devices attached
emulator-5554    device
```

If you see your emulator listed, you're good to go! If not:
- Make sure your emulator is running
- Check if ADB is in your PATH (see troubleshooting below)

### Step 4: Make Sure Your App is Running

Start your Flutter app on the emulator:
```bash
flutter run
```

Wait until the app is fully loaded and visible on the emulator.

### Step 5: Run the Deep Link Command

**Option 1: Simple Test (No Auth Tokens)**
```bash
adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://reset-password"
```

**Option 2: With Test Tokens (As shown in the guide)**
```bash
adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://reset-password?access_token=test_token&refresh_token=test_refresh&type=recovery"
```

**Option 3: With Fragment (Hash) Instead of Query Parameters**
```bash
adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://reset-password#access_token=test_token&refresh_token=test_refresh&type=recovery"
```

### Step 6: What Should Happen

1. The command should execute without errors
2. Your app should automatically open (if it wasn't already)
3. The app should navigate to the Reset Password page
4. You should see the password reset form

## Complete Example Session

Here's what a complete session looks like:

```bash
# 1. Check if emulator is connected
C:\Users\Steve M Thomas> adb devices
List of devices attached
emulator-5554    device

# 2. Navigate to project (optional)
C:\Users\Steve M Thomas> cd "OneDrive\Documents\Visual Studio Code\.vscode\Flutter\Room_Mate\Volhub\main_volhub"

# 3. Run the deep link command
C:\Users\Steve M Thomas\...\main_volhub> adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://reset-password"

# 4. App should open automatically!
```

## Troubleshooting

### "adb: command not found" or "adb is not recognized"

**Windows:**
1. Find where Android SDK is installed (usually):
   - `C:\Users\YourName\AppData\Local\Android\Sdk\platform-tools`
   - Or `C:\Android\Sdk\platform-tools`

2. Add to PATH:
   - Press `Win + Pause` → Advanced System Settings → Environment Variables
   - Under "System Variables", find "Path" and click "Edit"
   - Click "New" and add the path: `C:\Users\YourName\AppData\Local\Android\Sdk\platform-tools`
   - Click OK on all dialogs
   - **Restart your terminal/command prompt**

3. Or use full path:
   ```bash
   C:\Users\YourName\AppData\Local\Android\Sdk\platform-tools\adb.exe shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://reset-password"
   ```

**Mac/Linux:**
1. Add to PATH in `~/.bashrc` or `~/.zshrc`:
   ```bash
   export PATH=$PATH:$HOME/Library/Android/sdk/platform-tools
   ```
2. Reload: `source ~/.bashrc` or `source ~/.zshrc`

### "error: no devices/emulators found"

- Make sure your emulator is running
- Check with: `adb devices`
- If emulator is running but not listed, try:
  ```bash
  adb kill-server
  adb start-server
  adb devices
  ```

### "App doesn't open" or "No app can handle this"

- Make sure your app is installed: `flutter install`
- Rebuild the app: `flutter clean && flutter run`
- Verify the intent filter is in `AndroidManifest.xml`

### Command runs but app shows blank screen

- Check Flutter logs: `flutter logs` (in another terminal)
- Or check Android logs: `adb logcat | grep flutter`
- Make sure the route `/reset-password` exists in your `main.dart`

## Quick Reference Commands

```bash
# Check emulator connection
adb devices

# Test reset password deep link (simple)
adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://reset-password"

# Test reset password deep link (with tokens)
adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://reset-password#access_token=test&refresh_token=test&type=recovery"

# Test email confirmation deep link
adb shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://email-confirm"

# View app logs
adb logcat | grep flutter

# Restart ADB server
adb kill-server
adb start-server
```

## Alternative: Use Flutter's Built-in Deep Link Testing

You can also test deep links directly from Flutter:

1. Keep your app running with `flutter run`
2. In the Flutter console, you can manually trigger navigation
3. Or add a test button in your app that navigates to the reset password page

But using ADB is the most accurate way to simulate clicking an email link.

## Need More Help?

- Check `EMULATOR_DEEP_LINK_TESTING.md` for more detailed testing scenarios
- Check `PASSWORD_RESET_SETUP.md` for Supabase configuration
- Check Flutter logs for any errors: `flutter logs`

