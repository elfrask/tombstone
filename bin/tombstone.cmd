@echo off
setlocal
if not defined CLX_BIN if defined CLX set "CLX_BIN=%CLX%"
if not defined TOMBSTONE_CONSOLE set "TOMBSTONE_CONSOLE=src\console.clsx"
if defined CLX_BIN (
  call "%CLX_BIN%" run "%TOMBSTONE_CONSOLE%" -- %*
) else (
  call clx run "%TOMBSTONE_CONSOLE%" -- %*
)
exit /b %ERRORLEVEL%
