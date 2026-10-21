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
- Seguridad: password hashing con CSPRNG, sesiones SQL, `AuthGuard`, CSRF
  enforced, `NotePolicy` y rate limit global.
- Capa de aplicación: `EventBus` + model events, `Logger`, `Action`/`Service`,
  DTOs, `NoteRepository`, `ServiceProvider` y `ApplicationServices` tipados.
- ORM de aplicación: migraciones (`MigrationRunner` + `DbSchema`), relaciones
  (`has_many`/`has_one`/`belongs_to`), timestamps, soft deletes y factories.
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
│   │   ├── schema.clsx      # DbSchema/Blueprint/Column (migraciones)
│   │   ├── migration.clsx   # Migration + MigrationRunner
│   │   ├── factory.clsx     # Factory (datos para tests/seeds)
│   │   ├── event.clsx       # EventBus + Event/Listener
│   │   ├── log.clsx         # Logger
│   │   └── action.clsx      # Action/Service
│   │   ├── group.clsx        # RouteGroup (prefijo + middleware)
│   │   ├── resource.clsx     # Resource (presentación JSON)
│   │   ├── pagination.clsx   # PaginatedResource
│   │   └── types/           # interfaces de props CMX (HTML + UI)
│   └── tombstone-icons/     # iconos SVG para las vistas
├── src/
│   ├── main.clsx            # proyecto demo (rutas + Template)
│   ├── components.clsx      # componentes CMX (funciones -> Cmx)
│   ├── controllers.clsx     # RegistrationController / NotesController
│   ├── config.clsx          # AppConfig (env)
│   ├── dtos.clsx            # DTOs de casos de uso
│   ├── repositories.clsx    # NoteRepository
│   ├── actions.clsx         # Create/Delete/RestoreNoteAction
│   ├── services.clsx        # ApplicationServices + providers + bootstrap
│   ├── resources.clsx       # NoteResource
│   ├── scopes.clsx          # NoteScopes (query objects)
│   ├── migrations.clsx      # esquema versionado del demo
│   └── views.clsx           # páginas (Landing, Gallery) con <Componente />
├── public/                  # css / js / favicon servidos por /public
├── tests/unit/              # tests in-memory (clx test)
├── tests/db/                # Model + migraciones/relaciones/soft deletes
└── tests/integration/       # servidor real + curl
```

Los ladrillos reutilizables viven en la stdlib global: `modules/socket`,
`modules/httpd`, `modules/orm`, `modules/sqlite` y `modules/check`.

## Requisitos

- CLS 2.0 dev-2 compilado: `cargo build --bin clx` (o `--release`).
- `gcc` (MinGW-w64 x64) para los shims de sockets/SQLite.
- `wasm32-unknown-unknown` (lo usa `cls-internals`).

Los shims nativos se resuelven contra el `cls.json` del módulo, no contra el
CWD. Ya se puede ejecutar el servidor desde cualquier directorio.

```powershell
powershell -File modules\socket\build.ps1
powershell -File modules\sqlite\build.ps1
```

## Build

```powershell
target\debug\clx.exe build
```

Genera `dist/app.clsapp` y `dist/native-libs/<paquete>@<version>/`. Cada paquete
conserva los nombres originales de sus `.dll`/`.so`/`.dylib` y no comparte
carpeta con otros módulos, evitando colisiones entre versiones. El manifiesto
del `.clsapp` incluye el mapa `nativeLibs`.

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
| POST | `/api/login` | login email/password; cookie de sesión + `X-CSRF-Token` |
| GET | `/api/csrf` | token CSRF de la sesión (crea sesión si falta) |
| GET | `/api/me` | usuario de la sesión o 401 |
| POST | `/api/logout` | destruye la sesión |
| GET | `/api/notes` | conteo de notas (Model, sin soft-deleted) |
| POST | `/api/notes` | crea nota desde formulario (Model) |
| GET | `/api/notes/trashed` | conteo de notas en la papelera |
| GET | `/api/notes/page` | notas paginadas (`PaginatedResource`) |
| DELETE | `/api/notes/{id}` | soft delete |
| POST | `/api/notes/{id}/restore` | restaura una nota |
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
powershell -File cls-repositories\tombstone\tests\unit\run.ps1
```

Integración HTTP real (desde la raíz del repo CLS):

```powershell
powershell -File cls-repositories\tombstone\tests\integration\http_smoke.ps1
```

Model/SQLite (desde la raíz; usa `:memory:`):

```powershell
powershell -File cls-repositories\tombstone\tests\db\run.ps1
```

Cobertura actual: **11 tests unitarios PASS** (request/response/router/app,
template, view, types, validation/form/multipart, cookies/CORS/JSON/static,
status), **75 checks DB PASS** (Model CRUD + migraciones, relaciones, eventos,
timestamps, soft deletes, factories, sessions/CSRF y policies) y **70 checks de
integración PASS** (landing, UI kit, API, auth/sesión, CSRF, rate limit,
Model SQLite + soft delete/restore, cookies, CORS, static, 404/405).

## Configuración de seguridad

