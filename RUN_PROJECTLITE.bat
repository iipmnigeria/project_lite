@echo off
setlocal
title ProjectLite Setup and Launcher
cd /d "%~dp0"

echo.
echo  =====================================================
echo            PROJECTLITE SETUP AND LAUNCHER
echo  =====================================================
echo.

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\install-and-run.ps1"
set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" (
  echo.
  echo ProjectLite could not be started automatically.
  echo Please review the message above, then try this launcher again.
  echo.
  pause
)

exit /b %EXIT_CODE%
