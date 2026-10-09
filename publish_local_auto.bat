@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion

echo ===============================================================================
echo 🚀 MusicFlow Mobile - ПОВНА АВТОМАТИЗАЦІЯ (Локально)
echo ===============================================================================
echo.
echo Цей скрипт проаналізує ваші останні коміти (feat:, fix:), сам визначить
echo наступну версію, збере APK і опублікує реліз на GitHub.
echo.

:: Перевіряємо наявність GH CLI
where gh >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ ПОМИЛКА: Не знайдено GitHub CLI ^(gh^).
    echo Будь ласка, встановіть його: winget install --id GitHub.cli
    pause
    exit /b 1
)

:: Перевіряємо чи є незбережені зміни
git diff-index --quiet HEAD --
if %errorlevel% neq 0 (
    echo ❌ У вас є незбережені зміни (git commit).
    echo Будь ласка, зробіть коміт перед запуском автоматичного релізу!
    pause
    exit /b 1
)

echo ⏳ [1/4] Аналізую коміти для визначення наступної версії...
:: Запускаємо semantic-release в режимі dry-run щоб просто витягти номер версії
for /f "tokens=*" %%i in ('npx semantic-release --dry-run ^| findstr "Published release"') do set SEMANTIC_OUT=%%i

if "!SEMANTIC_OUT!"=="" (
    echo.
    echo ℹ️ Немає нових 'feat:' або 'fix:' комітів з моменту минулого релізу.
    echo Новий реліз не потрібен.
    pause
    exit /b 0
)

:: Витягуємо тільки цифри (наприклад, 1.0.39) з рядка
for /f "tokens=4" %%a in ("!SEMANTIC_OUT!") do set NEXT_VERSION=%%a
echo ✅ Наступна версія: v!NEXT_VERSION!

:: Для номера білда використаємо кількість комітів у гілці (завжди зростає)
for /f %%b in ('git rev-list --count HEAD') do set BUILD_NUM=%%b
echo ✅ Номер білда: !BUILD_NUM!

echo.
echo ⏳ [2/4] Оновлюю pubspec.yaml...
python -c "import re; content = open('pubspec.yaml', 'r', encoding='utf-8').read(); content = re.sub(r'version: .*', f'version: !NEXT_VERSION!+!BUILD_NUM!', content); open('pubspec.yaml', 'w', encoding='utf-8').write(content)"

echo.
echo ⏳ [3/4] Збираю Release та Debug APK...
call flutter build apk --release --build-name=!NEXT_VERSION! --build-number=!BUILD_NUM!
call flutter build apk --debug --build-name=!NEXT_VERSION! --build-number=!BUILD_NUM!

echo.
echo ⏳ [4/4] Відправляю код та створюю реліз на GitHub...
git add pubspec.yaml
git commit -m "chore: release v!NEXT_VERSION! [skip ci]"
git push origin main

:: Тепер викликаємо справжній semantic-release, який збереchangelog і зробить реліз
:: Оскільки він використовує GitHub CLI, переконайтеся, що ви залогінені (gh auth login)
set GITHUB_TOKEN=
for /f "tokens=*" %%t in ('gh auth token') do set GITHUB_TOKEN=%%t

npx semantic-release

echo.
echo ===============================================================================
echo 🎉 ГОТОВО!
echo Реліз v!NEXT_VERSION! автоматично зібрано і опубліковано на GitHub!
echo ===============================================================================
pause
