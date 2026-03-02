# Share VolHub App Script
# This script builds the debug APK, uploads it to Catbox.moe, and generates a QR code.

$APK_PATH = "build/app/outputs/flutter-apk/app-debug.apk"
$CURL_PATH = "C:\Windows\System32\curl.exe"

Write-Host "--- 1. Building Flutter Debug APK ---" -ForegroundColor Cyan
flutter build apk --debug

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Flutter build failed." -ForegroundColor Red
    exit $LASTEXITCODE
}

if (-Not (Test-Path $APK_PATH)) {
    Write-Host "Error: APK not found at $APK_PATH" -ForegroundColor Red
    exit 1
}

Write-Host "--- 2. Uploading APK ---" -ForegroundColor Cyan
$UPLOAD_SUCCESS = $false
$UPLOAD_LINK = ""

# Try Catbox first
Write-Host "Attempting upload to Catbox.moe..." -ForegroundColor Gray
$UPLOAD_LINK = & $CURL_PATH -F "reqtype=fileupload" -F "fileToUpload=@$APK_PATH" https://catbox.moe/user/api.php
if ($LASTEXITCODE -eq 0 -and $UPLOAD_LINK.StartsWith("https")) {
    $UPLOAD_SUCCESS = $true
}
else {
    Write-Host "Catbox upload failed. Attempting fallback to BashUpload..." -ForegroundColor Yellow
    # Fallback to BashUpload
    $UPLOAD_LINK = & $CURL_PATH --upload-file "$APK_PATH" https://bashupload.com/volhub-debug.apk
    if ($LASTEXITCODE -eq 0 -and $UPLOAD_LINK.Contains("https")) {
        # BashUpload returns a full message, extract the link
        if ($UPLOAD_LINK -match "(https://bashupload\.com/[^\s]+)") {
            $UPLOAD_LINK = $matches[1]
            $UPLOAD_SUCCESS = $true
        }
    }

    if (-not $UPLOAD_SUCCESS) {
        Write-Host "BashUpload failed. Attempting final fallback to file.io..." -ForegroundColor Yellow
        $UPLOAD_LINK_RAW = & $CURL_PATH -F "file=@$APK_PATH" https://file.io
        if ($LASTEXITCODE -eq 0 -and $UPLOAD_LINK_RAW -match '"link":"([^"]+)"') {
            $UPLOAD_LINK = $matches[1]
            $UPLOAD_SUCCESS = $true
        }
    }
}

if (-not $UPLOAD_SUCCESS) {
    Write-Host "Error: All upload attempts failed." -ForegroundColor Red
    exit 1
}

# Save link for retrieval
$UPLOAD_LINK | Out-File -FilePath "app_link.txt" -Encoding utf8

Write-Host "--- 3. Success! ---" -ForegroundColor Green
Write-Host "Download Link: $UPLOAD_LINK" -ForegroundColor Yellow

$QR_API = "https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=$UPLOAD_LINK"
Write-Host "QR Code Image: $QR_API" -ForegroundColor Yellow

Write-Host "`nScan the QR code above or open the link in your mobile browser to install." -ForegroundColor White
