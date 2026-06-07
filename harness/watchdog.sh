#!/bin/bash
# 마커 선검사 → 죽은채만료 → liveness → productive-timeout → 2-strike → 재시동(최대 3회)
ROOT="${MR_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"; ST="$ROOT/state"   # v2-1: 절대경로 하드코딩 제거
# 감시자도 박동을 남긴다 (실패 노트 #8): 이 마커가 곧 "launchd가 나를 실행할 수 있다"는 증거.
# TCC가 막으면 스크립트 자체가 안 돌아 마커가 안 생김 → start_run이 점화 직후 신선도 검사.
mkdir -p "$ST" 2>/dev/null; date +%s > "$ST/.watchdog-alive" 2>/dev/null
[ -f "$ST/.budget-anchor" ] || exit 0
# 백로그 전진(CONTRACT §9): DONE = "항목" 완주. 큐·예산이 남았으면 전진기가 다음 항목을 점화한다.
# 조건 검사·락·커밋은 전진기 몫 — 여기선 분리 호출만 (AbandonProcessGroup=true라 이 틱이 끝나도 생존).
if [ -f "$ST/DONE" ] && [ -f "$ROOT/adapter/BACKLOG.md" ]; then
  nohup bash "$ROOT/harness/backlog_advance.sh" >> "$ST/watchdog.log" 2>&1 &
fi
for m in DONE BUDGET_EXHAUSTED STUCK_ON_COMPLETION MANUAL_STOP; do [ -f "$ST/$m" ] && exit 0; done
NOW=$(date +%s)
DEADLINE=$(python3 -c "import json;print(int(json.load(open('$ST/.budget-anchor'))['deadline_epoch']))" 2>/dev/null) || exit 0
if [ "$NOW" -gt "$DEADLINE" ]; then echo "$NOW" > "$ST/BUDGET_EXHAUSTED"; exit 0; fi  # 만료≠정체: 재시동 금지
PID=$(cat "$ST/claude.pid" 2>/dev/null || echo "")
ALIVE=0; [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null && ALIVE=1
HB=$(stat -f %m "$ST/heartbeat" 2>/dev/null || echo 0)
if [ "$ALIVE" -eq 1 ] && [ $((NOW - HB)) -lt 600 ]; then rm -f "$ST/.strike"; exit 0; fi
# productive-timeout: 최근 10분 작업트리 변화가 있으면 진행으로 간주
if [ "$ALIVE" -eq 1 ] && [ -n "$(find "$ROOT/app" "$ROOT/PROGRESS.md" -mmin -10 2>/dev/null | head -1)" ]; then  # 2호 일반화: 워크로드 트리 전체
  rm -f "$ST/.strike"; exit 0
fi
if [ ! -f "$ST/.strike" ]; then touch "$ST/.strike"; exit 0; fi  # 2-strike
rm -f "$ST/.strike"
N=$(cat "$ST/.restarts" 2>/dev/null || echo 0)
if [ "$N" -ge 3 ]; then echo "$NOW restarts-exhausted" > "$ST/STUCK_ON_COMPLETION"; exit 0; fi
echo $((N + 1)) > "$ST/.restarts"
[ -n "$PID" ] && kill -9 "$PID" 2>/dev/null
CLAUDE_BIN=$(cat "$ST/claude.path" 2>/dev/null || echo claude)   # start_run이 박제한 절대경로
cd "$ROOT"
nohup "$CLAUDE_BIN" -p "Read adapter/PROMPT.md and PROGRESS.md, continue the run from disk state. Never declare completion." \
  --permission-mode acceptEdits >> "$ST/session.log" 2>&1 &
echo $! > "$ST/claude.pid"
echo "$(date '+%H:%M:%S') [watchdog] restart #$((N + 1))" >> "$ST/run.log"
