# run.ps1 - tests de Model contra SQLite (se ejecutan desde la raíz del repo).
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$repo = (Resolve-Path (Join-Path $here "..\..\..\..")).Path
$clx = Join-Path $repo "target\debug\clx.exe"
$entry = Join-Path $here "model.clsx"

if (-not (Test-Path $clx)) {
    Write-Host "ERROR: falta $clx (compila con: cargo build --bin clx)"
    exit 2
}

Push-Location $repo
try {
    & $clx run $entry
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
