#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
STATE="$ROOT/state"
BACKLOG="$STATE/backlog.tsv"
LOCK="$STATE/backlog.lock"
DONE="$STATE/DONE"
VERIFY_CMD="${VERIFY_CMD:-bash "$ROOT/harness/verify.sh"}"
NOW="${BACKLOG_NOW:-$(date +%s)}"
LOCK_TTL="${BACKLOG_LOCK_TTL:-60}"

msg() { printf '[backlog] %s\n' "$1"; }
die() { printf '[backlog] RED: %s\n' "$1" >&2; exit 1; }

acquire_lock() {
  mkdir -p "$STATE"
  if mkdir "$LOCK" 2>/dev/null; then
    printf '%s\n' "$NOW" > "$LOCK/epoch"
    trap 'rm -rf "$LOCK"' EXIT
    return 0
  fi
  local epoch age
  epoch="$(cat "$LOCK/epoch" 2>/dev/null || printf '0')"
  case "$epoch" in *[!0-9]*|'') epoch=0 ;; esac
  age=$((NOW - epoch))
  if test "$age" -gt "$LOCK_TTL"; then
    rm -rf "$LOCK"
    mkdir "$LOCK"
    printf '%s\n' "$NOW" > "$LOCK/epoch"
    trap 'rm -rf "$LOCK"' EXIT
    msg 'stale lock stolen'
    return 0
  fi
  die 'fresh lock exists'
}

normalize_cursor() {
  local cursor_file="$STATE/cursor"
  local cursor
  cursor="$(cat "$cursor_file" 2>/dev/null || printf '0')"
  case "$cursor" in *[!0-9]*|'') cursor=0; msg 'stale cursor reset' ;; esac
  cursor=$((cursor + 1))
  printf '%s\n' "$cursor" > "$cursor_file"
}

seed_backlog() {
  test -f "$BACKLOG" && return 0
  mkdir -p "$STATE"
  printf 'S1\tTODO\t0\t0\nS2\tTODO\t0\t0\n' > "$BACKLOG"
}

rewrite_status() {
  local id="$1" status="$2" attempts="$3" expires="$4"
  awk -F '\t' -v OFS='\t' -v id="$id" -v st="$status" -v at="$attempts" -v ex="$expires" '
    $1 == id { $2 = st; $3 = at; $4 = ex }
    { print }
  ' "$BACKLOG" > "$BACKLOG.tmp"
  mv "$BACKLOG.tmp" "$BACKLOG"
}

promote_next() {
  local next
  next="$(awk -F '\t' '$2 == "TODO" { print $1; exit }' "$BACKLOG")"
  if test -n "$next"; then
    rewrite_status "$next" "DOING" "0" "0"
    msg "promoted $next"
    return 0
  fi
  if ! awk -F '\t' '$2 == "TODO" || $2 == "DOING" { found=1 } END { exit found ? 0 : 1 }' "$BACKLOG"; then
    printf 'DONE\n' > "$DONE"
    msg 'queue exhausted'
  fi
}

current_doing() {
  awk -F '\t' '$2 == "DOING" { print $1 "\t" $3 "\t" $4; exit }' "$BACKLOG"
}

main() {
  if test -f "$DONE"; then
    msg 'DONE marker present; yielding'
    exit 0
  fi
  acquire_lock
  normalize_cursor
  seed_backlog

  local row id attempts expires
  row="$(current_doing)"
  if test -z "$row"; then
    promote_next
    exit 0
  fi
  IFS=$'\t' read -r id attempts expires <<EOF
$row
EOF
  case "$attempts" in *[!0-9]*|'') attempts=0 ;; esac
  case "$expires" in *[!0-9]*|'') expires=0 ;; esac

  if test "$expires" -gt 0 && test "$expires" -lt "$NOW"; then
    rewrite_status "$id" "EXPIRED" "$attempts" "$expires"
    msg "expired $id"
    promote_next
    exit 0
  fi

  if $VERIFY_CMD >/tmp/codex-ralph-backlog-verify.out 2>&1; then
    rewrite_status "$id" "DONE" "$attempts" "$expires"
    msg "completed $id"
    promote_next
  else
    attempts=$((attempts + 1))
    rewrite_status "$id" "DOING" "$attempts" "$expires"
    msg "retry $id attempts=$attempts"
    exit 1
  fi
}

main "$@"
