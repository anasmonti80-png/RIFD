@echo off
setlocal
cd /d "%~dp0"
title RIFD - Local Preview
where powershell.exe >nul 2>&1
if errorlevel 1 (
  echo PowerShell is not installed. Open RIFD.html with Chrome or Edge.
  pause
  exit /b 1
)
powershell.exe -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%~dp0Run-RIFD.ps1"
if errorlevel 1 (
  echo.
  echo Launch failed. Check the error above, or open RIFD.html in Chrome or Edge.
  pause
)
endlocal
