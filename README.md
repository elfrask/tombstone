# Tombstone

Framework web para **CLS 2.0**, construido con **CLS puro + FFI**. Router,
middleware, HTTP/1.1, archivos estáticos, CORS, cookies, JSON, **vistas CMX** y
**plantillas/layouts** (`Template`).

- **Motor**: `modules/tombstone/` (módulo CLS reutilizable).
- **Proyecto demo / template de inicialización**: `src/` + `public/`.
- **Iconos**: `modules/tombstone-icons/` (CMX + SVG inline).

## Estado

Fase 0 completa y ampliada:

- `App`: router con `{param}`, middleware, static, CORS, cookies, JSON.
- `Template`: documento HTML completo con `lang`, title, metas, styles,
  scripts, favicon, body class, herencia por `Template.derive`.
- `view`: renderer **CMX -> HTML** (escape, `raw`, `attrs`, void elements,
  componentes uppercase vía `tagCallable`, `renderEach`).
- Transporte HTTP: `modules/httpd` + `modules/socket` (FFI).
- Archivos estáticos: `modules/io` (FFI, sin `host_call fs`).
- Demo: landing real con CMX, iconos, CSS/JS y API JSON.

## Estructura

```
tombstone/
├── cls.json                 # proyecto demo (entry: src/main.clsx)
├── modules/
│   ├── tombstone/           # MOTOR del framework
│   │   ├── cls.json         # export.entry = mod.clsx
│   │   ├── mod.clsx         # barrel público
│   │   ├── app.clsx         # App (router + middleware + static + CORS)
│   │   ├── router.clsx
│   │   ├── middleware.clsx
│   │   ├── static.clsx
│   │   ├── cors.clsx
│   │   ├── cookies.clsx
│   │   ├── json.clsx
│   │   ├── status.clsx      # HttpStatus
│   │   ├── view.clsx        # CMX -> HTML
│   │   ├── template.clsx    # Template + MetaTag
│   │   └── lib.clsx         # pid / uptime / env (FFI)
│   └── tombstone-icons/     # iconos SVG para las vistas
├── src/
│   ├── main.clsx            # proyecto demo (rutas + Template)
│   └── views.clsx           # vistas CMX de la landing
├── public/                  # css / js / favicon servidos por /public
├── tests/unit/              # tests in-memory (clx test)
└── tests/integration/       # servidor real + curl
```

Los ladrillos reutilizables viven en la stdlib global: `modules/socket`,
`modules/httpd`, `modules/io` y `modules/check`.

## Requisitos

- CLS 2.0 dev-2 compilado: `cargo build --bin clx` (o `--release`).
- `gcc` (MinGW-w64 x64) para los shims de sockets e I/O.
- `wasm32-unknown-unknown` (lo usa `cls-internals`).

El shim de `socket` y el de `io` resuelven su ruta **relativa al CWD**: el
servidor se ejecuta desde la raíz del repo CLS.

```powershell
powershell -File modules\socket\build.ps1
powershell -File modules\io\build.ps1
```

## Demo

Desde la raíz del repo CLS:

```powershell
target\debug\clx.exe run cls-repositories\tombstone\src\main.clsx -- 8080
```

Rutas del demo:

| Método | Ruta | Respuesta |
|--------|------|-----------|
| GET | `/` | landing (Template + CMX + iconos) |
| GET | `/api/health` | JSON |
| GET | `/api/users` | JSON (lista) |
| GET | `/users/{id}` | JSON con el param |
| POST | `/api/echo` | JSON con el body recibido |
| GET | `/cookies` | cookies recibidas |
| GET | `/set-cookie` | `Set-Cookie` + redirect |
| GET | `/public/*` | CSS / JS / favicon |

```powershell
curl.exe -i http://127.0.0.1:8080/api/health
```

Autotest en memoria (sin sockets):

```powershell
target\debug\clx.exe run cls-repositories\tombstone\src\main.clsx -- 8080 test
```

## Tests

Unitarios (desde este directorio):

```powershell
..\..\target\debug\clx.exe test
```

Integración HTTP real (desde la raíz del repo CLS):

```powershell
powershell -File cls-repositories\tombstone\tests\integration\http_smoke.ps1
```

Cobertura actual: **7 tests unitarios PASS** (request/response/router/app,
template, view, cookies/CORS/JSON/static, status) y **29 checks de integración
PASS** (landing, API, cookies, CORS, static, 404/405).

## Uso del framework

