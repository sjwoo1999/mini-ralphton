#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$(pwd)}"

ok() { printf '[ok] %s\n' "$1"; }
warn() { printf '[warn] %s\n' "$1"; }
fail() { printf '[fail] %s\n' "$1"; }

is_github_url() {
  case "$1" in
    https://github.com/*/*|git@github.com:*/*|ssh://git@github.com/*/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

find_readme_github_url() {
  local readme="$ROOT/README.md"
  test -f "$readme" || return 1
  grep -Eo 'https://github\.com/[^[:space:]]+/[^[:space:]]+|git@github\.com:[^[:space:]]+/[^[:space:]]+' "$readme" \
    | sed "s/[),.>\"']*$//" \
    | head -n 1
}

find_github_url() {
  local url
  if test -n "${SUBMISSION_GITHUB_URL:-}"; then
    printf '%s\n' "$SUBMISSION_GITHUB_URL"
    return 0
  fi

  url="$(git -C "$ROOT" config --get remote.origin.url 2>/dev/null || true)"
  if test -n "$url"; then
    printf '%s\n' "$url"
    return 0
  fi

  find_readme_github_url
}

check_github_url() {
  local url
  url="$(find_github_url || true)"
  if test -z "$url"; then
    fail 'GitHub URL required: set remote.origin.url, SUBMISSION_GITHUB_URL, or include a GitHub URL in README.md'
    return 1
  fi
  if ! is_github_url "$url"; then
    fail "GitHub URL required: '$url' is not a github.com repository URL"
    return 1
  fi
  ok "GitHub URL present: $url"
}

check_demo_screenshot() {
  local candidate
  if test -n "${SUBMISSION_DEMO_SCREENSHOT:-}"; then
    candidate="$ROOT/$SUBMISSION_DEMO_SCREENSHOT"
    if test -f "$candidate"; then
      ok "Demo screenshot present: $SUBMISSION_DEMO_SCREENSHOT"
    else
      warn "Demo screenshot optional: SUBMISSION_DEMO_SCREENSHOT points to a missing file: $SUBMISSION_DEMO_SCREENSHOT"
    fi
    return 0
  fi

  candidate="$(
    find "$ROOT" -maxdepth 3 -type f \
      \( -iname 'demo-screenshot.png' -o -iname 'demo-screenshot.jpg' -o -iname 'demo-screenshot.jpeg' -o -iname 'demo-screenshot.webp' -o -iname 'screenshot.png' \) \
      | head -n 1
  )"
  if test -n "$candidate"; then
    ok "Demo screenshot present: ${candidate#"$ROOT"/}"
  else
    warn 'Demo screenshot optional: not found'
  fi
}

check_readme_onepager() {
  local readme="$ROOT/README.md"
  if ! test -f "$readme"; then
    warn 'README.md one-pager optional: not found at project root'
    return 0
  fi

  local lines bytes
  lines="$(wc -l < "$readme" | tr -d ' ')"
  bytes="$(wc -c < "$readme" | tr -d ' ')"
  if test "$lines" -le 120 && test "$bytes" -le 12000; then
    ok "README.md one-pager present: ${lines} lines, ${bytes} bytes"
  else
    warn "README.md one-pager optional: present but long (${lines} lines, ${bytes} bytes)"
  fi
}

check_commit_trail() {
  if ! git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    warn 'Commit trail optional: not a git worktree'
    return 0
  fi

  local count
  count="$(git -C "$ROOT" rev-list --count HEAD 2>/dev/null || printf '0')"
  if test "$count" -ge 2; then
    ok "Commit trail present: $count commits"
  else
    warn "Commit trail optional: only $count commit(s)"
  fi
}

main() {
  check_github_url
  check_demo_screenshot
  check_readme_onepager
  check_commit_trail
}

main "$@"
