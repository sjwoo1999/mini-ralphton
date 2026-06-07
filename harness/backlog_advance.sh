#!/bin/bash
# 백로그 전진기 — cron(워치독) 레이어의 일감 공급 (설계: 6/7 5-에이전트 감사 + cron 재요청 구상)
# 원칙: 완주 기준은 신성(각 항목 런은 진짜 DONE으로 끝남). 큐 전진은 런 "밖"에서 — 다음 항목을 SPEC으로
#       스왑·커밋하고 start_run을 재호출한다(fresh context, Huntley 원조 패턴). 큐 소진 시 DONE이 그대로 남음 = 진짜 완주.
# 호출자: watchdog.sh (DONE 감지 시, nohup 분리). 사람이 직접 호출해도 무해(조건 안 맞으면 그냥 종료).
# 상태: state/.backlog-cursor = 현재 활성 항목의 "BACKLOG 원문 토큰"(spec 경로). 새 BACKLOG로 교체되면
#       토큰이 목록에 없어 자동으로 항목1 활성 취급 — 수동 rm 불필요(10-감사 HIGH② 기계 강제). 숫자형(구버전)도 호환.
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
# 직전 claude 생존 시 양보 (감사 HIGH: DONE 기록~프로세스 종료 사이 초 단위 창에서 start_run이 PID가드로 abort → 항목 무음 스킵)
_PID=$(cat "$ST/claude.pid" 2>/dev/null || echo "")
[ -n "$_PID" ] && kill -0 "$_PID" 2>/dev/null && exit 0   # 다음 틱이 재시도

# 이중 전진 방지 (워치독 180초 틱 × 전진 소요 수십초 레이스): mkdir 원자 락
LOCK="$ST/.advance-lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  # 묵은 락(>10분)은 죽은 전진의 잔재 — 회수
  LA=$(stat -f %m "$LOCK" 2>/dev/null || echo 0)
  [ $((NOW - LA)) -gt 600 ] && rmdir "$LOCK" 2>/dev/null || exit 0
  mkdir "$LOCK" 2>/dev/null || exit 0
fi
trap 'rmdir "$LOCK" 2>/dev/null' EXIT

# 위치 계산: cursor 토큰을 BACKLOG 목록에서 찾는다. 미발견(새 백로그/부재/손상) = 항목1 활성 취급 → NEXT=2.
ITEMS=$(grep -E '^- ' "$BL" | awk '{print $2}')
CUR_TOK=$(cat "$ST/.backlog-cursor" 2>/dev/null || echo "")
POS=0
if [ -n "$CUR_TOK" ]; then
  case "$CUR_TOK" in
    *[!0-9]*) i=0; for t in $ITEMS; do i=$((i+1)); [ "$t" = "$CUR_TOK" ] && POS=$i && break; done ;;
    *) POS=$CUR_TOK ;;   # 구버전 숫자형 호환
  esac
fi
[ "$POS" -lt 1 ] && POS=1
NEXT=$((POS + 1))
RAW=$(echo "$ITEMS" | sed -n "${NEXT}p")
ITEM="$RAW"
# 경로 관용 (드릴 #1 발견): $ROOT 기준 → 없으면 adapter/ 접두 시도 (사람이 specs/x.md로 적는 자연 표기 수용)
[ -n "$ITEM" ] && [ ! -f "$ROOT/$ITEM" ] && [ -f "$ROOT/adapter/$ITEM" ] && ITEM="adapter/$ITEM"
if [ -z "$ITEM" ] || [ ! -f "$ROOT/$ITEM" ]; then
  echo "$(date '+%H:%M:%S') [backlog] 큐 소진 (${POS}개 완주) — DONE 유지" >> "$ST/run.log"
  # ⑤캠페인 종료음 (감사: "진짜 끝"만 무음이던 역설) — 항목 DONE(Glass)과 구분되는 소리+메시지
  if [ -z "${MR_VERIFY:-}" ]; then   # 테스트 중 무음 (stop_gate와 같은 관례)
    _INST=$(basename "$ROOT")
    osascript -e "display notification \"${_INST}: 캠페인 완주 (${POS}개 항목)\" with title \"ralphton\" sound name \"Hero\"" >/dev/null 2>&1 || true
    afplay /System/Library/Sounds/Hero.aiff >/dev/null 2>&1 || true
  fi
  exit 0   # 진짜 완주 — DONE 그대로
fi

cp "$ROOT/$ITEM" "$ROOT/adapter/SPEC.md"
(cd "$ROOT" && git add adapter/SPEC.md && git commit -qm "[backlog] advance #${NEXT}: ${ITEM}") >/dev/null 2>&1 || true  # 답안지 변경 커밋 의무. 재시도 no-change 무해(출력도 침묵)
REM=$(( (DL - NOW) / 60 )); [ "$REM" -lt 1 ] && REM=1
echo "$(date '+%H:%M:%S') [backlog] #${NEXT} ${ITEM} 점화 시도 (잔여 ${REM}분)" >> "$ST/run.log"
# start_run 재호출: anchor 미만료라 시계 유지, SPEC diff가 부트 프롬프트에 자동 주입(v2-2 재사용).
# MR_KEEP_PLIST=1: 이미 로드된 자기(워치독) launchd 잡을 unload하면 이 스크립트가 도중 죽음 — plist 재로드 생략.
if MR_KEEP_PLIST=1 bash "$ROOT/harness/start_run.sh" "$REM" >> "$ST/run.log" 2>&1; then
  echo "$RAW" > "$ST/.backlog-cursor"   # 점화 성공 후에만 전진(토큰 기록) — 실패 시 유지 → 다음 틱 멱등 재시도
else
  echo "$(date '+%H:%M:%S') [backlog] #${NEXT} 점화 실패 — cursor 유지, 다음 틱 재시도" >> "$ST/run.log"
fi
