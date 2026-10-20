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
- Archivos estáticos: `fs` del nodo desktop (sin io FFI).
- Formularios: urlencoded, multipart (campos + `FormFile`) y JSON en `Request`.
- Validación de request: reglas pipe + builder `field()/schema()`; `Controller`.
- Model: `Model/Query/ModelRow` sobre `modules/orm`; SQLite en el demo.
- Demo: landing real con CMX, iconos, CSS/JS, API JSON, formulario y notas.

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
│   │   ├── static.clsx      # archivos (fs del nodo)
│   │   ├── cors.clsx
│   │   ├── cookies.clsx
│   │   ├── json.clsx
│   │   ├── status.clsx      # HttpStatus
│   │   ├── view.clsx        # CMX -> HTML
│   │   ├── template.clsx    # Template + MetaTag
│   │   ├── lib.clsx         # pid / uptime / env (FFI)
│   │   ├── controller.clsx  # Controller base (request/validación/respuestas)
│   │   ├── model.clsx       # Model/Query/ModelRow (Active Record)
│   │   ├── database.clsx    # Database (driver -> Orm -> Model)
│   │   └── types/           # interfaces de props CMX (HTML + UI)
│   └── tombstone-icons/     # iconos SVG para las vistas
├── src/
│   ├── main.clsx            # proyecto demo (rutas + Template)
│   ├── components.clsx      # componentes CMX (funciones -> Cmx)
│   ├── controllers.clsx     # RegistrationController / NotesController
│   └── views.clsx           # páginas (Landing, Gallery) con <Componente />
├── public/                  # css / js / favicon servidos por /public
├── tests/unit/              # tests in-memory (clx test)
└── tests/integration/       # servidor real + curl
```

Los ladrillos reutilizables viven en la stdlib global: `modules/socket`,
`modules/httpd`, `modules/orm`, `modules/sqlite` y `modules/check`.

## Requisitos

- CLS 2.0 dev-2 compilado: `cargo build --bin clx` (o `--release`).
- `gcc` (MinGW-w64 x64) para los shims de sockets/SQLite.
- `wasm32-unknown-unknown` (lo usa `cls-internals`).

Los shims de `socket` y `sqlite` resuelven su ruta **relativa al CWD**: el
servidor se ejecuta desde la raíz del repo CLS.

```powershell
powershell -File modules\socket\build.ps1
powershell -File modules\sqlite\build.ps1
```

## Demo

Desde la raíz del repo CLS:

```powershell
target\debug\clx.exe run cls-repositories\tombstone\src\main.clsx -- 8080
```

Rutas del demo:

| Método | Ruta | Respuesta |
|--------|------|-----------|
| GET | `/` | landing (Template + componentes CMX + iconos) |
| GET | `/ui` | galería de componentes con props tipados |
| GET | `/api/health` | JSON |
| GET | `/api/users` | JSON (lista) |
| GET | `/users/{id}` | JSON con el param |
| POST | `/api/echo` | JSON con el body recibido |
| POST | `/api/register` | formulario/JSON validado (Controller + `validate`) |
| GET | `/api/notes` | conteo de notas (Model) |
| POST | `/api/notes` | crea nota desde formulario (Model) |
| GET | `/api/notes/{id}` | nota por id (Model) |
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

Model/SQLite (desde la raíz; usa `:memory:`):

```powershell
powershell -File cls-repositories\tombstone\tests\db\run.ps1
```

Cobertura actual: **9 tests unitarios PASS** (request/response/router/app,
template, view, types, validation/form/multipart, cookies/CORS/JSON/static,
status) y **46 checks de integración PASS** (landing, UI kit, API, formulario
validado, Model SQLite, cookies, CORS, static, 404/405).

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

## Componentes CMX + interfaces

Los componentes son **funciones CLS que devuelven `Cmx`** y se usan como tags
`<Componente ... />`. Los props se tipan con las interfaces de
`modules/tombstone/types` y se extienden con herencia de interfaces:

```clx
from "tombstone" import DivProps, raw, render, renderChildren;

interface HeroProps extends DivProps {
    title: String,
    lead: String,
};

function Hero(props: Record<String, Value>, children: Cmx[]) -> Cmx {
    return (
        <div id={str(props.id)} class={str(props.className)}>
            <h1>{str(props.title)}</h1>
            <p>{str(props.lead)}</p>
            {raw(renderChildren(children))}
        </div>
    );
};

