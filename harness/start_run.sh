#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
mkdir -p "$ROOT/state"
rm -f "$ROOT/state/DONE" "$ROOT/state/verify-report.txt" "$ROOT/state/run.log" "$ROOT/state/cursor"
rm -rf "$ROOT/state/backlog.lock"
printf 'S1\tTODO\t0\t0\nS2\tTODO\t0\t0\n' > "$ROOT/state/backlog.tsv"
printf '0\n' > "$ROOT/state/tokens.log"
printf '[start] initialized codex-ralph run\n' | tee "$ROOT/state/run.log"
