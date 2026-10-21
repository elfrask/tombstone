#!/usr/bin/env sh
# tombstone - launcher de Tombstone (CLI del framework, no de clx).
set -eu
CLX_BIN="${CLX:-clx}"
CONSOLE="${TOMBSTONE_CONSOLE:-src/console.clsx}"
if ! command -v "$CLX_BIN" >/dev/null 2>&1; then
    echo "tombstone: no se encontro '$CLX_BIN' (usa CLX=/ruta/a/clx o agrega clx al PATH)" >&2
    exit 127
fi
exec "$CLX_BIN" run "$CONSOLE" -- "$@"
