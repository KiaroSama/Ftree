@echo off
setlocal

REM PATH-friendly launcher for FileTreeReporter (Ftree).

set "POWERSHELL_EXE=powershell.exe"
where pwsh.exe >nul 2>nul
if not errorlevel 1 set "POWERSHELL_EXE=pwsh.exe"

if "%~1"=="" (
    "%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0src\FileTreeReporter.ps1"
) else (
    "%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0src\FileTreeReporter.ps1" -Path %*
)

exit /b %ERRORLEVEL%
