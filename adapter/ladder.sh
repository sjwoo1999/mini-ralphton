# adapter/ladder.sh — 워크로드별 판정 사다리 (전용층 카트리지)
# 계약: harness/verify.sh가 source한 뒤 아래 5함수를 순서대로 호출. (정본: harness/ADAPTER-CONTRACT.md)
#   환경 주입: $ROOT $APP $ST, fail() 제공.
#   ladder_typecheck / ladder_build : 실패 시 fail "<이유>" 호출
#   ladder_test                     : 종료코드만 반환 (verify 골격이 판정 — green set 기록 후)
#   ladder_green                    : $ST/verify-report.json 에 {"green_ids":[...]} 기록
#   MR_REVERSE=1 (재현성 2차에서 주입): 이 어댑터(vitest)는 미지원 = no-op — 2차는 격리 HOME 효과만 (#17 장착≠작동. 정직표: ADAPTER-CONTRACT §5)
# 워크로드 교체 = 이 파일의 함수 본문만 교체 (Python이면 mypy/pytest, Go면 go vet/go test ...)

ladder_typecheck() {
  (cd "$APP" && npx tsc --noEmit) || fail "tsc"
}

ladder_test() {
  # vitest 1회 (JSON + coverage). flaky 방어는 stop_gate의 "2연속 green"이 담당 (개선 ②)
  (cd "$APP" && npx vitest run --reporter=json --outputFile="$ST/vitest.json" --coverage)
}

ladder_green() {
  node "$ROOT/adapter/green_set.js" "$ST/vitest.json" > "$ST/verify-report.json"   # vitest 전용이라 adapter 소속 (#19 엔진 경계 정리)
}

ladder_build() {
  (cd "$APP" && npx vite build) || fail "build"
  [ -s "$APP/dist/index.html" ] || fail "build 산출물 없음"
}

ladder_gaming() {
  # TS/vitest 전용 게이밍 검사 (v2-1 엔진에서 adapter로 이동 — 언어 종속이므로)
  grep -rEn '\.(skip|only|todo)\(|@ts-nocheck|@ts-ignore' "$APP/src" "$APP/tests" 2>/dev/null && fail "skip/only/ts-ignore 발견"
  local TC AC MIN_T MIN_A
  TC=$(grep -rEoh "it\(|test\(" "$APP/tests" 2>/dev/null | wc -l | tr -d ' ')
  AC=$(grep -rEoh "expect\(" "$APP/tests" 2>/dev/null | wc -l | tr -d ' ')
  MIN_T=$(python3 -c "import json;print(json.load(open('$ROOT/adapter/baseline.json'))['min_test_count'])")
  MIN_A=$(python3 -c "import json;print(json.load(open('$ROOT/adapter/baseline.json'))['min_assertion_count'])")
  [ "$TC" -ge "$MIN_T" ] || fail "테스트 수 ratchet ($TC < $MIN_T)"
  [ "$AC" -ge "$MIN_A" ] || fail "assertion 밀도 ratchet ($AC < $MIN_A)"
  # S-ID ↔ 테스트 태그 대응 (SPEC 체크리스트가 진실원, "verify 레벨" 항목 제외)
  local sid
  for sid in $(grep -E '^\- \[S[0-9]+\]' "$ROOT/adapter/SPEC.md" | grep -v 'verify 레벨' | grep -oE 'S[0-9]+' | sort -uV); do
    grep -rq "\[$sid\]" "$APP/tests" || fail "SPEC 항목 $sid 대응 테스트 없음"
  done
}
