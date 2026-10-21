#!/usr/bin/env sh
# tombstone - launcher del modulo (no pertenece a clx).
set -eu
MODULE_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
CLX_BIN="${CLX:-clx}"
if [ -f "src/console.clsx" ]; then
    CONSOLE="src/console.clsx"
else
    CONSOLE="${TOMBSTONE_CONSOLE:-$MODULE_DIR/console.clsx}"
fi
if ! command -v "$CLX_BIN" >/dev/null 2>&1; then
    echo "tombstone: no se encontro '$CLX_BIN' (usa CLX=/ruta/a/clx)" >&2
    exit 127
fi
exec "$CLX_BIN" run "$CONSOLE" -- "$@"
