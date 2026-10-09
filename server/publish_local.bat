@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion

echo ===============================================================================
echo 🎵 MusicFlow Mobile - Локальна збірка та OTA-оновлення (Без GitHub)
echo ===============================================================================
echo.
echo Цей скрипт збере APK (Release та Debug), порахує SHA-256 і покладе
echo їх у папку локального сервера (server/data/updates).
echo Це НЕ буде пушити код на GitHub і НЕ запустить GitHub Actions.
echo.

set /p CHANGELOG="Введіть опис змін для цього локального оновлення: "
if "!CHANGELOG!"=="" set CHANGELOG=Локальна тестова збірка

echo.
echo ⏳ Починаю збірку...

python server\publish_release.py --changelog "!CHANGELOG!" --mode both --skip-git

echo.
if %errorlevel% neq 0 (
    echo ❌ Сталася помилка під час збірки! Перевірте логи вище.
    pause
    exit /b %errorlevel%
)

echo.
echo ===============================================================================
echo ✅ Готово! APK-файли збережено локально.
echo.
echo Щоб перевірити оновлення на телефоні:
echo 1. Переконайтеся, що ваш телефон і ПК в одній Wi-Fi мережі.
echo 2. Запустіть сервер: python server\server.py
echo 3. У додатку виберіть "Канал оновлень: Custom Server" та вкажіть IP вашого ПК.
echo ===============================================================================
echo.
pause
