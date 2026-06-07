#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

npm run typecheck
output="$(npm test -- --reporter=verbose 2>&1)"
printf '%s\n' "$output" >&2
printf '%s\n' "$output" | grep -Eo '\[S[0-9]+\]' | tr -d '[]' | sort -u | sed 's/^/[green] /'
npm run build