var hero: HeroProps = {
    id: "",
    className: "hero",
    role: "",
    hidden: false,
    title: "Tombstone",
    lead: "Framework HTTP en CLS"
};
var props: Record<String, Value> = hero;   # CMX fusiona props desde un Record
var node = (<Hero {...props}><span>slot</span></Hero>);
var html = render(node);
```

- `modules/tombstone/types/*.clsx`: una interface por etiqueta HTML
  (`AnchorProps`, `ButtonProps`, `ImgProps`, `DivProps`, `SvgProps`, ...), más
  las props de UI (`NavBarProps`, `HeroBannerProps`, `ChipProps`, ...). Se
  reexportan desde `"tombstone"`. Ver `modules/tombstone/types/README.md`.
- `ElementProps` es la base (`id`, `className`); cada etiqueta la hereda con
  `extends` y agrega solo sus atributos. Para props opcionales, definí una
  interface con los campos que uses y extendé con `extends Base, OtraBase`.
- `components.clsx` (demo) muestra `Link`, `Button`, `Chip`, `NavBar`,
  `HeroBanner`, `TerminalPanel`, `SiteFooter`, `UiCard`; `views.clsx` compone
  `Landing` y `Gallery` con tags `<Componente />`.

## Formularios, validación y Controller

`Request` parsea formularios además de JSON:

```clx
app.post("/register", (req: Request) -> Response {
    var v = req.validate({
        name: "required|string|min:2|max:40",
        email: "required|email",
        password: "required|min:8|confirmed"
    });
    if (v.failed()) {
        var bad = Response.json_response(json_encode({errors: v.errors}));
        bad.status = 422;
        return bad;
    };
    return Response.json_response(json_encode({ok: true, name: v.data["name"]}));
});
```

- `application/x-www-form-urlencoded` → `req.form`.
- `multipart/form-data` → `req.form` + `req.files` (`FormFile[]`).
- `application/json` → `req.input(name)` / `req.validate(rules)`.
- Reglas: `required`, `nullable`, `string`, `int`, `float`, `bool`, `email`,
  `url`, `date`, `uuid`, `alpha`, `alnum`, `alpha_dash`, `accepted`,
  `confirmed`, `min`, `max`, `size`, `between`, `in`, `not_in`, `same`,
  `different`, `required_if`, `starts_with`, `ends_with`, `contains`.
- `Controller` (base) expone `input/all/param/file`, `validate`,
  `validate_schema`, `json/ok/created/no_content/invalid`, `redirect`.
- `schema({ name: field().required().string().min(2).to_rule() })` es el
  builder chainable estilo schema.

## Model (SQLite / `modules/orm`)

El motor es agnóstico al driver; el demo usa `modules/sqlite`:

```clx
import "sqlite" as sqlite;
var db = Database(sqlite::SqliteDriver());
db.connect(":memory:");
db.exec("CREATE TABLE notes (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT)");
var notes = db.table("notes");

var note = notes.create({title: "Hola"});
var row = notes.find(note.get("id"));
row.set("title", "Chau");
row.save();
var page = notes.paginate(1, 10);
```

`Model`: `all`, `all_ordered`, `find`, `find_or_fail`, `find_many`, `first`,
`first_or_fail`, `first_where`, `create`, `insert`, `update`, `delete`,
`destroy`, `count`, `exists`, `pluck`, `value`, `max/min/avg/sum`,
`first_or_create`, `update_or_create`, `increment`, `truncate`, `paginate`,
`where`, `query`.
`Query`: `where`, `where_eq/like/in/null/not_null/between`, `order_by`,
`latest/oldest`, `limit/offset/take/skip`, `get`, `first`, `count`, `exists`,
`pluck`, `value`, `sum/max/min/avg`, `update`, `delete`.
`ModelRow`: `get/get_str/get_int/get_float/get_bool`, `set`, `fill`,
`to_record`, `save`, `delete`.

> Cobertura del núcleo de Active Record. Relaciones, eventos, timestamps
> automáticos, soft deletes y migraciones quedan fuera de esta fase.

### API

- `App`: `get/post/put/patch/delete_route/options`, `use`, `serve_static`,
  `cors`, `handle(raw)`, `dispatch(Request)`, `serve(host, port)`.
- `Router`: `add`, verbos, `dispatch(Request)`; `{param}` + 404/405.
- `Middleware`: `(Request) -> Response`; `status == 0` continúa.
- `Request`: `http_method`, `path`, `query`, `query_param`, `headers`,
  `header`, `body`, `params`, `param`, `form`, `files`, `input`, `all`,
  `validate`, `validate_schema`, `file`, `has_file`.
- `ValidationResult`: `ok`, `failed`, `first`, `errors`, `data`;
  `field()`/`schema()` para armar reglas; `validate_data(data, rules)`.
- `Controller`: `input/all/param/file`, `validate`, `validate_schema`,
  `json/ok/created/accepted/no_content/invalid/error/redirect`.
- `Database`: `connect/close/exec/query/begin/commit/rollback/table`.
- `Model`: ver sección Model (`all`, `find`, `create`, `update`, `delete`,
  `where`, `paginate`, agregados, ...); `ModelRow`/`Query`/`Paginator`.
- `Response`: `text`, `html`, `json_raw`, `json_response`, `redirect`,
  `status_only`, `not_found`, `header`, `set_cookie`, `serialize`.
- `Template`: `set_*`, `add_style`, `add_script`, `add_meta`,
  `add_meta_prop`, `derive`, `render(page)`.
- `view`: `e`, `raw`, `render`, `renderChildren`, `attrs`, `isVoid`,
  `renderEach`, `layout`, `ul_items`.
- `types` (dentro de `tombstone`): interfaces de props de etiquetas HTML + UI
  (solo compile-time).
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
from "tombstone" import AnchorProps, ButtonProps, DivProps;
from "tombstone-icons" import icon;
```

El consumidor también necesita `modules/socket`, `modules/httpd` y, si usa
Model, `modules/orm`/`modules/sqlite`; `static` usa `fs` del nodo.

## Limitaciones conocidas

- HTTP/1.1 sin `Transfer-Encoding: chunked` ni keep-alive (una request por
  conexión, `Connection: close`).
- `headers` es `Record<String, String>`: el último valor gana; `Set-Cookie`
  múltiple queda pendiente.
- Router: solo params requeridos `{id}`. Faltan constraints (`where`),
  opcionales (`{id?}`), named routes y controllers como clases.
- CMX: un child que es `Array` no se expande solo; usar `renderEach` + `raw`.
  Los componentes uppercase deben devolver `Cmx` (para HTML crudo: `raw`).
- Spread de props: el source debe ser `Record<String, Value>`; un interface
  (Shape) se convierte con `var r: Record<String, Value> = propsTipados;` antes
  de `<Componente {...r} />`.
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
También se corrigió el tag de tipo de las expresiones `str(...)` como atributos
CMX en componentes con children anidados (regresión
`units/cmx-component-attr.clsx`).

## Licencia

MIT (ver `LICENSE`).
