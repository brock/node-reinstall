@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "VERSION=0.0.17"
set "DEFAULT_NODE_VERSION=5"
set "FORCE=0"
set "DRY_RUN=0"
set "DESIRED_NODE_VERSION="
set "GLOBAL_MODULES_FILE=%TEMP%\node-reinstall-global-modules-%RANDOM%.txt"

:parse_args
if "%~1"=="" goto after_args
set "ARG=%~1"
if /I "%ARG%"=="--help" goto usage
if /I "%ARG%"=="-h" goto usage
if /I "%ARG%"=="--version" goto version
if /I "%ARG%"=="-v" goto version
if /I "%ARG%"=="--force" (
  set "FORCE=1"
  shift
  goto parse_args
)
if /I "%ARG%"=="-f" (
  set "FORCE=1"
  shift
  goto parse_args
)
if /I "%ARG%"=="--dry-run" (
  set "DRY_RUN=1"
  shift
  goto parse_args
)
if "%ARG:~0,1%"=="-" (
  echo error: Unknown option `%ARG%` 1>&2
  call :usage_text 1>&2
  exit /b 1
)
if defined DESIRED_NODE_VERSION (
  echo error: Only one NODE_VERSION argument is supported. 1>&2
  call :usage_text 1>&2
  exit /b 1
)
set "DESIRED_NODE_VERSION=%ARG%"
shift
goto parse_args

:after_args
call :detect_node_version

if defined DESIRED_NODE_VERSION (
  set "NODE_VERSION=%DESIRED_NODE_VERSION%"
) else if defined INSTALLED_NODE_VERSION (
  set "NODE_VERSION=%INSTALLED_NODE_VERSION%"
) else (
  set "NODE_VERSION=%DEFAULT_NODE_VERSION%"
)

if /I "%NODE_VERSION:~0,1%"=="v" set "NODE_VERSION=%NODE_VERSION:~1%"

echo node-reinstall.bat will delete user-level Windows Node/npm paths.
echo Read this script before continuing. The deleted files cannot be recovered.
echo.

if defined INSTALLED_NODE_VERSION (
  echo Found Node.js version %INSTALLED_NODE_VERSION% already installed.
  echo If you continue now, this script will clean npm paths and reinstall Node.js version %NODE_VERSION% when nvm-windows is available.
  call :confirm || exit /b 1
)

call :collect_global_modules

if exist "%GLOBAL_MODULES_FILE%" (
  echo Will reinstall these global npm modules after Node is available:
  for /f "usebackq delims=" %%M in ("%GLOBAL_MODULES_FILE%") do echo   %%M
) else (
  echo No global npm modules were detected before cleanup.
)

call :confirm || exit /b 1

call :remove_file "%APPDATA%\npm\npm"
call :remove_file "%APPDATA%\npm\npm.cmd"
call :remove_file "%APPDATA%\npm\npx"
call :remove_file "%APPDATA%\npm\npx.cmd"
call :remove_dir "%APPDATA%\npm\node_modules"
call :remove_dir "%APPDATA%\npm-cache"
call :remove_dir "%USERPROFILE%\.npm"
call :remove_dir "%USERPROFILE%\.npm-cache"
call :remove_dir "%USERPROFILE%\.node-gyp"

call :reinstall_with_nvm
call :reinstall_global_modules

if exist "%GLOBAL_MODULES_FILE%" del /f /q "%GLOBAL_MODULES_FILE%" >nul 2>nul

echo node-reinstall.bat is done.
echo You must restart your terminal for changes to take effect.
exit /b 0

:usage
call :usage_text
exit /b 0

:usage_text
echo node-reinstall.bat
echo   completely cleans Windows Node/npm user paths and reinstalls with nvm-windows when available.
echo.
echo Usage: node-reinstall.bat [-h^|--help] [-v^|--version] [-f^|--force] [--dry-run] [NODE_VERSION]
echo.
echo Commands:
echo   node-reinstall.bat             clean npm paths and reinstall current/default Node version with nvm-windows
echo   node-reinstall.bat --dry-run   show what would be deleted or run without changing anything
echo   node-reinstall.bat -f          skip confirmation prompts
echo   node-reinstall.bat 20.11.1     reinstall a specific Node.js version with nvm-windows
exit /b 0

:version
echo %VERSION%
exit /b 0

:confirm
if "%FORCE%"=="1" exit /b 0
choice /C YN /N /M "Continue? [Y/N] "
if errorlevel 2 exit /b 1
exit /b 0

:detect_node_version
set "INSTALLED_NODE_VERSION="
for /f "usebackq delims=" %%V in (`node --version 2^>nul`) do (
  set "INSTALLED_NODE_VERSION=%%V"
)
exit /b 0

:collect_global_modules
if exist "%GLOBAL_MODULES_FILE%" del /f /q "%GLOBAL_MODULES_FILE%" >nul 2>nul
where npm >nul 2>nul
if errorlevel 1 exit /b 0

for /f "usebackq delims=" %%G in (`npm -g list --depth 0 --parseable 2^>nul`) do (
  for %%M in ("%%G") do set "MODULE_NAME=%%~nxM"
  if /I not "!MODULE_NAME!"=="node_modules" if /I not "!MODULE_NAME!"=="npm" if not "!MODULE_NAME!"=="" (
    echo !MODULE_NAME!>>"%GLOBAL_MODULES_FILE%"
  )
)

for %%F in ("%GLOBAL_MODULES_FILE%") do if %%~zF EQU 0 del /f /q "%GLOBAL_MODULES_FILE%" >nul 2>nul
exit /b 0

:remove_file
set "TARGET=%~1"
if not exist "%TARGET%" exit /b 0
if "%DRY_RUN%"=="1" (
  echo Would delete file: "%TARGET%"
  exit /b 0
)
echo Deleting file: "%TARGET%"
del /f /q "%TARGET%"
exit /b %ERRORLEVEL%

:remove_dir
set "TARGET=%~1"
if not exist "%TARGET%\" exit /b 0
if "%DRY_RUN%"=="1" (
  echo Would delete directory: "%TARGET%"
  exit /b 0
)
echo Deleting directory: "%TARGET%"
rmdir /s /q "%TARGET%"
exit /b %ERRORLEVEL%

:reinstall_with_nvm
where nvm >nul 2>nul
if errorlevel 1 (
  echo nvm-windows was not found on PATH.
  echo Install Node manually from https://nodejs.org/ or install nvm-windows, then rerun this script.
  exit /b 0
)

if "%DRY_RUN%"=="1" (
  echo Would run: nvm install %NODE_VERSION%
  echo Would run: nvm use %NODE_VERSION%
  exit /b 0
)

echo Installing Node.js %NODE_VERSION% with nvm-windows.
nvm install %NODE_VERSION%
if errorlevel 1 exit /b %ERRORLEVEL%
nvm use %NODE_VERSION%
exit /b %ERRORLEVEL%

:reinstall_global_modules
if not exist "%GLOBAL_MODULES_FILE%" exit /b 0
where npm >nul 2>nul
if errorlevel 1 (
  echo npm was not found after cleanup, so global modules were not reinstalled.
  exit /b 0
)

if "%DRY_RUN%"=="1" (
  for /f "usebackq delims=" %%M in ("%GLOBAL_MODULES_FILE%") do echo Would run: npm install --global %%M
  exit /b 0
)

for /f "usebackq delims=" %%M in ("%GLOBAL_MODULES_FILE%") do (
  echo Reinstalling global module: %%M
  npm install --global %%M
  if errorlevel 1 exit /b %ERRORLEVEL%
)
exit /b 0
