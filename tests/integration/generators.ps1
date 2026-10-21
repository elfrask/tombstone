$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$repo = (Resolve-Path (Join-Path $here "..\..\..\..")).Path
$module = Join-Path $repo "cls-repositories\tombstone\modules\tombstone"
$clx = Join-Path $repo "target\debug\clx.exe"
$tb = Join-Path $module "bin\tombstone.cmd"
$tmp = Join-Path $env:TEMP ("tombstone-generators-" + [guid]::NewGuid().ToString("N"))
$oldClx = $env:CLX
$fails = 0
function Check($name, $ok, $detail) {
    if ($ok) { Write-Host ("PASS  {0}" -f $name) } else { Write-Host ("FAIL  {0}: {1}" -f $name, $detail); $script:fails++ }
}
New-Item -ItemType Directory $tmp -Force | Out-Null
try {
    $env:CLX = $clx
    Push-Location $tmp
    & $tb create app | Out-Null
    Check "generator.create" (Test-Path "cls.json") "sin cls.json"
    & $tb make:controller Home | Out-Null
    & $tb make:model Note | Out-Null
    & $tb make:action CreateNote | Out-Null
    & $tb make:factory Note | Out-Null
    & $tb make:resource Note | Out-Null
    & $tb make:migration create_notes | Out-Null
    $files = @(
        "src\controllers\HomeController.clsx",
        "src\models\Note.clsx",
        "src\actions\CreateNoteAction.clsx",
        "src\factories\NoteFactory.clsx",
        "src\resources\NoteResource.clsx"
    )
    foreach ($f in $files) { Check ("generator." + (Split-Path $f -Leaf)) (Test-Path $f) $f }
    $mig = Get-ChildItem "src\migrations\*_create_notes.clsx" -ErrorAction SilentlyContinue
    Check "generator.migration" ($mig.Count -eq 1) "sin migracion"
    foreach ($f in (Get-ChildItem src -Recurse -Filter *.clsx)) {
        & $clx ast $f.FullName --json | Out-Null
        Check ("syntax." + $f.Name) ($LASTEXITCODE -eq 0) "clx ast fallo"
    }
    Pop-Location
} finally {
    Pop-Location -ErrorAction SilentlyContinue
    $env:CLX = $oldClx
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
if ($fails -gt 0) { exit 1 }
Write-Host "OK: generadores"
