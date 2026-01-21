# How to Run the Flutter App on Your Laptop

## Quick Start

You have Flutter installed and ready! Here are the ways to run your app:

### Option 1: Run on Windows Desktop (Recommended)
This will run the app as a native Windows application:

```bash
flutter run -d windows
```

### Option 2: Run in Chrome Browser
This will run the app in your Chrome browser:

```bash
flutter run -d chrome
```

### Option 3: Run in Edge Browser
This will run the app in your Edge browser:

```bash
flutter run -d edge
```

## Step-by-Step Instructions

### 1. Open Terminal/Command Prompt
- In VS Code, you can use the integrated terminal (Terminal → New Terminal)
- Or open PowerShell/Command Prompt

### 2. Navigate to Project Directory (if not already there)
```bash
cd "C:\Users\Steve M Thomas\OneDrive\Documents\Visual Studio Code\.vscode\Flutter\Room_Mate\Volhub\main_volhub"
```

### 3. Run the App
Choose one of the options above. For example, to run on Windows:
```bash
flutter run -d windows
```

The first time you run, it may take a few minutes to build. Subsequent runs will be faster.

## Building an Installable App

### For Windows Desktop (Creates an .exe installer)
```bash
flutter build windows
```

The built app will be in: `build\windows\x64\runner\Release\`

### For Web (Creates deployable web files)
```bash
flutter build web
```

The built files will be in: `build\web\`

## Troubleshooting

### If you get errors:
1. **Check Flutter setup:**
   ```bash
   flutter doctor
   ```
   This will show any missing dependencies or configuration issues.

2. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run -d windows
   ```

3. **Check for device availability:**
   ```bash
   flutter devices
   ```

## Available Devices
Currently detected:
- ✅ Windows (desktop)
- ✅ Chrome (web)
- ✅ Edge (web)

## Notes
- The app uses Supabase for backend services, so make sure you have internet connection
- First build may take 5-10 minutes
- Hot reload is available during development (press `r` in terminal to reload)

