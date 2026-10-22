@echo off
setlocal EnableExtensions
for %%i in ("%~dp0..") do set "MODULE_DIR=%%~fi"
if exist "%USERPROFILE%\.cls\bin\.tombstone-home" (
  for /f "usebackq delims=" %%i in ("%USERPROFILE%\.cls\bin\.tombstone-home") do set "MODULE_DIR=%%i"
)
if not defined CLX_BIN if defined CLX set "CLX_BIN=%CLX%"
if not defined CLX_BIN set "CLX_BIN=clx"
set "TOMBSTONE_MODULE_DIR=%MODULE_DIR%"

set "ENTRY="
if exist "app\main.clsx" (
  set "ENTRY=app\main.clsx"
) else if exist "src\main.clsx" (
  set "ENTRY=src\main.clsx"
)

set "APPDIR=."
if exist "app" (set "APPDIR=app") else if exist "src" (set "APPDIR=src")

if exist "src\console.clsx" (
  set "CONSOLE=src\console.clsx"
) else if exist "app\console.clsx" (
  set "CONSOLE=app\console.clsx"
) else if defined TOMBSTONE_CONSOLE (
  set "CONSOLE=%TOMBSTONE_CONSOLE%"
) else (
  set "CONSOLE=%MODULE_DIR%\console.clsx"
)

set "CMD=%~1"
if "%CMD%"=="" goto usage
if /I "%CMD%"=="help" goto usage
if /I "%CMD%"=="-h" goto usage
if /I "%CMD%"=="--help" goto usage
if /I "%CMD%"=="version" goto version
if /I "%CMD%"=="-v" goto version
if /I "%CMD%"=="--version" goto version
if /I "%CMD%"=="serve" goto serve
if /I "%CMD%"=="run" goto serve
if /I "%CMD%"=="start" goto serve
if /I "%CMD%"=="test" goto test_app
if /I "%CMD%"=="test:app" goto test_app
if /I "%CMD%"=="test:unit" goto test_unit
if /I "%CMD%"=="test:db" goto test_db
if /I "%CMD%"=="test:http" goto test_http
if /I "%CMD%"=="test:all" goto test_all
if /I "%CMD%"=="check" goto check
if /I "%CMD%"=="build" goto build
goto console

:usage
echo Uso: tombstone ^<comando^> [args]
echo.
echo Servidor y build:
echo   serve [puerto]          Inicia el servidor (default 3000)
echo   check [--strict]        Verifica tipos de app/ o src/
echo   build [args]            Empaqueta la app en .clsapp
echo.
echo Tests:
echo   test                    Autotest in-process de la app
echo   test:unit               Ejecuta tests/unit/**/*.clsx
echo   test:db                 Ejecuta tests/db (si hay runner)
echo   test:http               Ejecuta tests/integration (si hay runner)
echo   test:all                unit + app + db/http disponibles
echo.
echo Base de datos y generadores:
echo   migrate
echo   migrate:rollback
echo   migrate:status
echo   db:seed
echo   make:controller ^<Nombre^>
echo   make:model ^<Nombre^>
echo   make:migration ^<nombre^>
echo   make:factory ^<Nombre^>
echo   make:action ^<Nombre^>
echo   make:resource ^<Nombre^>
echo   create app [--force]
echo.
echo Otros:
echo   help                    Muestra esta ayuda
echo   version                 Muestra la version de Tombstone
exit /b 0

:version
set "VER="
for /f "usebackq delims=" %%v in (`powershell -NoProfile -Command "(Get-Content -Raw '%MODULE_DIR%\cls.json' ^| ConvertFrom-Json).version" 2^>nul`) do set "VER=%%v"
if not defined VER set "VER=0.2.0"
echo tombstone %VER%
exit /b 0

:serve
if "%ENTRY%"=="" goto no_entry
set "PORT=%~2"
if "%PORT%"=="" set "PORT=3000"
call "%CLX_BIN%" run "%ENTRY%" -- %PORT%
exit /b %ERRORLEVEL%

:test_app
if "%ENTRY%"=="" goto no_entry
call "%CLX_BIN%" run "%ENTRY%" -- test
exit /b %ERRORLEVEL%

:test_unit
if not exist "tests\unit" (
  echo tombstone: no hay tests en tests\unit
  exit /b 0
)
dir /b "tests\unit\*.clsx" >nul 2>&1
if errorlevel 1 (
  echo tombstone: no hay tests en tests\unit
  exit /b 0
)
call "%CLX_BIN%" test "tests/unit/**/*.clsx"
exit /b %ERRORLEVEL%

:test_db
if exist "tests\db\run.ps1" (
  powershell -ExecutionPolicy Bypass -File "tests\db\run.ps1"
  exit /b %ERRORLEVEL%
)
if exist "tests\db\run.sh" (
  bash "tests/db/run.sh"
  exit /b %ERRORLEVEL%
)
echo tombstone: no hay runner para tests/db 1>&2
exit /b 2

:test_http
if exist "tests\integration\http_smoke.ps1" (
  powershell -ExecutionPolicy Bypass -File "tests\integration\http_smoke.ps1"
  exit /b %ERRORLEVEL%
)
if exist "tests\integration\http_smoke.sh" (
  bash "tests/integration/http_smoke.sh"
  exit /b %ERRORLEVEL%
)
echo tombstone: no hay runner para tests/integration 1>&2
exit /b 2

:test_all
if "%ENTRY%"=="" goto no_entry
call :run_unit
if errorlevel 1 exit /b 1
call "%CLX_BIN%" run "%ENTRY%" -- test
if errorlevel 1 exit /b 1
if exist "tests\db\run.ps1" (
  powershell -ExecutionPolicy Bypass -File "tests\db\run.ps1"
  if errorlevel 1 exit /b 1
) else if exist "tests\db\run.sh" (
  bash "tests/db/run.sh"
  if errorlevel 1 exit /b 1
)
if exist "tests\integration\http_smoke.ps1" (
  powershell -ExecutionPolicy Bypass -File "tests\integration\http_smoke.ps1"
  if errorlevel 1 exit /b 1
) else if exist "tests\integration\http_smoke.sh" (
  bash "tests/integration/http_smoke.sh"
  if errorlevel 1 exit /b 1
)
exit /b 0

:run_unit
if not exist "tests\unit" exit /b 0
call "%CLX_BIN%" test "tests/unit/**/*.clsx"
exit /b %ERRORLEVEL%

:check
set "CHECK_TARGET=%ENTRY%"
if "%CHECK_TARGET%"=="" set "CHECK_TARGET=%APPDIR%"
call "%CLX_BIN%" check "%CHECK_TARGET%" %2 %3 %4 %5
exit /b %ERRORLEVEL%

:build
call "%CLX_BIN%" build %2 %3 %4 %5
exit /b %ERRORLEVEL%

:no_entry
echo tombstone: no encontre app\main.clsx ni src\main.clsx 1>&2
exit /b 2

:console
call "%CLX_BIN%" run "%CONSOLE%" -- %*
exit /b %ERRORLEVEL%
