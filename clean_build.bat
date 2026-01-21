@echo off
echo Killing Dart, Flutter, and Browser processes...
taskkill /F /IM dart.exe /T >nul 2>&1
taskkill /F /IM flutter.exe /T >nul 2>&1
taskkill /F /IM java.exe /T >nul 2>&1
taskkill /F /IM chrome.exe /T >nul 2>&1
taskkill /F /IM msedge.exe /T >nul 2>&1

echo Clearing build artifacts...
:retry_build
if exist "build" (
    rd /s /q "build" >nul 2>&1
    if exist "build" (
        echo Build directory locked, retrying in 2 seconds...
        timeout /t 2 >nul
        goto retry_build
    )
)

:retry_tool
if exist ".dart_tool" (
    rd /s /q ".dart_tool" >nul 2>&1
    if exist ".dart_tool" (
        echo .dart_tool directory locked, retrying in 2 seconds...
        timeout /t 2 >nul
        goto retry_tool
    )
)

echo Restoring dependencies...
call flutter pub get

echo Done! The workspace is clear. 
echo Suggestion: Run 'flutter run -d chrome' to start fresh.
