# `tombstone-icons` — iconos SVG inline

Colección de iconos de trazo para las vistas CMX de Tombstone. Sin
dependencias ni emojis.

## Uso

```clx
from "tombstone-icons" import icon;

var vista = (
    <li>{icon("route")}<span>Router</span></li>
);
```

`icon(name) -> Cmx` devuelve un nodo CMX; se inserta por interpolación
(`{icon("...")}`). El renderer de `tombstone` lo procesa como un elemento SVG
normal.

Iconos: `route`, `layers`, `code`, `socket`, `globe`, `cookie`, `folder`,
`braces`, `tick`, `logo` (fallback: `dot`).
