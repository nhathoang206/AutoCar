@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Start-FreeAI.ps1"
if errorlevel 1 echo Khong the bat AI. Xem thong bao loi o tren.
pause
