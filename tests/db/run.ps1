# run.ps1 - tests de Model contra SQLite (se ejecutan desde la raíz del repo).
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$repo = (Resolve-Path (Join-Path $here "..\..\..\..")).Path
$clx = Join-Path $repo "target\debug\clx.exe"
$entries = @((Join-Path $here "model.clsx"), (Join-Path $here "orm.clsx"))

if (-not (Test-Path $clx)) {
    Write-Host "ERROR: falta $clx (compila con: cargo build --bin clx)"
    exit 2
}

Push-Location $repo
try {
    foreach ($entry in $entries) {
        & $clx run $entry
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    exit 0
} finally {
    Pop-Location
}
