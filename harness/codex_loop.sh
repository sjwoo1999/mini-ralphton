#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
LOG="$ROOT/state/run.log"
MAX_ROUNDS="${MAX_ROUNDS:-20}"

mkdir -p "$ROOT/state"
round=0
while ! bash "$ROOT/harness/verify.sh" >>"$LOG" 2>&1; do
  round=$((round + 1))
  test "$round" -le "$MAX_ROUNDS" || { printf '[loop] max rounds reached\n' | tee -a "$LOG"; exit 1; }
  bash "$ROOT/harness/backlog_advance.sh" >>"$LOG" 2>&1 || true
  if command -v codex >/dev/null 2>&1; then
    codex exec --sandbox workspace-write resume --last "bash harness/verify.sh failed. Read the gate output in state/run.log, fix exactly one missing S-ID vertical slice, then stop after <=3 lines." </dev/null >>"$LOG" 2>&1
  else
    printf '[loop] codex CLI not found; manual pass required\n' | tee -a "$LOG"
    exit 1
  fi
done
drain=0
while ! test -f "$ROOT/state/DONE"; do
  drain=$((drain + 1))
  test "$drain" -le 20 || { printf '[loop] backlog drain cap reached\n' | tee -a "$LOG"; exit 1; }
  bash "$ROOT/harness/backlog_advance.sh" >>"$LOG" 2>&1
done
printf '[loop] VERIFY GREEN + QUEUE DONE\n' | tee -a "$LOG"
