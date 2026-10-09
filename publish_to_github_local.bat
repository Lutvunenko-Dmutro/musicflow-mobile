@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion

echo ===============================================================================
echo 🚀 MusicFlow Mobile - ПУБЛІКАЦІЯ РЕЛІЗУ
echo ===============================================================================
echo.
echo Оберіть спосіб публікації:
echo [1] 💻 Локальна збірка (Швидко, не витрачає хвилини GitHub, збирає на цьому ПК)
echo [2] ☁️  GitHub Actions (Робить все самостійно на серверах GitHub, запускає тести)
echo.
set /p BUILD_MODE="Ваш вибір (1 або 2): "

if "!BUILD_MODE!" neq "1" if "!BUILD_MODE!" neq "2" (
    echo ❌ Невірний вибір!
    pause
    exit /b 1
)

:: Перевірка чи встановлений gh
where gh >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ ПОМИЛКА: Не знайдено GitHub CLI ^(gh^).
    echo Будь ласка, встановіть його: winget install --id GitHub.cli
    echo Після встановлення авторизуйтеся: gh auth login
    pause
    exit /b 1
)

echo.
set /p VERSION_NAME="Введіть нову версію (наприклад, 1.0.39): "
if "!VERSION_NAME!"=="" (
    echo ❌ Версія не може бути порожньою!
    pause
    exit /b 1
)

set /p BUILD_NUM="Введіть номер білда (наприклад, 40): "
if "!BUILD_NUM!"=="" (
    echo ❌ Номер білда не може бути порожнім!
    pause
    exit /b 1
)

set /p CHANGELOG="Введіть опис змін (Changelog): "
if "!CHANGELOG!"=="" set CHANGELOG=Оновлення MusicFlow v!VERSION_NAME!

if "!BUILD_MODE!"=="2" goto GITHUB_BUILD

:: ==========================================
:: ЛОКАЛЬНА ЗБІРКА (ОПЦІЯ 1)
:: ==========================================
echo.
echo ⏳ [1/5] Оновлюю pubspec.yaml...
python -c "import re; content = open('pubspec.yaml', 'r', encoding='utf-8').read(); content = re.sub(r'version: .*', f'version: !VERSION_NAME!+!BUILD_NUM!', content); open('pubspec.yaml', 'w', encoding='utf-8').write(content)"

echo.
echo ⏳ [2/5] Проганяю тести та аналіз коду...
call flutter analyze
if %errorlevel% neq 0 (
    echo ❌ Помилка аналізу коду (flutter analyze). Виправте помилки перед релізом!
    pause
    exit /b 1
)

call flutter test
if %errorlevel% neq 0 (
    echo ❌ Деякі тести не пройшли (flutter test). Виправте їх перед релізом!
    pause
    exit /b 1
)

echo.
echo ⏳ [3/5] Збираю Release та Debug APK...
call flutter build apk --release --build-name=!VERSION_NAME! --build-number=!BUILD_NUM!
if %errorlevel% neq 0 (
    echo ❌ Помилка збірки Release!
    pause
    exit /b 1
)

call flutter build apk --debug --build-name=!VERSION_NAME! --build-number=!BUILD_NUM!
if %errorlevel% neq 0 (
    echo ❌ Помилка збірки Debug!
    pause
    exit /b 1
)

echo.
echo ⏳ [4/5] Розрахунок SHA-256...
for /f "tokens=*" %%a in ('certutil -hashfile "build\app\outputs\flutter-apk\app-release.apk" SHA256 ^| findstr /v "hash"') do set SHA256=%%a
set SHA256=!SHA256: =!
echo ✅ SHA-256: !SHA256!

echo.
echo ⏳ [5/5] Відправляю код та створюю реліз на GitHub...
git add pubspec.yaml
git commit -m "chore: bump version to v!VERSION_NAME!"
git push origin main

:: Створюємо файл з нотатками для релізу
echo !CHANGELOG! > release_notes.txt
echo. >> release_notes.txt
echo **SHA-256 (Release):** `!SHA256!` >> release_notes.txt

:: Публікація через GitHub CLI
gh release create v!VERSION_NAME! build\app\outputs\flutter-apk\app-release.apk build\app\outputs\flutter-apk\app-debug.apk --title "MusicFlow v!VERSION_NAME! (build !BUILD_NUM!)" --notes-file release_notes.txt
del release_notes.txt

echo.
echo ===============================================================================
echo 🎉 ГОТОВО! Реліз v!VERSION_NAME! зібрано локально і опубліковано на GitHub!
echo ===============================================================================
pause
exit /b 0

:: ==========================================
:: GITHUB ACTIONS ЗБІРКА (ОПЦІЯ 2)
:: ==========================================
:GITHUB_BUILD
echo.
echo ⏳ Відправляю команду на GitHub Actions для запуску збірки...
gh workflow run ci.yml -f release_version="v!VERSION_NAME!" -f build_number="!BUILD_NUM!" -f release_notes="!CHANGELOG!"

if %errorlevel% neq 0 (
    echo ❌ Помилка при запуску GitHub Actions. Перевірте авторизацію gh auth status
    pause
    exit /b 1
)

echo.
echo ===============================================================================
echo 🎉 КОМАНДУ ВІДПРАВЛЕНО!
echo GitHub Actions вже почав працювати.
echo Він оновить pubspec.yaml, прожене тести, збере обидва APK і викладе реліз.
echo Ви можете слідкувати за процесом тут:
echo https://github.com/Lutvunenko-Dmutro/musicflow-mobile/actions
echo ===============================================================================
pause
exit /b 0
