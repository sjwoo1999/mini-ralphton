#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMPROOT="$(mktemp -d "${TMPDIR:-/tmp}/codex-ralph-verify.XXXXXX")"
COUNT=0

cleanup() { rm -rf "$TMPROOT"; }
trap cleanup EXIT

pass() { COUNT=$((COUNT + 1)); printf '[T%s] %s\n' "$COUNT" "$1"; }
fail() { printf '[verify-smoke] RED: %s\n' "$1" >&2; exit 1; }

mkcase() {
  local name="$1" ids="${2:-S1}"
  local d="$TMPROOT/$name"
  mkdir -p "$d/adapter/specs" "$d/app" "$d/harness"
  cp "$ROOT/harness/verify.sh" "$d/harness/verify.sh"
  chmod +x "$d/harness/verify.sh"
  : > "$d/adapter/protected.txt"
  local id
  for id in $ids; do
    printf -- '- [%s] fixture item\n' "$id" >> "$d/adapter/specs/SPEC-B-gull-runner.md"
  done
  printf '%s\n' "$d"
}

write_adapter() {
  local d="$1"
  local body="$2"
  cat > "$d/app/verify_adapter.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
$body
EOF
  chmod +x "$d/app/verify_adapter.sh"
}

expect_fail() {
  local d="$1" pattern="$2"
  if ROOT="$d" VERIFY_SPEC="$d/adapter/specs/SPEC-B-gull-runner.md" bash "$d/harness/verify.sh" >"$d/out.txt" 2>&1; then
    cat "$d/out.txt"
    fail "expected failure: $pattern"
  fi
  grep -q "$pattern" "$d/out.txt" || { cat "$d/out.txt"; fail "missing failure pattern: $pattern"; }
}

expect_pass() {
  local d="$1"
  ROOT="$d" VERIFY_SPEC="$d/adapter/specs/SPEC-B-gull-runner.md" bash "$d/harness/verify.sh" >"$d/out.txt" 2>&1
  grep -q 'VERIFY GREEN' "$d/out.txt" || { cat "$d/out.txt"; fail 'missing VERIFY GREEN'; }
}

t1_green_path() {
  local d
  d="$(mkcase t1 'S1 S2')"
  write_adapter "$d" 'printf "[green] S1\n[green] S2\n"'
  expect_pass "$d"
  pass 'verify green path'
}

t2_completeness() {
  local d
  d="$(mkcase t2 'S1 S2')"
  write_adapter "$d" 'printf "[green] S1\n"'
  expect_fail "$d" 'missing required S-IDs'
  pass 'verify rejects incomplete green set'
}

t3_reproducibility() {
  local d
  d="$(mkcase t3 'S1')"
  write_adapter "$d" 'if test "${VERIFY_REPRO_RUN:-0}" = 1; then :; else printf "[green] S1\n"; fi'
  expect_fail "$d" 'not reproducible'
  pass 'verify rejects non-reproducible green ids'
}

t4_tamper() {
  local d
  d="$(mkcase t4 'S1')"
  write_adapter "$d" 'printf "[green] S1\n"'
  printf 'adapter/specs/SPEC-B-gull-runner.md\n' > "$d/adapter/protected.txt"
  git -C "$d" init -q
  git -C "$d" add .
  git -C "$d" -c user.name=x -c user.email=x@example.com commit -qm init
  printf -- '- [S2] tamper\n' >> "$d/adapter/specs/SPEC-B-gull-runner.md"
  expect_fail "$d" 'protected path modified'
  pass 'verify rejects protected file mutation'
}

t5_opt_out() {
  local d
  d="$(mkcase t5 'S1')"
  write_adapter "$d" 'if test "${VERIFY_REPRO_RUN:-0}" = 1; then :; else printf "[green] S1\n"; fi'
  printf 'reproducibility=off\n' > "$d/adapter/baseline.reproducibility"
  expect_pass "$d"
  pass 'verify honors reproducibility opt-out'
}

t6_test_gate() {
  local d
  d="$(mkcase t6 'S1')"
  expect_fail "$d" 'no adapter ladder'
  pass 'verify fails when no test gate exists'
}

t7_empty_protected() {
  local d
  d="$(mkcase t7 'S1')"
  write_adapter "$d" 'printf "[green] S1\n"'
  : > "$d/adapter/protected.txt"
  expect_pass "$d"
  pass 'verify allows empty protected set'
}

t8_dev_non_destructive() {
  local d before after
  d="$(mkcase t8 'S1')"
  printf 'keep me\n' > "$d/app/dev.txt"
  before="$(shasum "$d/app/dev.txt" | awk '{print $1}')"
  write_adapter "$d" 'printf "[green] S1\n"'
  expect_pass "$d"
  after="$(shasum "$d/app/dev.txt" | awk '{print $1}')"
  test "$before" = "$after" || fail 'verify modified app/dev.txt'
  pass 'verify does not mutate dev file'
}

t1_green_path
t2_completeness
t3_reproducibility
t4_tamper
t5_opt_out
t6_test_gate
t7_empty_protected
t8_dev_non_destructive

test "$COUNT" -eq 8 || fail "expected 8 verify smokes, got $COUNT"
printf 'VERIFY SMOKE 8 GREEN\n'
