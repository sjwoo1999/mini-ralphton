#!/bin/bash
# harness/test_verify_smoke.sh — verify.sh 실행 스모크 (#18: 판정기 자체가 실행 테스트 0줄이던 사각)
# 가짜 ladder 카트리지를 주입해 "진짜" verify.sh를 tmp git repo에서 실행한다.
# T3 = ④-0 재현성 검사의 음성 대조군(#17), T4 = 탬퍼 복원 + git clean 일반화(#19),
# T6/T7/T8 = 10-에이전트 감사(#21)에서 생존한 뮤턴트(테스트 게이트·빈 보호집합·dev모드) 사살용.
set -u
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0; FAIL=0
check(){ if [ "$2" -eq 0 ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "  ✗ $1"; fi }

mkrepo(){  # $1 = repo dir — 최소 카트리지 + 이 repo의 진짜 verify.sh 복사 + git 커밋
  local R="$1"
  mkdir -p "$R/harness" "$R/adapter" "$R/app/protected" "$R/state"
  cp "$SRC/verify.sh" "$R/harness/verify.sh"
  echo "golden" > "$R/app/protected/answer.txt"
  printf 'app/protected\n' > "$R/adapter/protected.txt"
  printf -- '- [S1] one\n- [S2] two\n' > "$R/adapter/SPEC.md"
  echo '{"reproducibility": true}' > "$R/adapter/baseline.json"
  cat > "$R/adapter/ladder.sh" <<'EOF'
ladder_typecheck(){ :; }
ladder_test(){ return 0; }
ladder_build(){ :; }
ladder_gaming(){ :; }
ladder_green(){ printf '{"green_ids":["S1","S2"]}' > "$ST/verify-report.json"; }
EOF
  (cd "$R" && git init -q && git add -A && git -c user.email=t@t -c user.name=t commit -qm init) >/dev/null
}

# green을 S1만 내는 ladder (T2용 — sed 대신 전체 재작성: BSD/GNU 이식성)
s1_only_green(){
  cat > "$1/adapter/ladder.sh" <<'EOF'
ladder_typecheck(){ :; }
ladder_test(){ return 0; }
ladder_build(){ :; }
ladder_gaming(){ :; }
ladder_green(){ printf '{"green_ids":["S1"]}' > "$ST/verify-report.json"; }
EOF
}

# 비결정 stub: 1차 호출 S1,S2 / 2차 호출 S1 — ④-0이 잡아야 하는 바로 그 결함
nondet_green(){
  cat > "$1/adapter/ladder.sh" <<'EOF'
ladder_typecheck(){ :; }
ladder_test(){ return 0; }
ladder_build(){ :; }
ladder_gaming(){ :; }
ladder_green(){
  if [ -f "$ST/.smoke-call" ]; then printf '{"green_ids":["S1"]}' > "$ST/verify-report.json"
  else touch "$ST/.smoke-call"; printf '{"green_ids":["S1","S2"]}' > "$ST/verify-report.json"; fi
}
EOF
}

# 테스트가 실패하는 ladder (T6용 — VT!=0 게이트)
failing_test(){
  cat > "$1/adapter/ladder.sh" <<'EOF'
ladder_typecheck(){ :; }
ladder_test(){ return 1; }
ladder_build(){ :; }
ladder_gaming(){ :; }
ladder_green(){ printf '{"green_ids":[]}' > "$ST/verify-report.json"; }
EOF
}

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT

# T1 — 정상 GREEN 경로
mkrepo "$T/t1"
OUT=$(cd "$T/t1" && bash harness/verify.sh 2>&1); RC=$?
[ "$RC" -eq 0 ] && echo "$OUT" | grep -q "VERIFY GREEN"; check "T1 GREEN 경로 (rc=$RC)" $?

# T2 — 완성성 검사: green이 SPEC을 못 덮으면 fail
mkrepo "$T/t2"; s1_only_green "$T/t2"
OUT=$(cd "$T/t2" && bash harness/verify.sh 2>&1); RC=$?
[ "$RC" -ne 0 ] && echo "$OUT" | grep -q "S2 미충족"; check "T2 완성성 fail (rc=$RC)" $?

# T3 — ④-0 재현성 음성 대조군: 비결정 green이면 반드시 fail해야 (#17)
mkrepo "$T/t3"; nondet_green "$T/t3"
OUT=$(cd "$T/t3" && bash harness/verify.sh 2>&1); RC=$?
[ "$RC" -ne 0 ] && echo "$OUT" | grep -q "재현 불가"; check "T3 재현성 검사 발화 (rc=$RC)" $?

# T4 — 런 모드 탬퍼: 수정 복원 + untracked 청소 (git clean 일반화 #19)
mkrepo "$T/t4"
echo '{}' > "$T/t4/state/.budget-anchor"
echo "hacked" > "$T/t4/app/protected/answer.txt"
echo "evil"   > "$T/t4/app/protected/evil.txt"
OUT=$(cd "$T/t4" && bash harness/verify.sh 2>&1); RC=$?
[ "$RC" -ne 0 ] && echo "$OUT" | grep -q "ANSWER-KEY TAMPERED" \
  && [ "$(cat "$T/t4/app/protected/answer.txt")" = "golden" ] \
  && [ ! -f "$T/t4/app/protected/evil.txt" ]
check "T4 탬퍼 복원+untracked 청소 (rc=$RC)" $?

# T5 — reproducibility=false opt-out: 비결정 stub여도 2차 생략 → GREEN
mkrepo "$T/t5"; nondet_green "$T/t5"
echo '{"reproducibility": false}' > "$T/t5/adapter/baseline.json"
OUT=$(cd "$T/t5" && bash harness/verify.sh 2>&1); RC=$?
[ "$RC" -eq 0 ] && echo "$OUT" | grep -q "VERIFY GREEN"; check "T5 repro opt-out (rc=$RC)" $?

# T6 — 테스트 실패 게이트: ladder_test rc!=0 이면 fail "test" (감사#21 생존 뮤턴트 F 사살)
mkrepo "$T/t6"; failing_test "$T/t6"
OUT=$(cd "$T/t6" && bash harness/verify.sh 2>&1); RC=$?
[ "$RC" -ne 0 ] && echo "$OUT" | grep -q "VERIFY FAIL: test"; check "T6 테스트 게이트 (rc=$RC)" $?

# T7 — 빈 protected.txt(주석뿐) = 격리 무력화 → fail (감사#21 생존 뮤턴트 E 사살)
mkrepo "$T/t7"
printf '# 주석뿐\n' > "$T/t7/adapter/protected.txt"
OUT=$(cd "$T/t7" && bash harness/verify.sh 2>&1); RC=$?
[ "$RC" -ne 0 ] && echo "$OUT" | grep -q "protected.txt 비어 있음"; check "T7 빈 보호집합 fail (rc=$RC)" $?

# T8 — dev 모드(anchor 없음) 미커밋 답안지: 파괴 없이 거부 (학살 사건 #3 방어선)
mkrepo "$T/t8"
echo "wip-edit" > "$T/t8/app/protected/answer.txt"
OUT=$(cd "$T/t8" && bash harness/verify.sh 2>&1); RC=$?
[ "$RC" -ne 0 ] && echo "$OUT" | grep -q "uncommitted answer-key" \
  && [ "$(cat "$T/t8/app/protected/answer.txt")" = "wip-edit" ]   # 파괴 금지 — 복원 안 했어야
check "T8 dev모드 비파괴 거부 (rc=$RC)" $?

TOTAL=$((PASS+FAIL))
echo "$TOTAL smoke: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
