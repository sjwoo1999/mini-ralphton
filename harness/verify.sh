#!/bin/bash
# 판정 골격 (범용층). 워크로드별 판정 내용은 adapter/ladder.sh가 정의. (답안지 — 루프 수정 금지)
# 전제: 보호 집합은 전부 git tracked 상태여야 함 (untracked면 탬퍼로 간주).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/app"; ST="$ROOT/state"; mkdir -p "$ST"
cd "$ROOT"
fail(){ echo "VERIFY FAIL: $1"; exit 1; }
trap '[ -n "${_RHOME:-}" ] && rm -rf "$_RHOME"' EXIT   # 재현성 2차 임시 HOME 누수 방지 (워치독 kill 시나리오)

# 보호 집합 = adapter/protected.txt 단일 진실원 (v2-1: 3중복 해소 — 실패노트 #2/#7)
PROT=()
while IFS= read -r line; do
  [ -n "$line" ] && [ "${line:0:1}" != "#" ] && PROT+=("$line")
done < "$ROOT/adapter/protected.txt"
[ "${#PROT[@]}" -gt 0 ] || fail "protected.txt 비어 있음 (격리 무력화 방지)"

# ④-1 답안지 무결 — git status --porcelain: 수정 + 신규(untracked) 탬퍼까지 탐지
if [ -n "$(git status --porcelain -- "${PROT[@]}" 2>/dev/null)" ]; then
  if [ -f "$ST/.budget-anchor" ]; then
    # 런 모드: 루프의 탬퍼 → 파괴적 복원 (SWE-bench 패턴). 개별 복원 — 일괄 checkout은 매치실패 1건에 전체 무산
    for p in "${PROT[@]}"; do git checkout -- "$p" 2>/dev/null || true; done
    # untracked 탬퍼 청소를 protected.txt 기반으로 일반화 (#19: 구버전은 1호 경로 하드코딩 → 2호 잔존 구멍)
    git clean -fd -- adapter "${PROT[@]}" 2>/dev/null || true
    fail "ANSWER-KEY TAMPERED (원복됨 — 답안지를 수정하지 마라)"
  else
    # 개발 모드(anchor 없음): 제작자의 미커밋 수정은 정상 — 파괴 금지 (실패 3: 학살 사건)
    fail "uncommitted answer-key changes — dev mode: 커밋 먼저, verify 나중"
  fi
fi
echo '{"green_ids":[]}' > "$ST/verify-report.json"   # stale green 방지 (핑퐁 판정 정직성)

# 판정 사다리 — 내용물은 adapter가 정의 (cheap first)
source "$ROOT/adapter/ladder.sh"
ladder_typecheck
ladder_test; VT=$?
ladder_green
[ "$VT" -eq 0 ] || fail "test"

# ④-0 재현성 검사 (실패 노트 #15 방어): ladder_test를 격리 HOME에서 1회 더 → green_ids 불일치 = 비결정/격리 결함.
# "통과하는가"와 "항상 통과하는가"는 다른 축 — 무인 루프는 후자가 필수(아침에 사람 없음). baseline.repro=false로 opt-out.
REPRO=$(python3 -c "import json;print(json.load(open('$ROOT/adapter/baseline.json')).get('reproducibility',True))" 2>/dev/null || echo True)
if [ "$REPRO" = "True" ]; then
  cp "$ST/verify-report.json" "$ST/.report1.json"
  G1=$(python3 -c "import json;print(','.join(json.load(open('$ST/.report1.json'))['green_ids']))" 2>/dev/null)
  # 2차 = 격리 HOME 재실행 — 환경(HOME 경로/캐시) 의존과 비결정 실패를 탐지.
  # MR_REVERSE=1도 주입하나 실효는 어댑터에 달림(#17 — 장착≠작동): 1호 vitest 미지원(no-op),
  # 2호는 rc 차이만 탐지(green은 coverage 누적이라 순서 무관). 순서 의존 탐지를 보증하지 않음. 정직표: ADAPTER-CONTRACT §5
  _RHOME=$(mktemp -d); _OLDHOME=$HOME; export HOME="$_RHOME" MR_REVERSE=1
  ladder_test > /dev/null 2>&1; VT2=$?
  ladder_green
  export HOME="$_OLDHOME"; unset MR_REVERSE; rm -rf "$_RHOME"
  G2=$(python3 -c "import json;print(','.join(json.load(open('$ST/verify-report.json'))['green_ids']))" 2>/dev/null)
  cp "$ST/.report1.json" "$ST/verify-report.json"   # 1차(정상 HOME) 결과를 기준으로 복원
  if [ "$VT" != "$VT2" ] || [ "$G1" != "$G2" ]; then
    # 주의: 변수 직후 멀티바이트 문자(≠) 금지 — bash가 변수명에 바이트를 끌어들여 unbound variable 크래시 (스모크 T3가 발견)
    fail "재현 불가 — 테스트 격리/순서 결함 (rc $VT != $VT2 또는 green [$G1] != [$G2]). 같은 코드가 환경 따라 다른 결과 = 거짓 GREEN 위험"
  fi
fi

ladder_build

# ④-2 게이밍 검사 — 검사 방법은 언어/도구 종속이라 adapter 몫 (2호 일반화: 첫 비-TS 워크로드)
ladder_gaming

# ④-3 완성성 검사 (범용): 완성 = SPEC 체크리스트 전 항목이 green_ids에 존재
# (2호 드라이런에서 발견된 엔진 공백 — TS 어댑터에선 태그 검사가 우연히 대행해서 안 보였음)
GREEN_IDS=$(python3 -c "import json;print(' '.join(json.load(open('$ST/verify-report.json')).get('green_ids',[])))" 2>/dev/null || echo "")
for sid in $(grep -E '^\- \[S[0-9]+\]' "$ROOT/adapter/SPEC.md" | grep -v 'verify 레벨' | grep -oE 'S[0-9]+' | sort -uV); do
  case " $GREEN_IDS " in
    *" $sid "*) ;;
    *) fail "SPEC 항목 $sid 미충족 (green_ids에 없음)";;
  esac
done

# green 태깅 = 부수효과 (LLM 행위 아님)
git tag -f run-last-green HEAD >/dev/null 2>&1 || true
echo "VERIFY GREEN"
exit 0
