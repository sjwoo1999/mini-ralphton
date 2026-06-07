# adapter/ladder.sh — <워크로드명> 카트리지 (당일 고지용 뼈대)
# 정본 계약: harness/ADAPTER-CONTRACT.md — 이 문서만 읽고 5함수를 채울 수 있어야 함.
# 주입: $ROOT $APP $ST, fail() 제공. 캐시 언어(Python .pyc 등)는 캐시 무력화 필수(#16: -B + purge).
# 참고 구현: 1호(TS/vitest) mini-ralphton, 2호(Python/coverage) ralphton-2-prdmas 의 adapter/ladder.sh

ladder_typecheck() {
  fail "TODO: 타입/문법 검사 (예: npx tsc --noEmit / \$PY -B -m compileall / go vet)"
}

ladder_test() {
  # 종료코드만 반환 — 판정은 verify 골격. 러너가 없는 워크로드(변환기 등)면
  # 골든 입출력쌍 채점기를 테스트 스위트로 작성하라 (CONTRACT §2 — "러너가 없다"는 "아직 안 만들었다").
  # 채점 결과를 ladder_green에 넘기려면 $ST 사설 파일을 써라 (예: $ST/.grade-out — CONTRACT §7).
  # MR_REVERSE는 반드시 "${MR_REVERSE:-0}" 가드로 읽어라 — 1차 호출 땐 미정의라 set -u 크래시 (#21).
  # 재현성 2차에서 test+green이 1회 더 불린다 — 두 함수는 멱등해야 함 (CONTRACT §1).
  return 1  # TODO
}

ladder_green() {
  # $ST/verify-report.json 에 {"green_ids":["S1",...]} 기록 — 기계 판정으로 충족된 S-ID만 (CONTRACT §2)
  printf '{"green_ids":[]}' > "$ST/verify-report.json"  # TODO
}

ladder_build() {
  :  # 빌드 단계 없으면 이대로 (no-op)
}

ladder_gaming() {
  # skip류 금지 grep + 래칫. baseline의 1은 바닥값일 뿐 — 실측값으로 올려 고정하고
  # 음성 대조군(min=실측+1 → fail)을 한 번 실증할 것 (#17. 0으로 두면 no-op 방어).
  # 함정 2개 (#21 드릴 실측): ① 금지 grep이 정당한 코드(sys.exit(0 if ok else 1) 등)를 오탐하지 않게
  #   패턴을 좁혀라 ② 단언 카운트 grep은 헬퍼 "정의(def check)"와 docstring 산문을 제외하라 — 유령 카운트.
  # ③ fail 메시지에 변수를 쓸 땐 반드시 ${var} 중괄호 — $var직후한글 은 unbound variable 크래시 (#21).
  fail "TODO: 게이밍 검사 (예: skip/only 금지 + min_assertion_count 래칫)"
}
