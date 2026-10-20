# http_smoke.ps1 - Integracion HTTP real contra el demo de Tombstone.
#
#   powershell -File cls-repositories\tombstone\tests\integration\http_smoke.ps1
#
# Arranca `clx run src/main.clsx -- <puerto>` desde la RAIZ del repo CLS (los
# shims de socket/io resuelven su ruta relativa al CWD) y valida status/body
# con `curl.exe`. Sale con != 0 si algo falla.
$ErrorActionPreference = "Stop"

$here = $PSScriptRoot
$repo = (Resolve-Path (Join-Path $here "..\..\..\..")).Path
$tombstone = (Resolve-Path (Join-Path $here "..\..")).Path
$clx = Join-Path $repo "target\debug\clx.exe"
$entry = Join-Path $tombstone "src\main.clsx"

if (-not (Test-Path $clx)) {
    Write-Host "ERROR: falta $clx (compila con: cargo build --bin clx)"
    exit 2
}
if (-not (Test-Path $entry)) {
    Write-Host "ERROR: falta $entry"
    exit 2
}
if (-not (Test-Path (Join-Path $repo "modules\socket\socket_shim.dll"))) {
    Write-Host "ERROR: falta modules\socket\socket_shim.dll (powershell -File modules\socket\build.ps1)"
    exit 2
}
if (-not (Test-Path (Join-Path $repo "modules\io\io_shim.dll"))) {
    Write-Host "ERROR: falta modules\io\io_shim.dll (powershell -File modules\io\build.ps1)"
    exit 2
}

# Puerto libre efimero.
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
$listener.Start()
$port = $listener.LocalEndpoint.Port
$listener.Stop()

$out = Join-Path $env:TEMP "tombstone_http_out.txt"
$err = Join-Path $env:TEMP "tombstone_http_err.txt"
$proc = $null
$fails = 0

function Check($name, $ok, $detail) {
    if ($ok) {
        Write-Host ("PASS  {0}" -f $name)
    } else {
        Write-Host ("FAIL  {0}: {1}" -f $name, $detail)
        $script:fails++
    }
}

function CurlRaw($method, $path, $body, $headers) {
    $curlArgs = @("-s", "-i", "-X", $method)
    if ($body -ne $null) {
        $curlArgs += @("--data", $body)
    }
    if ($headers -ne $null) {
        foreach ($h in $headers) {
            $curlArgs += @("-H", $h)
        }
    }
    $curlArgs += "http://127.0.0.1:$port$path"
    return (& curl.exe @curlArgs 2>&1 | Out-String)
}

try {
    $proc = Start-Process -FilePath $clx `
        -ArgumentList @("run", $entry, "--", "$port") `
        -WorkingDirectory $repo -NoNewWindow -PassThru `
        -RedirectStandardOutput $out -RedirectStandardError $err

    # Esperar a que el puerto responda (compilacion + listen).
    $ready = $false
    for ($i = 0; $i -lt 80; $i++) {
        Start-Sleep -Milliseconds 250
        try {
            $resp = Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 `
                -Uri "http://127.0.0.1:$port/api/health"
            if ($resp.StatusCode -eq 200) {
                $ready = $true
                break
            }
        } catch {
            # aun compilando o conexion rechazada
        }
        if ($proc.HasExited) {
            break
        }
    }

    if (-not $ready) {
        Write-Host "ERROR: el servidor no respondio en el puerto $port"
        $script:fails++
    } else {
        $r = CurlRaw "GET" "/" $null $null
        Check "GET / status" ($r -match "HTTP/1\.1 200 OK") $r
        Check "GET / doctype" ($r -match "<!DOCTYPE html>") $r
        Check "GET / template" ($r -match "<title>Tombstone") $r
        Check "GET / landing" ($r -match "class=`"hero`"") $r
        Check "GET / static css link" ($r -match "/public/css/style.css") $r

        $r = CurlRaw "GET" "/api/health" $null $null
        Check "GET /api/health status" ($r -match "HTTP/1\.1 200 OK") $r
        Check "GET /api/health json" ($r -match '"status":"ok"') $r
        Check "GET /api/health content-type" ($r -match "content-type: application/json") $r
        Check "GET /api/health cors" ($r -match "access-control-allow-origin: \*") $r

        $r = CurlRaw "GET" "/api/users" $null $null
        Check "GET /api/users json" ($r -match '"users":\["ana","beto","carla"\]') $r

        $r = CurlRaw "GET" "/users/42" $null $null
        Check "GET /users/{id} status" ($r -match "HTTP/1\.1 200 OK") $r
        Check "GET /users/{id} param" ($r -match '"id":"42"') $r

        $r = CurlRaw "POST" "/api/echo" "hola" $null
        Check "POST /api/echo status" ($r -match "HTTP/1\.1 200 OK") $r
        Check "POST /api/echo body" ($r -match '"recibido":"hola"') $r

        $r = CurlRaw "GET" "/cookies" $null @("Cookie: a=1; b=two")
        Check "GET /cookies status" ($r -match "HTTP/1\.1 200 OK") $r
        Check "GET /cookies a" ($r -match "a=1;") $r
        Check "GET /cookies b" ($r -match "b=two;") $r

        $r = CurlRaw "GET" "/set-cookie" $null $null
        Check "GET /set-cookie status" ($r -match "HTTP/1\.1 302 Found") $r
        Check "GET /set-cookie location" ($r -match "location: /cookies") $r
        Check "GET /set-cookie header" ($r -match "set-cookie: visita=1; Path=/; HttpOnly") $r

        $r = CurlRaw "GET" "/public/css/style.css" $null $null
        Check "GET /public/css status" ($r -match "HTTP/1\.1 200 OK") $r
        Check "GET /public/css type" ($r -match "content-type: text/css") $r
        Check "GET /public/css body" ($r -match ":root") $r

        $r = CurlRaw "GET" "/public/favicon.svg" $null $null
        Check "GET /public/favicon status" ($r -match "HTTP/1\.1 200 OK") $r
        Check "GET /public/favicon type" ($r -match "content-type: image/svg\+xml") $r

        $r = CurlRaw "OPTIONS" "/api/health" $null $null
        Check "OPTIONS preflight status" ($r -match "HTTP/1\.1 204 No Content") $r
        Check "OPTIONS preflight cors" ($r -match "access-control-allow-origin: \*") $r

        $r = CurlRaw "GET" "/nope" $null $null
        Check "GET /nope 404" ($r -match "HTTP/1\.1 404 Not Found") $r

        $r = CurlRaw "POST" "/" $null $null
        Check "POST / 405" ($r -match "HTTP/1\.1 405 Method Not Allowed") $r
    }
} finally {
    if ($proc -ne $null -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
    if ($fails -ne 0) {
        Write-Host "--- stdout del servidor ---"
        Get-Content $out -ErrorAction SilentlyContinue
        Write-Host "--- stderr del servidor ---"
        Get-Content $err -ErrorAction SilentlyContinue
    }
    Remove-Item $out, $err -ErrorAction SilentlyContinue
}

if ($fails -eq 0) {
    Write-Host "OK: integracion HTTP"
    exit 0
}
Write-Host "FALLARON $fails chequeo(s)"
exit 1
