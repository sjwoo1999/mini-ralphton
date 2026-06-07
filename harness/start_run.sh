#!/bin/bash
# 사용: bash harness/start_run.sh [분, 기본 150]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; ST="$ROOT/state"; MIN="${1:-150}"
LABEL="com.woo.$(basename "$ROOT")"   # v2-1: repo명 기반 라벨 (다중 호기 충돌 방지)
# PATH 못박기: claude(~/.local/bin)·node(fnm aliases/default) — 셸 무관 동작 (감사 A/B/G)
export PATH="$HOME/.local/bin:$HOME/.local/share/fnm/aliases/default/bin:$PATH"
mkdir -p "$ST" ~/Library/LaunchAgents
# 이중 점화 가드 (실패 4): 살아있는 런의 상태를 밀어버리고 2호기를 띄우는 사고 방지
OLD_PID=$(cat "$ST/claude.pid" 2>/dev/null || echo "")
if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
  echo "✗ 이미 런이 진행 중 (pid $OLD_PID). 중단하려면: bash harness/stop_run.sh"; exit 1
fi
command -v claude > "$ST/claude.path"   # 워치독이 쓸 절대경로 박제 (launchd PATH 불신)
rm -f "$ST/DONE" "$ST/BUDGET_EXHAUSTED" "$ST/STUCK_ON_COMPLETION" "$ST/MANUAL_STOP" "$ST/state.json" "$ST/.strike" "$ST/.restarts" "$ROOT/DIAGNOSIS.md" \
      "$ST/claude.pid" "$ST/verify-report.json" "$ST/.report1.json"   # 점화 위생(#20): stale PID 거짓 "진행 중" + 직전 런 green 잔재 방지 (pid 가드는 위에서 이미 검사함)
_TS=$(date +%m%d-%H%M%S)   # 로테이트 세대 보존(#21): 리허설→본런 연속 점화에도 직전 증거가 안 덮임 (.prev 1세대의 함정)
for L in run.log session.log watchdog.log; do [ -s "$ST/$L" ] && mv "$ST/$L" "$ST/$L.$_TS.prev" || true; done   # 옛 GREEN 줄 오독 방지(#20)
ls -t "$ST"/*.prev 2>/dev/null | tail -n +10 | xargs rm -f 2>/dev/null || true   # 10세대 초과분만 정리
NOW=$(date +%s)
if [ -f "$ST/.budget-anchor" ]; then
  DL=$(python3 -c "import json;print(int(json.load(open('$ST/.budget-anchor'))['deadline_epoch']))" 2>/dev/null || echo 0)
  if [ "$NOW" -gt "$DL" ]; then
    # 만료 anchor = 소진된 직전 예산. 수동 rm 요구는 보강→재점화(일상 동선)의 마찰이라 자동 리셋 (#22).
    # 원래 목적(만료 잔재로 본 런 즉사 방지 #10)은 fresh anchor 생성이 더 확실히 달성.
    echo "↻ 만료 anchor 자동 리셋 (직전 예산 소진) — 새 예산 ${MIN}분"
    rm -f "$ST/.budget-anchor"
  fi
fi
if [ ! -f "$ST/.budget-anchor" ]; then  # 1회 생성 — 미만료 재실행은 시계 유지 (재실행이 시계 리셋 못 함)
  FLOOR=720; [ "$MIN" -lt 30 ] && FLOOR=120   # 장난감 예산(<30분)은 마무리 하한 2분 (#10)
  printf '{"started_at_epoch": %s, "deadline_epoch": %s, "turn_cap": 40, "finish_floor_sec": %s}\n' "$NOW" "$((NOW + MIN*60))" "$FLOOR" > "$ST/.budget-anchor"
fi
touch "$ST/heartbeat" "$ST/run.log"
# TCC 사전 경고 (실패 노트 #8): launchd는 Desktop/Documents/Downloads를 못 읽는다
case "$ROOT" in
  "$HOME/Desktop/"*|"$HOME/Documents/"*|"$HOME/Downloads/"*)
    echo "⚠ repo가 TCC 보호 폴더 아래 — launchd 워치독(Tier 3)이 차단될 수 있음. 아래 박동 검사로 확정." ;;
esac
if [ "${MR_KEEP_PLIST:-0}" = "1" ]; then
  # 백로그 전진 경로(CONTRACT §9): 호출자가 워치독 launchd 잡 자신 — 자기 잡을 unload하면 이 스크립트가 도중 죽는다.
  echo "↻ plist 재로드 생략 (백로그 전진 — 기존 워치독 잡 유지)"
else
  # plist 생성 (v2-1: 템플릿 치환 — 절대경로 하드코딩 제거)
  sed -e "s|{{ROOT}}|$ROOT|g" -e "s|{{LABEL}}|$LABEL|g" -e "s|{{HOME}}|$HOME|g" \
    "$ROOT/harness/templates/launchd.plist.tmpl" > ~/Library/LaunchAgents/"$LABEL".plist
  launchctl unload ~/Library/LaunchAgents/"$LABEL".plist 2>/dev/null || true
  launchctl load ~/Library/LaunchAgents/"$LABEL".plist
  # 감시자 생존 증거 검사 (실패 노트 #8): kickstart로 1회 강제 실행 → 박동 마커 신선도 확인
  rm -f "$ST/.watchdog-alive"
  launchctl kickstart "gui/$(id -u)/$LABEL" 2>/dev/null || true
  sleep 3
  if [ -f "$ST/.watchdog-alive" ]; then
    echo "✓ Tier 3 워치독 생존 확인 (.watchdog-alive 박동 수신)"
  else
    echo "✗ Tier 3 워치독 사망 — launchd가 스크립트를 실행하지 못함 (TCC 추정. state/watchdog.log 확인)."
    echo "  런은 Tier 1+2 없이… 아니, Tier 1(Stop훅 루프)만으로 계속됨. 죽으면 자동 소생 없음 — 알고 시작할 것."
  fi
fi
# v2-2 재점화 계약: SPEC이 직전 런 이후 보강됐으면 diff를 부트 프롬프트에 주입
BOOT_PROMPT="Read adapter/PROMPT.md (follow §build) and PROGRESS.md, then continue the run. Never declare completion — the harness stops you when verify passes."
if [ -f "$ST/.spec-snapshot.md" ] && ! cmp -s "$ST/.spec-snapshot.md" "$ROOT/adapter/SPEC.md"; then
  SPEC_DIFF=$(diff -u "$ST/.spec-snapshot.md" "$ROOT/adapter/SPEC.md" 2>/dev/null | tail -n +3 | head -40 || true)
  BOOT_PROMPT="SPEC changed since the last run — the diff below is the human's answer to the previous blockage. Read it first, update PROGRESS for affected items, then proceed per adapter/PROMPT.md (§build). Never declare completion.

--- SPEC diff ---
$SPEC_DIFF"
  echo "↻ 재점화 감지: SPEC diff를 부트 프롬프트에 주입"
fi
cp "$ROOT/adapter/SPEC.md" "$ST/.spec-snapshot.md"
cd "$ROOT"
nohup claude -p "$BOOT_PROMPT" \
  --permission-mode acceptEdits >> "$ST/session.log" 2>&1 &
echo $! > "$ST/claude.pid"
echo "▶ run 시작 (pid $(cat "$ST/claude.pid"), 예산 ${MIN}분). 관전: tail -f state/run.log (+에러는 state/session.log)"
