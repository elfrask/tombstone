@echo off
setlocal
set "MODULE_DIR=%~dp0.."
if not defined CLX_BIN if defined CLX set "CLX_BIN=%CLX%"
if exist "src\console.clsx" (
  set "CONSOLE=src\console.clsx"
) else (
  if defined TOMBSTONE_CONSOLE (set "CONSOLE=%TOMBSTONE_CONSOLE%") else (set "CONSOLE=%MODULE_DIR%\console.clsx")
)
if defined CLX_BIN (
  call "%CLX_BIN%" run "%CONSOLE%" -- %*
) else (
  call clx run "%CONSOLE%" -- %*
)
exit /b %ERRORLEVEL%
