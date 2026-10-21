# `tombstone` — motor del framework web

Módulo CLS con el motor de Tombstone. El proyecto de presentación/pruebas vive
fuera (`../../src`, `../../public`); este directorio es el framework.

## Dependencias (stdlib global)

- `modules/httpd` — `Request`, `Response`, parser/serializer HTTP/1.1.
- `modules/socket` — transporte TCP (`serve` usa `listen/accept/read/write`).
- `modules/orm` — capa ORM agnóstica (Cell/ResultSet/Orm).
- `modules/sqlite` — backend SQLite (FFI; el demo lo conecta).
- `fs` — lectura de archivos estáticos (módulo desktop del nodo).
- `json` — intrínseco del lenguaje (deuda host-side, documentada).

## Archivos

| Archivo | Contenido |
|---|---|
| `app.clsx` | `App`: router + middleware + static + CORS + `serve` |
| `router.clsx` | `Router`, `Route`, `RouteMatch`, `route_matches` |
| `group.clsx` | `RouteGroup` (prefijo + middleware por grupo) |
| `middleware.clsx` | `Middleware` (`status == 0` continúa) |
| `static.clsx` | `StaticHandler`, `content_type_for` (`fs` del nodo) |
| `cors.clsx` | `CorsOptions`, `cors_apply`, `cors_preflight` |
| `cookies.clsx` | `CookieOptions`, `parse_cookies`, `serialize_cookie` |
| `json.clsx` | helpers JSON (`json_response`, `json_body`, ...) |
| `status.clsx` | `HttpStatus` (constantes + `reason`) |
| `view.clsx` | renderer CMX → HTML (`render`, `raw`, `e`, `renderEach`) |
| `template.clsx` | `Template`, `MetaTag`, `render_html` |
| `lib.clsx` | `system_pid`, `system_uptime_ms`, `system_env` |
| `controller.clsx` | `Controller` base |
| `model.clsx` | `Model`, `Query`, `ModelRow`, `Paginator` |
| `database.clsx` | `Database` (driver -> Orm -> Model) |
| `schema.clsx` | `DbSchema`, `Blueprint`, `Column` (migraciones) |
| `migration.clsx` | `Migration`, `MigrationRunner` |
| `factory.clsx` | `Factory` (datos para tests/seeds) |
| `event.clsx` | `Event`, `EventBus`, `Listener` |
| `log.clsx` | `Logger` (niveles + buffer) |
| `action.clsx` | `Action`, `Service` (marcadores de capa) |
| `hash.clsx` | Argon2id + compatibilidad SHA-256 legado |
| `session.clsx` | `Session`, `SessionStore`, `DbSessionStore` |
| `auth.clsx` | `AuthGuard` |
| `security.clsx` | `Csrf`, `CsrfMiddleware`, `NotePolicy`, `Gate`, `RateLimiter`, `RateLimitMiddleware` |
| `resource.clsx` | `Resource` (ModelRow -> JSON) |
| `pagination.clsx` | `PaginatedResource` (data + meta) |
| `testing.clsx` | `TestClient`, `TestResponse` (in-process) |
| `cache.clsx` | `Cache`, `FileCache` con TTL |
| `seeder.clsx` | `Seeder` base idempotente |
| `types/*.clsx` | interfaces de props CMX (una por etiqueta HTML + UI) |
| `mod.clsx` | barrel público (motor + tipos) |

## Tipos CMX

`types/*.clsx` define una interface por etiqueta HTML (`AnchorProps`,
`DivProps`, `InputProps`, `ImgProps`, `TableProps`, `SvgProps`, ...) más props
de UI (`NavBarProps`, `ChipProps`, ...). El barrel reexporta todo:

```clx
from "tombstone" import AnchorProps, DivProps;

interface HeroProps extends DivProps {
    title: String,
    lead: String,
};

var hero: HeroProps = {
    id: "hero",
    className: "hero",
    role: "",
    hidden: false,
    title: "Tombstone",
    lead: "Framework web CLS",
};
var r: Record<String, Value> = hero;
var node = (<Hero {...r} />);
```

Los nombres son camelCase (`className`, `htmlFor`, `formMethod`, `readOnly`) y
los campos son requeridos; para props opcionales se define una interface y se
hereda con `extends`. Ver `types/README.md`.

## Controller y validación

```clx
from "tombstone" import Controller, Request, Response;

class UsersController: Controller {
    function main(req: Request) { super.main(req); }
    function store() -> Response {
        var v = me.validate({name: "required|min:2", email: "required|email"});
        if (v.failed()) { return me.invalid(v); };
        return me.created({ok: true, name: v.data["name"]});
    }
};
```

