#!/bin/bash
# 백로그 전진기 — cron(워치독) 레이어의 일감 공급 (설계: 6/7 5-에이전트 감사 + cron 재요청 구상)
# 원칙: 완주 기준은 신성(각 항목 런은 진짜 DONE으로 끝남). 큐 전진은 런 "밖"에서 — 다음 항목을 SPEC으로
#       스왑·커밋하고 start_run을 재호출한다(fresh context, Huntley 원조 패턴). 큐 소진 시 DONE이 그대로 남음 = 진짜 완주.
# 호출자: watchdog.sh (DONE 감지 시, nohup 분리). 사람이 직접 호출해도 무해(조건 안 맞으면 그냥 종료).
# 상태: state/.backlog-cursor = 현재 활성 항목 번호(1부터). 새 캠페인 시작 시 사람이 rm (CONTRACT §9).
set -uo pipefail
ROOT="${MR_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"; ST="$ROOT/state"
BL="$ROOT/adapter/BACKLOG.md"

# 전진 조건: DONE 존재 + 백로그 존재 + 예산 잔여
[ -f "$ST/DONE" ] || exit 0
[ -f "$BL" ] || exit 0
[ -f "$ST/.budget-anchor" ] || exit 0
NOW=$(date +%s)
DL=$(python3 -c "import json;print(int(json.load(open('$ST/.budget-anchor'))['deadline_epoch']))" 2>/dev/null || echo 0)
[ "$NOW" -lt "$DL" ] || exit 0   # 예산 소진 → 전진 금지 (만료≠일감추가)

# 이중 전진 방지 (워치독 180초 틱 × 전진 소요 수십초 레이스): mkdir 원자 락
LOCK="$ST/.advance-lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  # 묵은 락(>10분)은 죽은 전진의 잔재 — 회수
  LA=$(stat -f %m "$LOCK" 2>/dev/null || echo 0)
  [ $((NOW - LA)) -gt 600 ] && rmdir "$LOCK" 2>/dev/null || exit 0
  mkdir "$LOCK" 2>/dev/null || exit 0
fi
trap 'rmdir "$LOCK" 2>/dev/null' EXIT

CUR=$(cat "$ST/.backlog-cursor" 2>/dev/null || echo 1)   # 1 = 사람이 점화 전 활성화한 첫 항목
NEXT=$((CUR + 1))
ITEM=$(grep -E '^- ' "$BL" | sed -n "${NEXT}p" | awk '{print $2}')
# 경로 관용 (드릴 #1 발견): $ROOT 기준 → 없으면 adapter/ 접두 시도 (사람이 specs/x.md로 적는 자연 표기 수용)
[ -n "$ITEM" ] && [ ! -f "$ROOT/$ITEM" ] && [ -f "$ROOT/adapter/$ITEM" ] && ITEM="adapter/$ITEM"
if [ -z "$ITEM" ] || [ ! -f "$ROOT/$ITEM" ]; then
  echo "$(date '+%H:%M:%S') [backlog] 큐 소진 (${CUR}개 완주) — DONE 유지" >> "$ST/run.log"
  exit 0   # 진짜 완주 — DONE 그대로
fi

cp "$ROOT/$ITEM" "$ROOT/adapter/SPEC.md"
(cd "$ROOT" && git add adapter/SPEC.md && git commit -qm "[backlog] advance #${NEXT}: ${ITEM}") || true  # 답안지 변경은 커밋 의무(런모드 탬퍼 오인 방지)
echo "$NEXT" > "$ST/.backlog-cursor"
REM=$(( (DL - NOW) / 60 )); [ "$REM" -lt 1 ] && REM=1
echo "$(date '+%H:%M:%S') [backlog] #${NEXT} ${ITEM} 점화 (잔여 ${REM}분)" >> "$ST/run.log"
# start_run 재호출: anchor 미만료라 시계 유지, SPEC diff가 부트 프롬프트에 자동 주입(v2-2 재사용).
# MR_KEEP_PLIST=1: 이미 로드된 자기(워치독) launchd 잡을 unload하면 이 스크립트가 도중 죽음 — plist 재로드 생략.
MR_KEEP_PLIST=1 bash "$ROOT/harness/start_run.sh" "$REM" >> "$ST/run.log" 2>&1
