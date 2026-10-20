# `tombstone` — motor del framework web

Módulo CLS con el motor de Tombstone. El proyecto de presentación/pruebas vive
fuera (`../../src`, `../../public`); este directorio es el framework.

## Dependencias (stdlib global)

- `modules/httpd` — `Request`, `Response`, parser/serializer HTTP/1.1.
- `modules/socket` — transporte TCP (`serve` usa `listen/accept/read/write`).
- `modules/io` — lectura de archivos estáticos (FFI).
- `json` — intrínseco del lenguaje (deuda host-side, documentada).

## Archivos

| Archivo | Contenido |
|---|---|
| `app.clsx` | `App`: router + middleware + static + CORS + `serve` |
| `router.clsx` | `Router`, `Route`, `RouteMatch`, `route_matches` |
| `middleware.clsx` | `Middleware` (`status == 0` continúa) |
| `static.clsx` | `StaticHandler`, `content_type_for` (io FFI) |
| `cors.clsx` | `CorsOptions`, `cors_apply`, `cors_preflight` |
| `cookies.clsx` | `CookieOptions`, `parse_cookies`, `serialize_cookie` |
| `json.clsx` | helpers JSON (`json_response`, `json_body`, ...) |
| `status.clsx` | `HttpStatus` (constantes + `reason`) |
| `view.clsx` | renderer CMX → HTML (`render`, `raw`, `e`, `renderEach`) |
| `template.clsx` | `Template`, `MetaTag`, `render_html` |
| `lib.clsx` | `system_pid`, `system_uptime_ms`, `system_env` |
| `mod.clsx` | barrel público |

## Uso

```clx
from "tombstone" import App, Request, Response, Template, render;

function main(args: String[]) -> int {
    var app = App();
    app.get("/", (req: Request) -> Response {
        var t = Template();
        t.set_title("Inicio");
        return Response.html(render(t.render((<h1>Hola</h1>))));
    });
    return app.serve("127.0.0.1", 8080);
}
```

Requiere el repo CLS en `pathModules` (ver README del proyecto) para resolver
`httpd`/`socket`/`io`.
