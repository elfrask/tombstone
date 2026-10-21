# run.ps1 - tests unitarios del proyecto Tombstone (desde la raiz del repo CLS).
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$repo = (Resolve-Path (Join-Path $here "..\..\..\..")).Path
$clx = Join-Path $repo "target\debug\clx.exe"
if (-not (Test-Path $clx)) {
    Write-Host "ERROR: falta $clx (compila con: cargo build --bin clx)"
    exit 2
}
$files = Get-ChildItem $here -Filter "*.clsx" | ForEach-Object { $_.FullName }
Push-Location $repo
try {
    & $clx test @files
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
