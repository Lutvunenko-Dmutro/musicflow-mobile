@echo off
title MusicFlow Server (Updates and Telemetry)
cd /d "%~dp0"

echo Starting MusicFlow Update and Telemetry Server...
python -u server.py

if errorlevel 1 (
    echo.
    echo [ERROR] Server stopped with an error code.
)
pause
