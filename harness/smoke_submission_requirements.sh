#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/codex-ralph-submit.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/repo"
git -C "$TMP/repo" init -q
if bash "$ROOT/harness/submission_requirements.sh" "$TMP/repo" >"$TMP/out.txt" 2>&1; then
  cat "$TMP/out.txt"
  exit 1
fi
grep -q 'GitHub URL required' "$TMP/out.txt"

git -C "$TMP/repo" remote add origin https://github.com/example/project.git
bash "$ROOT/harness/submission_requirements.sh" "$TMP/repo" >"$TMP/out.txt"
grep -q '\[ok\] GitHub URL present' "$TMP/out.txt"
printf 'SUBMISSION REQUIREMENTS SMOKE GREEN\n'