- `TOMBSTONE_SECURE_COOKIE=1`: añade `Secure` a la cookie `sid` (producción/HTTPS).
- `TOMBSTONE_DB=archivo.db`: sesiones persistentes en SQLite (por defecto `:memory:`).
- `TOMBSTONE_ENV=production`: desactiva `debug`; no cambia el KDF.
- CSRF: el login devuelve `X-CSRF-Token`; también `GET /api/csrf`. En métodos
  mutantes con cookie se acepta `X-CSRF-Token` o `_csrf` en el formulario.
- Rate limit global: 300 req/min por IP (`X-Forwarded-For` o `local`), además
  de 5 intentos/min para `/api/login`.

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
MigrationRunner(db.orm).add(CreateInitialSchema()).run();
var users = db.table("users").timestamps();
var notes = db.table("notes").timestamps().soft_deletes();

var note = notes.create({title: "Hola"});
var row = notes.find(note.get("id"));
row.set("title", "Chau");
row.save();
var page = notes.paginate(1, 10);
```

`Model`: `timestamps`, `soft_deletes`, `all`, `all_ordered`, `find`,
`find_or_fail`, `find_many`, `first`, `first_or_fail`, `first_where`, `create`,
`insert`, `update`, `delete`, `force_delete`, `restore`, `trashed`, `destroy`,
`with_trashed`, `only_trashed`, `has_many`/`hasMany`, `has_one`/`hasOne`, `belongs_to`/`belongsTo`, `count`,
`exists`, `pluck`, `value`, `max/min/avg/sum`, `first_or_create`,
`update_or_create`, `increment`, `truncate`, `paginate`, `where`, `query`.
`Query`: `where`, `where_eq/like/in/null/not_null/between`, `order_by`,
`latest/oldest`, `limit/offset/take/skip`, `get`, `first`, `count`, `exists`,
`pluck`, `value`, `sum/max/min/avg`, `update`, `delete`, `force_delete`,
`restore`, `with_trashed`, `only_trashed`.
`ModelRow`: `get/get_str/get_int/get_float/get_bool`, `set`, `fill`,
`to_record`, `save`, `delete`, `force_delete`, `restore`, `trashed`.

### Migraciones y schema

`DbSchema` es el builder portable (el nombre `Schema` ya lo usa la validación):

```clx
from "tombstone" import Migration, MigrationRunner, DbSchema;

class CreateUsers: Migration {
    function main() { super.main("2026_01_01_000001_create_users"); }
    function up(schema: DbSchema) -> int {
        var t = schema.blueprint("users");
        t.id();
        t.string("email").unique();
        t.timestamps();
        return schema.create(t);
    }
    function down(schema: DbSchema) -> int { return schema.drop("users"); }
};

MigrationRunner(db.orm).add(CreateUsers()).run();
```

- `DbSchema`: `blueprint`, `create`, `alter` (ADD COLUMN), `drop`,
  `has_table`, `has_column`.
- `Blueprint`: `id`, `string/text/char/integer/big_integer/float/boolean`,
  `timestamp`, `timestamps`, `soft_deletes`, `foreign_id`, `index`, `unique`.
- `Column`: `nullable`, `unique`, `with_default`, `references`.
- `MigrationRunner`: `add`, `run` (idempotente, un batch nuevo), `rollback`
  (último batch), `reset`, `status`.

### Relaciones, timestamps y soft deletes

```clx
var ana = users.create({name: "Ana", email: "ana@example.com"});
var n1 = notes.create({user_id: ana.get("id"), title: "Primera"});

users.has_many(notes, "user_id", ana.get("id")).get();
users.has_one(notes, "user_id", ana.get("id"));
notes.belongs_to(users, "user_id", n1.get("id"));

notes.delete(n1.get("id"));           # soft delete si soft_deletes()
notes.with_trashed().count();         # incluye papelera
notes.only_trashed().get();
notes.restore(n1.get("id"));
notes.force_delete(n1.get("id"));     # borrado físico
```

`timestamps()` escribe `created_at`/`updated_at` en milisegundos Unix;
`soft_deletes()` usa `deleted_at` y filtra por defecto en `Model`/`Query`.

### Factories

```clx
function user_definition(n: int) -> Record<String, String> {
    var r: Record<String, String> = {
        name: "User " + n.toString(),
        email: "u" + n.toString() + "@test.local"
    };
    return r;
}

class UserFactory: Factory {
    function main(users: Model) { super.main(users, user_definition); }
};

