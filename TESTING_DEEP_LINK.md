# Testing Deep Link - Troubleshooting Guide

## Your ADB Command Worked! ✅

The output you saw:
```
Status: ok
Activity: com.example.main_volhub/.MainActivity
```

This means the deep link was **successfully delivered** to your app!

## What Should Happen Now

After running the ADB command, your app should:
1. Open (if not already open)
2. Navigate to the Reset Password page automatically

## If the App Didn't Navigate

I've updated the code to better handle deep links. Try these steps:

### Step 1: Rebuild Your App

The code changes need to be compiled:

```powershell
flutter clean
flutter run
```

### Step 2: Test the Deep Link Again

Once your app is running, in a **new terminal/PowerShell window**, run:

```powershell
C:\Android\Sdk\platform-tools\adb.exe shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://reset-password"
```

### Step 3: Check the Logs

Watch the Flutter console/logs. You should see debug messages like:
```
=== Deep link received: io.supabase.volhub://reset-password ===
Processing reset-password deep link
Navigated to /reset-password
```

## Debugging Steps

### Check if Deep Link is Being Received

1. Keep `flutter run` running in one terminal
2. Watch the console output
3. Run the ADB command in another terminal
4. Look for "Deep link received" messages

### If You Don't See Navigation

1. **Check the route exists**: Make sure `/reset-password` is in your routes
2. **Check navigator key**: The navigatorKey should be set in MaterialApp
3. **Check logs**: Look for any error messages

### Test Navigation Manually

To verify the route works, you can temporarily add a button in your app:

```dart
ElevatedButton(
  onPressed: () {
    Navigator.pushNamed(context, '/reset-password');
  },
  child: Text('Test Reset Password'),
)
```

If this button works, the route is fine and it's a deep link handling issue.

## Common Issues

### Issue: "Warning: Activity not started, intent has been delivered to currently running top-most instance"

**This is actually GOOD!** It means:
- ✅ The deep link was received
- ✅ The app is already running
- ✅ The intent was delivered

The app should process it via `uriLinkStream.listen()`. If it doesn't navigate, check the logs.

### Issue: App Opens But Doesn't Navigate

**Possible causes:**
1. Navigator key not ready yet (added delay in code)
2. Route not registered (check routes in main.dart)
3. Deep link handler not catching it (check logs)

**Solution:** The updated code now:
- Handles initial links
- Handles links when app is running
- Adds delays to ensure navigator is ready
- Better logging for debugging

### Issue: No Logs Appear

**Possible causes:**
1. App not running in debug mode
2. Logs not visible
3. Deep link not being received

**Solution:**
- Make sure you're running `flutter run` (not release mode)
- Check both terminals (one for flutter run, one for ADB)
- Try restarting the app

## Expected Behavior

### When App is Closed:
1. Run ADB command
2. App opens
3. App navigates to Reset Password page

### When App is Already Running:
1. Run ADB command
2. App receives deep link (you'll see it in logs)
3. App navigates to Reset Password page

## Quick Test Sequence

```powershell
# Terminal 1: Run your app
flutter run

# Terminal 2: Test deep link
C:\Android\Sdk\platform-tools\adb.exe shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://reset-password"

# Watch Terminal 1 for logs
```

## Still Not Working?

1. **Verify the route exists:**
   - Check `main.dart` line 125: `/reset-password` should be in routes

2. **Check AndroidManifest.xml:**
   - Verify intent filter for reset-password exists

3. **Check logs:**
   - Look for "Deep link received" message
   - Look for "Navigated to /reset-password" message
   - Look for any error messages

4. **Try hot restart:**
   - Press `R` in the Flutter console (capital R for hot restart)
   - Then test the deep link again

5. **Full rebuild:**
   ```powershell
   flutter clean
   flutter pub get
   flutter run
   ```

## Success Indicators

You'll know it's working when:
- ✅ You see "Deep link received" in logs
- ✅ You see "Navigated to /reset-password" in logs
- ✅ The Reset Password page appears on screen
- ✅ You can enter a new password

## Next Steps After It Works

Once the deep link works with ADB:
1. Test with a real password reset email
2. The flow will be the same - Supabase will redirect to the deep link
3. Your app will handle it the same way

The ADB command simulates exactly what happens when a user clicks the reset link in their email!

