# Tipos de props CMX

Interfaces de **compile-time** para tipar los props de los componentes CMX. Se
exportan desde el barrel del módulo:

```clx
from "tombstone" import AnchorProps, ButtonProps, DivProps;

var cta: ButtonProps = {
    id: "",
    className: "btn btn--primary",
    type: "button",
    disabled: false,
};
var r: Record<String, Value> = cta;
var node = (<Button {...r}>Comenzar</Button>);
```

Los nombres siguen el estilo de props de componente (`className`, `htmlFor`,
`formMethod`, `readOnly`, `asyncScript`, `strokeWidth`, ...). El componente
traduce a atributos HTML (`class`, `for`, `method`, ...).

Cada archivo agrupa interfaces por área:

| Archivo | Etiquetas |
|---|---|
| `global.clsx` | `ElementProps` (base: `id`, `className`), `GlobalProps`, `ChildList` |
| `document.clsx` | `html`, `head`, `body`, `title`, `meta`, `link`, `style`, `script`, `base`, `noscript` |
| `sections.clsx` | `header`, `footer`, `main`, `section`, `article`, `aside`, `nav`, `address`, `div`, `span`, `hgroup`, `search` |
| `text.clsx` | `h1`–`h6`, `p`, `a`, `blockquote`, `pre`, `code`, `kbd`, `samp`, `var`, `em`, `strong`, `small`, `mark`, `del`, `ins`, `sub`, `sup`, `abbr`, `cite`, `q`, `time`, `data`, `bdi`, `bdo`, `ruby`, `rt`, `rp`, `br`, `wbr`, `hr` |
| `lists.clsx` | `ul`, `ol`, `li`, `dl`, `dt`, `dd` |
| `forms.clsx` | `form`, `input`, `button`, `textarea`, `select`, `option`, `optgroup`, `label`, `fieldset`, `legend`, `datalist`, `output`, `progress`, `meter` |
| `media.clsx` | `img`, `picture`, `source`, `video`, `audio`, `track`, `canvas`, `map`, `area`, `object`, `embed`, `iframe` |
| `table.clsx` | `table`, `caption`, `colgroup`, `col`, `thead`, `tbody`, `tfoot`, `tr`, `th`, `td` |
| `svg.clsx` | `svg`, `g`, `path`, `circle`, `ellipse`, `rect`, `line`, `polyline`, `polygon`, `text`, `defs`, `use`, `symbol`, gradientes, `stop`, `clipPath`, `mask`, `pattern`, `marker`, `image`, `a`, `title`, `desc`, `foreignObject` |
| `misc.clsx` | `figure`, `figcaption`, `details`, `summary`, `dialog`, `menu`, `template`, `slot` |
| `ui.clsx` | props de componentes del demo (`NavBarProps`, `HeroBannerProps`, `ChipProps`, ...) |

## Reglas

- **camelCase** para nombres compuestos: `className`, `htmlFor`, `formMethod`,
  `httpEquiv`, `acceptCharset`, `readOnly`, `asyncScript`, `defaultTrack`,
  `strokeWidth`, `viewBox`.
- Cada etiqueta **hereda** `ElementProps` (`id`, `className`) con `extends`; no
  se repiten campos base. Para props opcionales, definí una interface con solo
  los campos que usás y extendé la del tag:

```clx
interface HeroProps extends SectionProps {
    title: String,
    lead: String,
};
```

- Se pueden heredar **varias** interfaces (y con genéricos):

```clx
interface Labeled<T> {
    label: T,
};
interface StringLabel extends Labeled<String> {
    count: Int,
};
interface CardProps extends DivProps, GlobalProps {
    title: String,
    body: String,
};
```

- Los atributos globales (style/aria/data) están en `GlobalProps`, que a su vez
  extiende `ElementProps`.