var ana = UserFactory(users).create({name: "Ana"});
var many = UserFactory(users).create_many(3, {});
```

`Factory.make` mezcla la definición con overrides y avanza una secuencia;
`create` persiste y `create_many` crea N filas.

### Capa de aplicación

El demo separa controller, DTO, Action y Repository:

- `ApplicationServices` (`src/services.clsx`) es el contenedor tipado:
│   ├── resources.clsx       # NoteResource
│   ├── scopes.clsx          # NoteScopes (query objects)
  `config`, `db`, `events`, `logger`, `notes`, `create_note`, `delete_note`,
  `restore_note`.
- `ServiceProvider` expone `register(services)`/`boot(services)`; `bootstrap`
- `App.controller(metodo, ruta, accion, controller)` usa `ControllerRoute`;
  construye el bus, comparte `db.set_events(events)` y registra providers.
- `NoteRepository` envuelve `Model` y es la única puerta de datos para las
  Actions.
- `NoteInput`/`RegisterUserInput` son DTOs explícitos; `NotesController` valida
  y delega en Actions.
- `EventBus` emite `created/updated/deleted/restored` desde `Model`; los
- `NoteScopes` agrupa query objects (`recent`, `search`, `trashed`).
- `PaginatedResource` serializa `data` + `meta` para `/api/notes/page`.
  listeners del `DomainProvider` los loguean.
- `ModelRow.save()`/`ModelRow.delete()` no emiten eventos (solo las operaciones
  de `Model`); documentado como límite actual.

### API

- `App`: `get/post/put/patch/delete_route/options`, `controller`, `group`, `route`,
  `use`, `serve_static`,
  `cors`, `handle(raw)`, `dispatch(Request)`, `serve(host, port)`.
- `Router`: `add`, `add_named`, `url`, `controller`, verbos, `dispatch(Request)`;
  `{param}`, `{id?}`, named routes y 404/405.
- `Middleware`: `(Request) -> Response`; `status == 0` continúa.
- `RouteGroup`: prefijo, verbos y middleware por ruta/grupo.
- `Resource`: transforma `ModelRow` a `Record<String,String>`/colección.
- `PaginatedResource`: serializa `Paginator` + `Resource` con `data`/`meta`.
- `Request`: `http_method`, `path`, `query`, `query_param`, `headers`,
  `header`, `body`, `params`, `param`, `form`, `files`, `input`, `all`,
  `validate`, `validate_schema`, `file`, `has_file`.
- `ValidationResult`: `ok`, `failed`, `first`, `errors`, `data`;
  `field()`/`schema()` para armar reglas; `validate_data(data, rules)`.
- `Controller`: `input/all/param/file`, `validate`, `validate_schema`, `prepare`,
  `set_action`, `handle`,
  `json/ok/created/accepted/no_content/invalid/error/redirect`.
- `Database`: `connect/close/exec/query/begin/commit/rollback/table`,
  `table_with_key`, `schema`.
- `Model`: ver secci�n Model (`all`, `find`, `create`, `update`, `delete`,
  `force_delete`, `restore`, `with_trashed`, `only_trashed`, relaciones,
  `where`, `paginate`, agregados, ...); `ModelRow`/`Query`/`Paginator`.
- `Event`/`EventBus`/`Listener`: eventos síncronos y model events.
- `hash_password`/`verify_password`: Argon2id (`libargon2`) con salt CSPRNG (`modules/csprng`); acepta `sha256$...` legado y rehashea al login.
- `Session`/`SessionStore`: store en memoria; `DbSessionStore`: tabla `sessions`.
- `AuthGuard`: login/logout/user/check/guest sobre `users.password_hash`.
- `Csrf`/`CsrfMiddleware`: token por sesión, header o campo `_csrf`.
- `NotePolicy`: owner/admin para `view/update/delete`.
- `Gate`, `RateLimiter`/`RateLimitMiddleware`: autorización base y rate limit
  global (429 + `Retry-After`).
- `Logger`: niveles + buffer de test.
- `Action`/`Service`: marcadores de capa; providers en el demo.
- `DbSchema`/`Blueprint`/`Column`: schema builder y migraciones.
- `Migration`/`MigrationRunner`: migraciones versionadas (`run`, `rollback`,
  `reset`, `status`).
- `Factory`: `make`, `create`, `create_many`.
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
- Auth: password hash Argon2id (`t=2`, `m=19456`, `p=1`) con salt CSPRNG y
  rehash automático de hashes `sha256$...` legados.
- Sesiones persistentes en SQLite; `TOMBSTONE_SECURE_COOKIE=1` activa `Secure`
  (requiere HTTPS). CSRF se exige con cookie de sesión en métodos mutantes.
- `headers` es `Record<String, String>`: headers simples usan el último valor;
  los `Set-Cookie` múltiples usan `Response.add_cookie`.
- Router: faltan constraints (`where`); `{id?}`, named routes y controllers
  como clases ya están implementados.
- CMX: un child que es `Array` no se expande solo; usar `renderEach` + `raw`.
  Los componentes uppercase deben devolver `Cmx` (para HTML crudo: `raw`).
- Spread de props: el source debe ser `Record<String, Value>`; un interface
  (Shape) se convierte con `var r: Record<String, Value> = propsTipados;` antes
  de `<Componente {...r} />`.
- JSON: usa el módulo interno `json` del nodo (deuda host-side). El parser es
  permisivo; no se expone un validador estricto. `json.stringify(array)` no es
  fiable: se usa `json_string_array`.
- `static` / sockets / I/O: los shims se resuelven contra el `cls.json` del
  módulo; el CWD ya no determina la ruta del `.dll`.
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
