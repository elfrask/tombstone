# install-global.ps1 - instala los launchers de Tombstone en ~/.cls/bin.
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$root = (Resolve-Path (Join-Path $here "..")).Path
$homeDir = if ($env:USERPROFILE) { $env:USERPROFILE } elseif ($env:HOME) { $env:HOME } else { throw "No se pudo resolver HOME/USERPROFILE" }
$bin = Join-Path $homeDir ".cls\bin"
New-Item -ItemType Directory -Path $bin -Force | Out-Null
Copy-Item (Join-Path $root "bin\tombstone.cmd") (Join-Path $bin "tombstone.cmd") -Force
Copy-Item (Join-Path $root "bin\tombstone.sh")  (Join-Path $bin "tombstone")     -Force
Write-Host "Instalado en $bin"
Write-Host "Asegurate de tener '$bin' en PATH."
