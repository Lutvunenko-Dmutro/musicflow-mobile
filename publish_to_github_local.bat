@echo off
setlocal EnableDelayedExpansion

echo ===============================================================================
echo [ MusicFlow Mobile - RELEASE PUBLISHER ]
echo ===============================================================================
echo.
echo Choose publication method:
echo [1] Local Build (Fast, uses your PC)
echo [2] GitHub Actions (Runs on GitHub servers)
echo.
set /p BUILD_MODE="Your choice (1 or 2): "

if "!BUILD_MODE!" neq "1" if "!BUILD_MODE!" neq "2" (
    echo ERROR: Invalid choice!
    pause
    exit /b 1
)

where gh >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: GitHub CLI (gh) not found.
    pause
    exit /b 1
)

echo.
set /p VERSION_NAME="Enter new version (e.g., 1.0.39): "
if "!VERSION_NAME!"=="" (
    echo ERROR: Version cannot be empty!
    pause
    exit /b 1
)

set /p BUILD_NUM="Enter build number (e.g., 40): "
if "!BUILD_NUM!"=="" (
    echo ERROR: Build number cannot be empty!
    pause
    exit /b 1
)

set /p CHANGELOG="Enter changelog: "
if "!CHANGELOG!"=="" set CHANGELOG=Update MusicFlow v!VERSION_NAME!

if "!BUILD_MODE!"=="2" goto GITHUB_BUILD

echo [1/5] Updating pubspec.yaml...
python -c "import re; content = open('pubspec.yaml', 'r', encoding='utf-8').read(); content = re.sub(r'version: .*', f'version: !VERSION_NAME!+!BUILD_NUM!', content); open('pubspec.yaml', 'w', encoding='utf-8').write(content)"
if %errorlevel% neq 0 (
    echo ERROR: Failed to update pubspec.yaml
    pause
    exit /b 1
)

echo [2/5] Running tests...
call flutter analyze
if %errorlevel% neq 0 (
    echo ERROR: flutter analyze failed!
    pause
    exit /b 1
)

call flutter test
if %errorlevel% neq 0 (
    echo ERROR: flutter test failed!
    pause
    exit /b 1
)

echo [3/5] Building APKs...
call flutter build apk --release --build-name=!VERSION_NAME! --build-number=!BUILD_NUM!
if %errorlevel% neq 0 (
    echo ERROR: Release build failed!
    pause
    exit /b 1
)

call flutter build apk --debug --build-name=!VERSION_NAME! --build-number=!BUILD_NUM!
if %errorlevel% neq 0 (
    echo ERROR: Debug build failed!
    pause
    exit /b 1
)

echo [4/5] Calculating SHA-256...
set SHA256=
for /f "skip=1 tokens=* delims=" %%a in ('certutil -hashfile "build\app\outputs\flutter-apk\app-release.apk" SHA256') do (
    if "!SHA256!"=="" set SHA256=%%a
)
set SHA256=!SHA256: =!
echo SHA-256: !SHA256!

echo [5/5] Pushing code and creating GitHub Release...
git add pubspec.yaml
git commit -m "chore: bump version to v!VERSION_NAME!"
git push origin main

echo !CHANGELOG! > release_notes.txt
echo. >> release_notes.txt
echo **SHA-256 (Release):** `!SHA256!` >> release_notes.txt

gh release create v!VERSION_NAME! build\app\outputs\flutter-apk\app-release.apk build\app\outputs\flutter-apk\app-debug.apk --title "MusicFlow v!VERSION_NAME! (build !BUILD_NUM!)" --notes-file release_notes.txt
if %errorlevel% neq 0 (
    echo ERROR: GitHub release creation failed!
    pause
    exit /b 1
)

del release_notes.txt
echo DONE!
pause
exit /b 0

:GITHUB_BUILD
echo Sending command to GitHub Actions...
gh workflow run ci.yml -f release_version="v!VERSION_NAME!" -f build_number="!BUILD_NUM!" -f release_notes="!CHANGELOG!"
if %errorlevel% neq 0 (
    echo ERROR: Failed to trigger GitHub Action!
    pause
    exit /b 1
)
echo COMMAND SENT!
pause
exit /b 0
