#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
SPEC_FILE="${VERIFY_SPEC:-$ROOT/adapter/specs/SPEC-B-gull-runner.md}"
REPORT="$ROOT/state/verify-report.txt"

log() { printf '[gate] %s\n' "$1"; }
fail() {
  mkdir -p "$ROOT/state"
  printf 'VERIFY RED: %s\n' "$1" | tee "$REPORT" >&2
  exit 1
}

spec_ids() {
  grep -E '^- \[S[0-9]+\]' "$SPEC_FILE" | sed -E 's/^- \[(S[0-9]+)\].*/\1/'
}

run_ladder() {
  if test -x "$ROOT/adapter/ladder.sh"; then
    "$ROOT/adapter/ladder.sh"
    return
  fi
  if test -x "$ROOT/app/verify_adapter.sh"; then
    "$ROOT/app/verify_adapter.sh"
    return
  fi
  fail 'no adapter ladder found'
}

green_ids_once() {
  local output rc
  set +e
  output="$(run_ladder 2>&1)"
  rc=$?
  set -e
  printf '%s\n' "$output" >&2
  test "$rc" -eq 0 || return "$rc"
  printf '%s\n' "$output" | grep -Eo '\[green\][[:space:]]*S[0-9]+' | sed -E 's/.*(S[0-9]+)/\1/' | sort -u || true
}

check_shell_syntax() {
  local f
  while IFS= read -r f; do
    bash -n "$f"
  done < <(find "$ROOT/harness" -maxdepth 1 -type f -name '*.sh' | sort)
  log 'shell syntax ok'
}

check_protected_clean() {
  local list="$ROOT/adapter/protected.txt"
  test -f "$list" || { log 'protected set absent'; return 0; }
  test -s "$list" || { log 'protected set empty'; return 0; }
  git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { log 'protected clean skipped outside git'; return 0; }

  local path
  while IFS= read -r path; do
    test -n "$path" || continue
    case "$path" in \#*) continue ;; esac
    git -C "$ROOT" ls-files --error-unmatch "$path" >/dev/null 2>&1 || fail "protected path is not tracked: $path"
    git -C "$ROOT" diff --quiet -- "$path" || fail "protected path modified: $path"
  done < "$list"
  log 'protected files clean'
}

check_reproducible() {
  local first="$1"
  local baseline="$ROOT/adapter/baseline.reproducibility"
  if test -f "$baseline" && grep -Eq '^(reproducibility|VERIFY_REPRODUCIBILITY)=off$' "$baseline"; then
    log 'reproducibility opt-out'
    return 0
  fi

  local second
  second="$(VERIFY_REPRO_RUN=1 green_ids_once)"
  if test "$first" != "$second"; then
    printf 'first green ids:\n%s\nsecond green ids:\n%s\n' "$first" "$second" >&2
    fail 'green ids are not reproducible'
  fi
  log 'reproducibility ok'
}

check_complete() {
  local expected="$1"
  local actual="$2"
  local id missing=0
  for id in $expected; do
    if ! printf '%s\n' "$actual" | grep -qx "$id"; then
      printf '[missing] %s\n' "$id" >&2
      missing=1
    fi
  done
  test "$missing" -eq 0 || fail 'missing required S-IDs'
  log 'S-ID completeness ok'
}

main() {
  test -f "$SPEC_FILE" || fail "missing SPEC file: $SPEC_FILE"
  mkdir -p "$ROOT/state"

  local expected actual
  expected="$(spec_ids)"
  test -n "$expected" || fail 'SPEC has no live S-IDs'

  check_shell_syntax
  check_protected_clean
  actual="$(green_ids_once)"
  test -n "$actual" || fail 'adapter produced no green S-IDs'
  check_reproducible "$actual"
  check_complete "$expected" "$actual"

  {
    printf 'VERIFY GREEN\n'
    printf 'spec=%s\n' "${SPEC_FILE#"$ROOT"/}"
    printf 'green_ids=%s\n' "$(printf '%s ' $actual)"
  } > "$REPORT"
  cat "$REPORT"
}

main "$@"
