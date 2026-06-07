#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMPROOT="$(mktemp -d "${TMPDIR:-/tmp}/codex-ralph-backlog.XXXXXX")"
COUNT=0

cleanup() { rm -rf "$TMPROOT"; }
trap cleanup EXIT

pass() { COUNT=$((COUNT + 1)); printf '[T%s] %s\n' "$((COUNT + 8))" "$1"; }
fail() { printf '[backlog-smoke] RED: %s\n' "$1" >&2; exit 1; }

mkcase() {
  local name="$1"
  local d="$TMPROOT/$name"
  mkdir -p "$d/harness" "$d/state"
  cp "$ROOT/harness/backlog_advance.sh" "$d/harness/backlog_advance.sh"
  chmod +x "$d/harness/backlog_advance.sh"
  printf '%s\n' "$d"
}

run_backlog() {
  local d="$1"
  shift
  ROOT="$d" "$d/harness/backlog_advance.sh" "$@"
}

t9_advance_order() {
  local d
  d="$(mkcase t9)"
  printf 'S1\tTODO\t0\t0\nS2\tTODO\t0\t0\n' > "$d/state/backlog.tsv"
  run_backlog "$d" >"$d/out.txt"
  grep -q $'S1\tDOING\t0\t0' "$d/state/backlog.tsv" || fail 'S1 not promoted'
  pass 'backlog advances first TODO'
}

t10_expiry() {
  local d
  d="$(mkcase t10)"
  printf 'S1\tDOING\t0\t10\nS2\tTODO\t0\t0\n' > "$d/state/backlog.tsv"
  BACKLOG_NOW=20 run_backlog "$d" >"$d/out.txt"
  grep -q $'S1\tEXPIRED\t0\t10' "$d/state/backlog.tsv" || fail 'expired item not marked'
  grep -q $'S2\tDOING\t0\t0' "$d/state/backlog.tsv" || fail 'next item not promoted'
  pass 'backlog expires stale item and advances'
}

t11_exhaustion() {
  local d
  d="$(mkcase t11)"
  printf 'S1\tDONE\t0\t0\n' > "$d/state/backlog.tsv"
  run_backlog "$d" >"$d/out.txt"
  test -f "$d/state/DONE" || fail 'DONE marker missing'
  pass 'backlog writes DONE when exhausted'
}

t12_lock() {
  local d now
  d="$(mkcase t12)"
  now="$(date +%s)"
  mkdir "$d/state/backlog.lock"
  printf '%s\n' "$now" > "$d/state/backlog.lock/epoch"
  if run_backlog "$d" >"$d/out.txt" 2>&1; then
    cat "$d/out.txt"
    fail 'fresh lock did not block'
  fi
  grep -q 'fresh lock exists' "$d/out.txt" || fail 'lock failure message missing'
  pass 'backlog rejects concurrent lock'
}

t13_survival_yield() {
  local d before after
  d="$(mkcase t13)"
  printf 'DONE\n' > "$d/state/DONE"
  printf 'S1\tDONE\t0\t0\n' > "$d/state/backlog.tsv"
  before="$(shasum "$d/state/backlog.tsv" | awk '{print $1}')"
  run_backlog "$d" >"$d/out.txt"
  after="$(shasum "$d/state/backlog.tsv" | awk '{print $1}')"
  test "$before" = "$after" || fail 'DONE yield mutated backlog'
  pass 'backlog yields when DONE exists'
}

t14_failed_retry() {
  local d
  d="$(mkcase t14)"
  printf 'S1\tDOING\t0\t0\n' > "$d/state/backlog.tsv"
  if VERIFY_CMD=false run_backlog "$d" >"$d/out.txt" 2>&1; then
    fail 'failed verify did not fail backlog step'
  fi
  grep -q $'S1\tDOING\t1\t0' "$d/state/backlog.tsv" || fail 'attempt count not incremented'
  pass 'backlog retries failed item'
}

t15_stale_cursor() {
  local d
  d="$(mkcase t15)"
  printf 'stale\n' > "$d/state/cursor"
  printf 'S1\tTODO\t0\t0\n' > "$d/state/backlog.tsv"
  run_backlog "$d" >"$d/out.txt"
  grep -qx '1' "$d/state/cursor" || fail 'stale cursor not reset to 1'
  pass 'backlog resets stale cursor'
}

t16_numeric_cursor() {
  local d
  d="$(mkcase t16)"
  printf '4\n' > "$d/state/cursor"
  printf 'S1\tTODO\t0\t0\n' > "$d/state/backlog.tsv"
  run_backlog "$d" >"$d/out.txt"
  grep -qx '5' "$d/state/cursor" || fail 'numeric cursor not incremented'
  pass 'backlog increments numeric cursor'
}

t9_advance_order
t10_expiry
t11_exhaustion
t12_lock
t13_survival_yield
t14_failed_retry
t15_stale_cursor
t16_numeric_cursor

test "$COUNT" -eq 8 || fail "expected 8 backlog smokes, got $COUNT"
printf 'BACKLOG SMOKE 8 GREEN\n'
