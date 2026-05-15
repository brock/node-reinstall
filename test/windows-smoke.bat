@echo off
setlocal EnableExtensions

set "SCRIPT=%~dp0..\node-reinstall.bat"

call "%SCRIPT%" --help
if errorlevel 1 exit /b %ERRORLEVEL%

call "%SCRIPT%" --version
if errorlevel 1 exit /b %ERRORLEVEL%

call "%SCRIPT%" --dry-run --force 20.11.1
if errorlevel 1 exit /b %ERRORLEVEL%

call "%SCRIPT%" --not-a-real-option
if not errorlevel 1 (
  echo Expected unknown option to fail.
  exit /b 1
)

echo Windows smoke checks passed.
exit /b 0
