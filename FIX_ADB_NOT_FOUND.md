# Fix "adb is not recognized" Error

This guide helps you fix the "adb is not recognized" error in PowerShell/Command Prompt.

## Quick Solution: Find and Use Full Path to ADB

### Step 1: Find Where ADB is Installed

ADB is usually located in one of these places:

**Common Locations:**
- `C:\Users\Steve M Thomas\AppData\Local\Android\Sdk\platform-tools\adb.exe`
- `C:\Android\Sdk\platform-tools\adb.exe`
- `C:\Program Files\Android\android-sdk\platform-tools\adb.exe`
- Inside Android Studio installation folder

### Step 2: Check if ADB Exists

Run this in PowerShell to find ADB:

```powershell
# Try to find ADB in common locations
Get-ChildItem -Path "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" -ErrorAction SilentlyContinue
Get-ChildItem -Path "C:\Android\Sdk\platform-tools\adb.exe" -ErrorAction SilentlyContinue
Get-ChildItem -Path "C:\Program Files\Android\android-sdk\platform-tools\adb.exe" -ErrorAction SilentlyContinue
```

### Step 3: Use Full Path to ADB

Once you find ADB, use the full path in your commands:

**Example (replace with your actual path):**
```powershell
& "C:\Users\Steve M Thomas\AppData\Local\Android\Sdk\platform-tools\adb.exe" devices
```

**For the deep link command:**
```powershell
& "C:\Users\Steve M Thomas\AppData\Local\Android\Sdk\platform-tools\adb.exe" shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://reset-password"
```

## Solution 1: Find ADB Automatically (Recommended)

Run this PowerShell script to find and use ADB:

```powershell
# Search for adb.exe
$adbPath = Get-ChildItem -Path "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" -ErrorAction SilentlyContinue

if (-not $adbPath) {
    $adbPath = Get-ChildItem -Path "C:\Android\Sdk\platform-tools\adb.exe" -ErrorAction SilentlyContinue
}

if (-not $adbPath) {
    $adbPath = Get-ChildItem -Path "C:\Program Files\Android\android-sdk\platform-tools\adb.exe" -ErrorAction SilentlyContinue
}

if ($adbPath) {
    Write-Host "Found ADB at: $($adbPath.FullName)" -ForegroundColor Green
    Write-Host "Testing connection..." -ForegroundColor Yellow
    & $adbPath.FullName devices
} else {
    Write-Host "ADB not found. Please install Android SDK Platform Tools." -ForegroundColor Red
}
```

## Solution 2: Add ADB to PATH (Permanent Fix)

### For Current PowerShell Session Only:

```powershell
# Find ADB first
$adbDir = "$env:LOCALAPPDATA\Android\Sdk\platform-tools"
if (Test-Path $adbDir) {
    $env:Path += ";$adbDir"
    Write-Host "ADB added to PATH for this session" -ForegroundColor Green
    adb devices
} else {
    Write-Host "ADB not found at: $adbDir" -ForegroundColor Red
}
```

### For Permanent Fix (All Future Sessions):

1. **Find your ADB path** (usually: `C:\Users\Steve M Thomas\AppData\Local\Android\Sdk\platform-tools`)

2. **Add to System PATH:**
   - Press `Win + Pause` to open System Properties
   - Click "Advanced system settings"
   - Click "Environment Variables"
   - Under "System variables", find "Path" and click "Edit"
   - Click "New" and add: `C:\Users\Steve M Thomas\AppData\Local\Android\Sdk\platform-tools`
   - Click OK on all dialogs
   - **Close and reopen PowerShell/Command Prompt**

3. **Verify:**
   ```powershell
   adb devices
   ```

## Solution 3: Use Flutter's ADB (Easier)

Flutter comes with its own tools. You can use Flutter to run ADB commands:

```powershell
# Check if Flutter can find ADB
flutter doctor -v

# Flutter uses ADB internally, so you can also just use Flutter commands
flutter devices
```

## Solution 4: Create an Alias (PowerShell)

Add this to your PowerShell profile to create an `adb` alias:

```powershell
# Find your PowerShell profile
$PROFILE

# Edit the profile (create if it doesn't exist)
notepad $PROFILE

# Add this line (adjust path if needed):
function adb { & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" $args }

# Save and reload
. $PROFILE
```

Now you can use `adb` normally!

## Quick Test Commands (Using Full Path)

Once you find your ADB path, replace `YOUR_ADB_PATH` with the actual path:

```powershell
# Check devices
& "YOUR_ADB_PATH\adb.exe" devices

# Test reset password deep link
& "YOUR_ADB_PATH\adb.exe" shell am start -W -a android.intent.action.VIEW -d "io.supabase.volhub://reset-password"
```

## Alternative: Use Android Studio

If you have Android Studio installed:

1. Open Android Studio
2. Go to **Tools** → **SDK Manager**
3. Check **SDK Tools** tab
4. Make sure **Android SDK Platform-Tools** is installed
5. The path will be shown in **SDK Location**

## Still Can't Find ADB?

1. **Install Android SDK Platform Tools:**
   - Download from: https://developer.android.com/studio/releases/platform-tools
   - Extract to a folder (e.g., `C:\platform-tools`)
   - Use that path in commands

2. **Or use Android Studio:**
   - Open Android Studio
   - Go to **Tools** → **SDK Manager**
   - Install **Android SDK Platform-Tools**

## Recommended: Quick PowerShell Script

Save this as `test-adb.ps1` and run it:

```powershell
# Find ADB
$possiblePaths = @(
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    "C:\Android\Sdk\platform-tools\adb.exe",
    "C:\Program Files\Android\android-sdk\platform-tools\adb.exe"
)

$adbPath = $null
foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $adbPath = $path
        break
    }
}

if ($adbPath) {
    Write-Host "Found ADB at: $adbPath" -ForegroundColor Green
    Write-Host "`nTesting connection..." -ForegroundColor Yellow
    & $adbPath devices
    
    Write-Host "`nTo use ADB, run:" -ForegroundColor Cyan
    Write-Host "& `"$adbPath`" <command>" -ForegroundColor White
    Write-Host "`nExample:" -ForegroundColor Cyan
    Write-Host "& `"$adbPath`" shell am start -W -a android.intent.action.VIEW -d `"io.supabase.volhub://reset-password`"" -ForegroundColor White
} else {
    Write-Host "ADB not found. Please install Android SDK Platform Tools." -ForegroundColor Red
    Write-Host "Download from: https://developer.android.com/studio/releases/platform-tools" -ForegroundColor Yellow
}
```

