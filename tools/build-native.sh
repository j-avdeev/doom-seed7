#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENTRY="${1:-doom3_seed7_runtime.s7}"
SEED7_JS="${SEED7_JS:-seed7/bin/s7.js}"
SEED7_LIB="${SEED7_LIB:-seed7/lib}"

if [[ ! -f "$SEED7_JS" ]]; then
  echo "Seed7 JS runtime not found: $SEED7_JS" >&2
  exit 1
fi

if [[ ! -d "$SEED7_LIB" ]]; then
  echo "Seed7 library directory not found: $SEED7_LIB" >&2
  exit 1
fi

if [[ ! -f "$ENTRY" ]]; then
  echo "Seed7 entrypoint not found: $ENTRY" >&2
  exit 1
fi

cat >&2 <<MSG
Native build placeholder.

Current local smoke command:
  node "$SEED7_JS" -l "$SEED7_LIB" "$ENTRY" --smoke_frames 2

Future compiled-native command shape still needs validation. See:
  docs/browser-runtime.md
MSG

exit 2
