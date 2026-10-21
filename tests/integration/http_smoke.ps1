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
if (-not (Test-Path (Join-Path $repo "modules\sqlite\sqlite_shim.dll"))) {
    Write-Host "ERROR: falta modules\sqlite\sqlite_shim.dll (powershell -File modules\sqlite\build.ps1)"
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

# JSON por stdin: evita que PowerShell/curl partan el body en argumentos.
function CurlJson($path, $json) {
    $url = "http://127.0.0.1:$port$path"
    return ($json | & curl.exe -s -i -X POST -H "Content-Type: application/json" `
        --data-binary "@-" $url 2>&1 | Out-String)
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

        $form = "name=Ana&email=ana%40example.com&password=secret123&password_confirmation=secret123"
        $r = CurlRaw "POST" "/api/register" $form @("Content-Type: application/x-www-form-urlencoded")
        Check "POST /api/register status" ($r -match "HTTP/1\.1 201 Created") $r
        Check "POST /api/register name" ($r -match '"name":"Ana"') $r
        Check "POST /api/register email" ($r -match '"email":"ana@example.com"') $r

        $json = '{"name":"Beto","email":"beto@example.com","password":"secret123","password_confirmation":"secret123"}'
        $r = CurlJson "/api/register" $json
        Check "POST /api/register json" ($r -match "HTTP/1\.1 201 Created") $r
        Check "POST /api/register json name" ($r -match '"name":"Beto"') $r

        $r = CurlRaw "POST" "/api/login" "email=ana%40example.com&password=secret123" @("Content-Type: application/x-www-form-urlencoded")
        Check "POST /api/login status" ($r -match "HTTP/1\.1 200 OK") $r
        $sid = [regex]::Match($r, 'set-cookie: sid=([^;]+)').Groups[1].Value
        Check "POST /api/login cookie" ($sid -ne "") $r
        $csrf = [regex]::Match($r, 'x-csrf-token: ([0-9a-f]+)').Groups[1].Value
        Check "POST /api/login csrf header" ($csrf -ne "") $r
        $r = CurlRaw "GET" "/api/me" $null @("Cookie: sid=$sid")
        Check "GET /api/me status" ($r -match "HTTP/1\.1 200 OK") $r
        Check "GET /api/me email" ($r -match '"email":"ana@example.com"') $r
        $r = CurlRaw "POST" "/api/logout" $null @("Cookie: sid=$sid")
        Check "POST /api/logout requires csrf" ($r -match "HTTP/1\.1 403 Forbidden") $r
        $r = CurlRaw "GET" "/api/csrf" $null @("Cookie: sid=$sid")
        Check "GET /api/csrf status" ($r -match "HTTP/1\.1 200 OK") $r
        Check "GET /api/csrf token" ($r -match '"token":"[0-9a-f]+"') $r
        $r = CurlRaw "POST" "/api/logout" $null @("Cookie: sid=$sid", "X-CSRF-Token: $csrf")
        Check "POST /api/logout status" ($r -match "HTTP/1\.1 200 OK") $r
        $r = CurlRaw "GET" "/api/me" $null @("Cookie: sid=$sid")
        Check "GET /api/me after logout" ($r -match "HTTP/1\.1 401 Unauthorized") $r
        $r = CurlRaw "POST" "/api/login" "email=ana%40example.com&password=bad" @("Content-Type: application/x-www-form-urlencoded")
        Check "POST /api/login invalid" ($r -match "HTTP/1\.1 401 Unauthorized") $r
        for ($i = 0; $i -lt 3; $i++) {
            $null = CurlRaw "POST" "/api/login" "email=ana%40example.com&password=bad" @("Content-Type: application/x-www-form-urlencoded")
        }
        $r = CurlRaw "POST" "/api/login" "email=ana%40example.com&password=bad" @("Content-Type: application/x-www-form-urlencoded")
        Check "POST /api/login rate limit" ($r -match "HTTP/1\.1 429 Too Many Requests") $r

        $r = CurlRaw "POST" "/api/register" "name=A&email=no&password=1" @("Content-Type: application/x-www-form-urlencoded")
        Check "POST /api/register invalid" ($r -match "HTTP/1\.1 422 Unprocessable Entity") $r
        Check "POST /api/register errors" ($r -match '"errors"') $r

        $r = CurlRaw "POST" "/api/notes" "title=Hola" @("Content-Type: application/x-www-form-urlencoded")
        Check "POST /api/notes status" ($r -match "HTTP/1\.1 201 Created") $r
        Check "POST /api/notes title" ($r -match '"title":"Hola"') $r
        Check "POST /api/notes timestamp" ($r -match '"created_at":"[0-9]+"') $r
        $noteId = [regex]::Match($r, '"id":"?([0-9]+)"?').Groups[1].Value
        if ($noteId -eq "") { $noteId = "1" }

        $r = CurlRaw "GET" "/api/notes/$noteId" $null $null
        Check "GET /api/notes/{id} status" ($r -match "HTTP/1\.1 200 OK") $r
        Check "GET /api/notes/{id} title" ($r -match '"title":"Hola"') $r

        $r = CurlRaw "GET" "/api/notes" $null $null
        Check "GET /api/notes count" ($r -match '"count":1') $r

        $r = CurlRaw "GET" "/api/notes/page" $null $null
        Check "GET /api/notes/page status" ($r -match "HTTP/1\.1 200 OK") $r
        Check "GET /api/notes/page meta" ($r -match '"meta":\{"page":1') $r

        $r = CurlRaw "DELETE" "/api/notes/$noteId" $null $null
        Check "DELETE /api/notes status" ($r -match "HTTP/1\.1 200 OK") $r
        Check "DELETE /api/notes body" ($r -match '"deleted":true') $r

        $r = CurlRaw "GET" "/api/notes/$noteId" $null $null
        Check "GET /api/notes deleted 404" ($r -match "HTTP/1\.1 404 Not Found") $r

        $r = CurlRaw "GET" "/api/notes" $null $null
        Check "GET /api/notes soft count" ($r -match '"count":0') $r

        $r = CurlRaw "GET" "/api/notes/trashed" $null $null
        Check "GET /api/notes/trashed status" ($r -match "HTTP/1\.1 200 OK") $r
        Check "GET /api/notes/trashed count" ($r -match '"count":1') $r

        $r = CurlRaw "POST" "/api/notes/$noteId/restore" $null $null
        Check "POST /api/notes/restore status" ($r -match "HTTP/1\.1 200 OK") $r
        Check "POST /api/notes/restore body" ($r -match '"restored":true') $r

        $r = CurlRaw "GET" "/api/notes" $null $null
        Check "GET /api/notes restored count" ($r -match '"count":1') $r

        $r = CurlRaw "GET" "/cookies" $null @("Cookie: a=1; b=two")
        Check "GET /cookies status" ($r -match "HTTP/1\.1 200 OK") $r
        Check "GET /cookies a" ($r -match "a=1;") $r
        Check "GET /cookies b" ($r -match "b=two;") $r

        $r = CurlRaw "GET" "/set-cookie" $null $null
        Check "GET /set-cookie status" ($r -match "HTTP/1\.1 302 Found") $r
        Check "GET /set-cookie location" ($r -match "location: /cookies") $r
        Check "GET /set-cookie header" ($r -match "set-cookie: visita=1; Path=/; HttpOnly") $r

        $r = CurlRaw "GET" "/ui" $null $null
        Check "GET /ui status" ($r -match "HTTP/1\.1 200 OK") $r
        Check "GET /ui title" ($r -match "UI Kit") $r
        Check "GET /ui button" ($r -match "<button") $r
        Check "GET /ui card" ($r -match 'class="card"') $r
        Check "GET /ui slot" ($r -match "slot de children") $r

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
