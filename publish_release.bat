@echo off
chcp 65001 > nul
title MusicFlow Release Publisher
cd /d "%~dp0"
python server\publish_release.py
pause
