@echo off
setlocal

REM Double-click launcher for FileTreeReporter (Ftree).
REM It runs the PowerShell script without requiring a permanent execution-policy change.

cd /d "%~dp0"

set "POWERSHELL_EXE=powershell.exe"
where pwsh.exe >nul 2>nul
if not errorlevel 1 set "POWERSHELL_EXE=pwsh.exe"

"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0src\FileTreeReporter.ps1"

echo.
echo Press any key to close...
pause >nul
