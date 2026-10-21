#!/usr/bin/env sh
# Instala los launchers de Tombstone en ~/.cls/bin.
set -eu
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
BIN="${HOME:?}/.cls/bin"
mkdir -p "$BIN"
cp "$ROOT/bin/tombstone.sh" "$BIN/tombstone"
chmod +x "$BIN/tombstone"
if [ -f "$ROOT/bin/tombstone.cmd" ]; then cp "$ROOT/bin/tombstone.cmd" "$BIN/tombstone.cmd"; fi
echo "Instalado en $BIN"
echo "Asegurate de tener '$BIN' en PATH."