```clx
from "tombstone" import App, Request, Response, Template, CorsOptions, render;

function main(args: String[]) -> int {
    var app = App();
    app.cors(CorsOptions());
    app.serve_static("/public", "cls-repositories/mi-proyecto/public");

    app.use("logging", (req: Request) -> Response {
        print("-> " + req.http_method + " " + req.path);
        return Response.status_only(0);   # 0 = seguir la cadena
    });

    app.get("/users/{id}", (req: Request) -> Response {
        return Response.json_response("{\"id\":\"" + req.param("id") + "\"}");
    });

    return app.serve("127.0.0.1", 8080);
}
```

Plantilla + vista CMX:

```clx
from "tombstone" import Template, render;

var t = Template();
t.set_title("Inicio");
t.add_style("/public/style.css");

var page = (
    <main>
        <h1>{"Hola & bienvenido"}</h1>
    </main>
);

var html = render(t.render(page));   # <!DOCTYPE html> ... escapado
```

### API

- `App`: `get/post/put/patch/delete_route/options`, `use`, `serve_static`,
  `cors`, `handle(raw)`, `dispatch(Request)`, `serve(host, port)`.
- `Router`: `add`, verbos, `dispatch(Request)`; `{param}` + 404/405.
- `Middleware`: `(Request) -> Response`; `status == 0` continúa.
- `Request`: `http_method`, `path`, `query`, `query_param`, `headers`,
  `header`, `body`, `params`, `param`.
- `Response`: `text`, `html`, `json_raw`, `json_response`, `redirect`,
  `status_only`, `not_found`, `header`, `set_cookie`, `serialize`.
- `Template`: `set_*`, `add_style`, `add_script`, `add_meta`,
  `add_meta_prop`, `derive`, `render(page)`.
- `view`: `e`, `raw`, `render`, `attrs`, `isVoid`, `renderEach`, `layout`,
  `ul_items`.
- `static`: `StaticHandler`, `content_type_for`.
- `cors`: `CorsOptions`, `cors_apply`, `cors_preflight`.
- `cookies`: `CookieOptions`, `parse_cookies`, `serialize_cookie`.
- `json`: `json_encode`, `json_decode`, `json_parse_safe`, `json_body`,
  `json_response`, `json_response_raw`, `json_string_array`.
- `HttpStatus`: constantes (`OK`, `NOT_FOUND`, ...) + `reason(code)`.

## Consumo como módulo

El motor es el módulo local `modules/tombstone` (y los iconos
`modules/tombstone-icons`). En el `cls.json` del proyecto consumidor agrega:

```json
{
  "pathModules": [
    "<ruta-al-repo-cls>/modules",
    "<ruta-al-repo-cls>/cls-repositories/tombstone/modules"
  ]
}
```

Luego:

```clx
from "tombstone" import App, Request, Response, Template, render;
from "tombstone-icons" import icon;
```

El consumidor también necesita `modules/socket`, `modules/httpd` y
`modules/io` de la primera ruta (stdlib global).

## Limitaciones conocidas

- HTTP/1.1 sin `Transfer-Encoding: chunked` ni keep-alive (una request por
  conexión, `Connection: close`).
- `headers` es `Record<String, String>`: el último valor gana; `Set-Cookie`
  múltiple queda pendiente.
- Router: solo params requeridos `{id}`. Faltan constraints (`where`),
  opcionales (`{id?}`), named routes y controllers como clases.
- CMX: un child que es `Array` no se expande solo; usar `renderEach` + `raw`.
  Los componentes uppercase deben devolver `String`.
- JSON: usa el módulo interno `json` del nodo (deuda host-side). El parser es
  permisivo; no se expone un validador estricto. `json.stringify(array)` no es
  fiable: se usa `json_string_array`.
- `static` / sockets / I/O: rutas de shims relativas al CWD; ejecutar desde la
  raíz del repo CLS.
- Sin concurrencia: el loop es bloqueante (no hay `async` ejecutable todavía).

## Bugs del lenguaje encontrados (dogfooding)

- **Identificador local `path`**: `path.miembro` se parsea como namespace del
  módulo interno `path` aunque `path` sea un parámetro/local. En el motor se
  usa `route_path` / `file_path` como mitigación.
- **Flatten de exports hermanos**: si un módulo exporta una clase que llama a
  otra función exportada del mismo módulo y el consumidor no la importa, el
  flatten puede omitirla. El barrel del framework importa explícitamente los
  símbolos hermanos que usa.

El trap de JIT con arrows dentro de métodos que capturan locales fue corregido
en `cls-core` (regresión `examples/test/jit-test/units/mod-arrow-capture.clsx`).

## Licencia

MIT (ver `LICENSE`).