`req.input(name)` lee body (form/JSON) → query → params.
`req.validate(rules)` devuelve `ValidationResult` (`ok/failed/first/data`).
Reglas: `required`, `nullable`, `string`, `int`, `float`, `bool`, `email`,
`url`, `date`, `uuid`, `alpha`, `alnum`, `alpha_dash`, `accepted`, `confirmed`,
`min`, `max`, `size`, `between`, `in`, `not_in`, `same`, `different`,
`required_if`, `starts_with`, `ends_with`, `contains`.
También hay builder chainable: `schema({name: field().required().min(2).to_rule()})`.

## Model, migraciones, relaciones y factories
Controllers como clases: `app.controller("GET", "/notes", "index", notesController)`;
`Router` guarda un `ControllerRoute` y llama `prepare/set_action/handle` sin closure.


`Database` recibe un `orm::Driver`; `Model` es agnóstico al motor. El demo usa
SQLite y migraciones versionadas:

```clx
import "sqlite" as sqlite;
from "tombstone" import Database, MigrationRunner;

var db = Database(sqlite::SqliteDriver());
db.connect(":memory:");
MigrationRunner(db.orm).add(CreateInitialSchema()).run();
var notes = db.table("notes").timestamps().soft_deletes();
var note = notes.create({title: "Hola"});
```

`DbSchema` construye el esquema (el nombre `Schema` está reservado por la
validación): `blueprint`, `create`, `alter`, `drop`, `has_table`,
`has_column`; `Blueprint` expone `id`, `string/text/integer/float/boolean`,
`timestamps`, `soft_deletes`, `foreign_id`, `index`, `unique`.
`MigrationRunner` aplica migraciones por batch (`run`, `rollback`, `reset`,
`status`).

`Model`: `timestamps`, `soft_deletes`, `all`, `find`, `find_or_fail`, `first`,
`first_or_fail`, `create`, `insert`, `update`, `delete`, `force_delete`,
`restore`, `trashed`, `destroy`, `with_trashed`, `only_trashed`, `has_many`,
`has_one`, `belongs_to`, `count`, `exists`, `pluck`, `value`, `max/min/avg/sum`,
`first_or_create`, `update_or_create`, `increment`, `truncate`, `paginate`,
`where`, `query`.
`Query`: `where_eq/like/in/null/not_null/between`, `order_by`, `limit/offset`,
`get/first/count/pluck/value`, agregados, `update/delete`, `force_delete`,
`restore`, `with_trashed`, `only_trashed`.
`Factory`: `make`, `create`, `create_many`.

## Eventos, logging y capas de aplicación

`EventBus` es síncrono y tipado por `Event`/`Record<String,String>`:

```clx
var bus = EventBus();
bus.on("note.created", (e: Event) -> int {
    print(e.payload["id"]);
    return 1;
});
bus.dispatch_name("note.created", {id: "1"});
```

`Model` emite `creating/created`, `updating/updated`, `deleting/deleted`,
`force_deleting/force_deleted`, `restoring/restored`; `creating/updating/...`
pueden cancelar con `e.cancel()` (lanza error). Compartir un bus:
`db.set_events(bus)` antes de `db.table(...)`.

`Logger` tiene niveles `debug/info/warn/error` y buffer `entries` para tests.
`Action` y `Service` son marcadores de capa; las clases concretas implementan
`handle`. El demo usa `ApplicationServices` (campos tipados), `ServiceProvider`
(`register`/`boot`), `NoteRepository`, `NoteInput`/`RegisterUserInput` y
Actions para el flujo `Controller -> DTO -> Action -> Repository -> Model`.

## Seguridad

- `hash_password`/`verify_password`: Argon2id (`libargon2`) con salt desde
  `modules/csprng`. Los hashes `sha256$...` legados se verifican y se rehashean
  al iniciar sesión.
- `SessionStore` en memoria; `DbSessionStore` persiste en `sessions` con
  expiración (24 h).
- `AuthGuard.login(email, password)` valida `users.password_hash`, crea sesión
  y rota la anterior; `user/check/guest/logout`.
- `Csrf` emite/valida token por sesión; `CsrfMiddleware` exige header
  `X-CSRF-Token` o campo `_csrf` en métodos mutantes con cookie.
- `NotePolicy` aplica owner/admin por recurso.
- `RateLimiter` por clave/ventana; `RateLimitMiddleware` limita HTTP global
  (429 + `Retry-After`). Login usa además 5/min.

## Uso

```clx
from "tombstone" import App, Request, Response, Template, render;
from "tombstone" import AnchorProps, DivProps;

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
`httpd`/`socket`/`orm`/`sqlite`; `static` usa `fs` del nodo.

## CLI y setup

- `bin/tombstone` (POSIX) y `bin/tombstone.cmd` (Windows) son el launcher del
  módulo; no son comandos de `clx`.
- `setup.clsx` registra el paquete al instalar `clx install` (una vez por
  versión) y se apoya en `CLS_MODULE_DIR` / `CLS_GLOBAL_BIN`.
- `clx start` añade al `PATH` los `bin/` de los módulos resueltos
  (`modules/*/bin`, `pathModules`, `~/.cls/modules`, `~/.cls/bin`).
