@echo off
setlocal
cd /d "%~dp0"

if exist "C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot" (
    set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot"
    set "PATH=C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot\bin;%PATH%"
)

where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Python is not installed or not in PATH!
    echo Please install Python 3 or add it to PATH.
    pause
    exit /b 1
)

python publish_manager.py

if %errorlevel% neq 0 (
    echo.
    echo ===============================================================
    echo Script ended with exit code %errorlevel%.
    echo ===============================================================
    pause
)
