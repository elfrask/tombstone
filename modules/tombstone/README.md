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

## Model y Database

`Database` recibe un `orm::Driver`; `Model` es agnóstico al motor. El demo usa
SQLite:

```clx
import "sqlite" as sqlite;
from "tombstone" import Database;

var db = Database(sqlite::SqliteDriver());
db.connect(":memory:");
db.exec("CREATE TABLE notes (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT)");
var notes = db.table("notes");
var note = notes.create({title: "Hola"});
var row = notes.find(note.get("id"));
```

API principal: `all`, `find`, `find_or_fail`, `first`, `first_or_fail`,
`create`, `insert`, `update`, `delete`, `destroy`, `count`, `exists`, `pluck`,
`value`, `max/min/avg/sum`, `first_or_create`, `update_or_create`, `increment`,
`truncate`, `paginate`, `where`, `query`; el `Query` incluye `where_eq/like/in/
null/not_null/between`, `order_by`, `limit/offset`, `get/first/count/pluck/
value`, agregados, `update/delete`. Relaciones/eventos/soft deletes/timestamps
automáticos/migraciones quedan fuera de esta fase.

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
