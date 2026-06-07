#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$(pwd)}"
ok() { printf '[ok] %s\n' "$1"; }
warn() { printf '[warn] %s\n' "$1"; }
fail() { printf '[fail] %s\n' "$1"; }

is_github_url() {
  case "$1" in
    https://github.com/*/*|git@github.com:*/*|ssh://git@github.com/*/*) return 0 ;;
    *) return 1 ;;
  esac
}

find_readme_url() {
  test -f "$ROOT/README.md" || return 1
  grep -Eo 'https://github\.com/[^[:space:]]+/[^[:space:]]+|git@github\.com:[^[:space:]]+/[^[:space:]]+' "$ROOT/README.md" \
    | sed "s/[),.>\"']*$//" \
    | head -n 1
}

find_url() {
  if test -n "${SUBMISSION_GITHUB_URL:-}"; then
    printf '%s\n' "$SUBMISSION_GITHUB_URL"
    return 0
  fi
  git -C "$ROOT" config --get remote.origin.url 2>/dev/null || find_readme_url
}

url="$(find_url || true)"
if test -z "$url"; then
  fail 'GitHub URL required'
  exit 1
fi
is_github_url "$url" || { fail "not a GitHub repo URL: $url"; exit 1; }
ok "GitHub URL present: $url"

shot="$(
  find "$ROOT" -maxdepth 3 -type f \
    \( -iname 'demo-screenshot.png' -o -iname 'demo-screenshot.jpg' -o -iname 'demo-screenshot.jpeg' -o -iname 'demo-screenshot.webp' -o -iname 'screenshot.png' \) \
    | head -n 1
)"
if test -n "$shot"; then ok "Demo screenshot present: ${shot#"$ROOT"/}"; else warn 'Demo screenshot optional: not found'; fi

if test -f "$ROOT/README.md"; then
  lines="$(wc -l < "$ROOT/README.md" | tr -d ' ')"
  bytes="$(wc -c < "$ROOT/README.md" | tr -d ' ')"
  if test "$lines" -le 120 && test "$bytes" -le 12000; then ok "README.md one-pager present: ${lines} lines"; else warn "README.md is long: ${lines} lines"; fi
else
  warn 'README.md one-pager optional: not found'
fi

commits="$(git -C "$ROOT" rev-list --count HEAD 2>/dev/null || printf '0')"
if test "$commits" -ge 2; then ok "Commit trail present: $commits commits"; else warn "Commit trail optional: $commits commit(s)"; fi
