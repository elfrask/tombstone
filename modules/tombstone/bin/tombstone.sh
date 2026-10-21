#!/usr/bin/env sh
# Alias .sh del launcher (para shells que lo invocan por nombre).
set -eu
HERE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
exec "$HERE/tombstone" "$@"
