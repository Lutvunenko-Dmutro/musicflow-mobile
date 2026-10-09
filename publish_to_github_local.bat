@echo off
setlocal EnableDelayedExpansion

echo ===============================================================================
echo 🚀 MusicFlow Mobile - RELEASE PUBLISHER
echo ===============================================================================
echo.
echo Choose publication method:
echo [1] Local Build (Fast, uses your PC, no GitHub Actions minutes)
echo [2] GitHub Actions (Runs on GitHub servers, runs tests automatically)
echo.
set /p BUILD_MODE="Your choice (1 or 2): "

if "!BUILD_MODE!" neq "1" if "!BUILD_MODE!" neq "2" (
    echo ERROR: Invalid choice!
    pause
    exit /b 1
)

:: Check if gh CLI is installed
where gh >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: GitHub CLI (gh) not found.
    echo Please install it: winget install --id GitHub.cli
    echo After installation, authorize: gh auth login
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

:: ==========================================
:: LOCAL BUILD (OPTION 1)
:: ==========================================
echo.
echo [1/5] Updating pubspec.yaml...
python -c "import re; content = open('pubspec.yaml', 'r', encoding='utf-8').read(); content = re.sub(r'version: .*', f'version: !VERSION_NAME!+!BUILD_NUM!', content); open('pubspec.yaml', 'w', encoding='utf-8').write(content)"

echo.
echo [2/5] Running tests and code analysis...
call flutter analyze
if %errorlevel% neq 0 (
    echo ERROR: flutter analyze failed. Fix errors before release!
    pause
    exit /b 1
)

call flutter test
if %errorlevel% neq 0 (
    echo ERROR: flutter test failed. Fix tests before release!
    pause
    exit /b 1
)

echo.
echo [3/5] Building Release and Debug APK...
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

echo.
echo [4/5] Calculating SHA-256...
for /f "skip=1 tokens=* delims=" %%a in ('certutil -hashfile "build\app\outputs\flutter-apk\app-release.apk" SHA256') do (
    if not defined SHA256 (
        set SHA256=%%a
    )
)
set SHA256=!SHA256: =!
echo SHA-256: !SHA256!

echo.
echo [5/5] Pushing code and creating GitHub Release...
git add pubspec.yaml
git commit -m "chore: bump version to v!VERSION_NAME!"
git push origin main

:: Create release notes file
echo !CHANGELOG! > release_notes.txt
echo. >> release_notes.txt
echo **SHA-256 (Release):** `!SHA256!` >> release_notes.txt

:: Publish via GitHub CLI
gh release create v!VERSION_NAME! build\app\outputs\flutter-apk\app-release.apk build\app\outputs\flutter-apk\app-debug.apk --title "MusicFlow v!VERSION_NAME! (build !BUILD_NUM!)" --notes-file release_notes.txt
del release_notes.txt

echo.
echo ===============================================================================
echo DONE! Release v!VERSION_NAME! built locally and published to GitHub!
echo ===============================================================================
pause
exit /b 0

:: ==========================================
:: GITHUB ACTIONS BUILD (OPTION 2)
:: ==========================================
:GITHUB_BUILD
echo.
echo Sending command to GitHub Actions...
gh workflow run ci.yml -f release_version="v!VERSION_NAME!" -f build_number="!BUILD_NUM!" -f release_notes="!CHANGELOG!"

if %errorlevel% neq 0 (
    echo ERROR: Failed to run GitHub Actions. Check gh auth status.
    pause
    exit /b 1
)

echo.
echo ===============================================================================
echo COMMAND SENT!
echo GitHub Actions has started working.
echo It will update pubspec.yaml, run tests, build both APKs and publish release.
echo You can track the progress here:
echo https://github.com/Lutvunenko-Dmutro/musicflow-mobile/actions
echo ===============================================================================
pause
exit /b 0
