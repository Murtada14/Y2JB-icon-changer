@echo off
title PS5 Icon Auto-Uploader
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update_Icon.ps1"
echo.
pause