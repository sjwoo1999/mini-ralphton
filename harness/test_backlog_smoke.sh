#!/bin/bash
# harness/test_backlog_smoke.sh — backlog_advance.sh 실행 스모크 (#18 3차 재발 봉합, 10-감사 T9~T12 설계 + 안전핀 음성대조군)
# start_run을 PATH가 아닌 "같은 자리 스텁"으로 가로채(advance가 $ROOT/harness/start_run.sh를 절대경로 호출) 실점화 0.
set -u
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0; FAIL=0
check(){ if [ "$2" -eq 0 ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "  ✗ $1"; fi }

mkbl(){  # $1=repo $2=deadline_offset초 — DONE+BACKLOG(2항목)+anchor 최소 캠페인 상태
  local R="$1" OFF="$2"
  mkdir -p "$R/harness" "$R/adapter/specs" "$R/state"
  cp "$SRC/backlog_advance.sh" "$R/harness/"
  cat > "$R/harness/start_run.sh" <<'EOF'
#!/bin/bash
ST="$(cd "$(dirname "$0")/.." && pwd)/state"
echo "START_RUN min=$1 keep=${MR_KEEP_PLIST:-0}" >> "$ST/.smoke-startrun"
[ -f "$ST/.smoke-fail-ignite" ] && exit 1   # T14: 점화 실패 모사
exit 0
EOF
  chmod +x "$R/harness/start_run.sh" "$R/harness/backlog_advance.sh"
  printf -- '- specs/a.md 첫째\n- specs/b.md 둘째\n' > "$R/adapter/BACKLOG.md"
  echo "SPEC-A" > "$R/adapter/specs/a.md"; echo "SPEC-B" > "$R/adapter/specs/b.md"
  cp "$R/adapter/specs/a.md" "$R/adapter/SPEC.md"
  touch "$R/state/DONE"
  printf '{"deadline_epoch": %s}\n' "$(( $(date +%s) + OFF ))" > "$R/state/.budget-anchor"
  (cd "$R" && git init -q && git add -A && git -c user.email=t@t -c user.name=t commit -qm init) >/dev/null 2>&1
}
adv(){ MR_ROOT="$1" bash "$1/harness/backlog_advance.sh"; }

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT

# T9 — 정상 전진: SPEC=B 스왑 + start_run(keep=1) 성공 → cursor=2
mkbl "$T/t9" 3600; adv "$T/t9"
[ "$(cat "$T/t9/adapter/SPEC.md")" = "SPEC-B" ] && [ "$(cat "$T/t9/state/.backlog-cursor" 2>/dev/null)" = "2" ] \
  && grep -q "keep=1" "$T/t9/state/.smoke-startrun"
check "T9 정상 전진 (SPEC스왑·점화·cursor=2)" $?

# T10 — 만료가드 음성대조군: 예산 만료 → 전진 금지 (SPEC 불변·점화 0)
mkbl "$T/t10" -10; adv "$T/t10"
[ "$(cat "$T/t10/adapter/SPEC.md")" = "SPEC-A" ] && [ ! -f "$T/t10/state/.smoke-startrun" ]
check "T10 만료가드 (전진·점화 없음)" $?

# T11 — 소진가드: 마지막 항목 활성(cursor=2) → DONE 유지·점화 0·'큐 소진' 로그
mkbl "$T/t11" 3600; echo "2" > "$T/t11/state/.backlog-cursor"; adv "$T/t11"
[ -f "$T/t11/state/DONE" ] && [ ! -f "$T/t11/state/.smoke-startrun" ] && grep -q "큐 소진" "$T/t11/state/run.log"
check "T11 소진가드 (DONE 보존·완주 로그)" $?

# T12 — 이중전진 락: 신선 락 선점 → 즉시 양보 (SPEC 불변·점화 0)
mkbl "$T/t12" 3600; mkdir "$T/t12/state/.advance-lock"; adv "$T/t12"
[ "$(cat "$T/t12/adapter/SPEC.md")" = "SPEC-A" ] && [ ! -f "$T/t12/state/.smoke-startrun" ]
check "T12 락 양보 (이중전진 차단)" $?

# T13 — claude 생존 양보 (신규 안전핀): 직전 프로세스 살아있으면 전진 안 함
mkbl "$T/t13" 3600; echo "$$" > "$T/t13/state/claude.pid"   # 이 셸 자신 = 확실히 살아있는 PID
adv "$T/t13"
[ "$(cat "$T/t13/adapter/SPEC.md")" = "SPEC-A" ] && [ ! -f "$T/t13/state/.smoke-startrun" ]
check "T13 claude 생존 양보 (스킵 레이스 차단)" $?

# T14 — 점화 실패 시 cursor 유지 (신규 안전핀 음성대조군): 다음 틱 멱등 재시도 가능해야
mkbl "$T/t14" 3600; touch "$T/t14/state/.smoke-fail-ignite"; adv "$T/t14"
[ ! -f "$T/t14/state/.backlog-cursor" ] && grep -q "점화 실패" "$T/t14/state/run.log" \
  && rm -f "$T/t14/state/.smoke-fail-ignite" && adv "$T/t14" \
  && [ "$(cat "$T/t14/state/.backlog-cursor" 2>/dev/null)" = "2" ]   # 재시도가 같은 항목으로 성공
check "T14 점화실패→cursor 유지→재시도 성공" $?

TOTAL=$((PASS+FAIL))
echo "$TOTAL backlog smoke: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
