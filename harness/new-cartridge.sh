#!/bin/bash
# 사용: bash harness/new-cartridge.sh <새-repo-경로> [워크로드명]
# 당일 고지 워크로드용 신규 호기 스캐폴딩 — 엔진 복사 + adapter 뼈대 + git init + drift/테스트 자가검증.
# 목표: "과제 듣기 → 점화 가능한 카트리지"의 기계적 구간을 30초로 (사람은 SPEC/ladder 내용만 깎는다).
set -euo pipefail
SRCROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DST="${1:?사용: bash harness/new-cartridge.sh <새-repo-경로> [워크로드명]}"
NAME="${2:-$(basename "$DST")}"
[ -e "$DST" ] && { echo "✗ 이미 존재: $DST"; exit 1; }
case "$DST" in
  "$HOME/Desktop/"*|"$HOME/Documents/"*|"$HOME/Downloads/"*)
    echo "✗ TCC 보호 폴더(#8) — launchd 워치독이 차단됨. ~/dev 아래로."; exit 1;;
esac
# launchd 라벨은 basename 파생(start_run.sh) — 같은 이름의 다른 호기와 충돌하면 그쪽 워치독을 덮어쓴다 (#21)
_PL=~/Library/LaunchAgents/"com.woo.$(basename "$DST")".plist
[ -f "$_PL" ] && echo "⚠ 같은 라벨 plist 잔존: $_PL — 기존 호기와 basename 충돌. repo명을 바꾸거나 그쪽 런이 끝났는지 확인."

mkdir -p "$DST/app" "$DST/state"
cp -R "$SRCROOT/harness" "$DST/harness"
cp -R "$SRCROOT/.claude" "$DST/.claude"
cp -R "$SRCROOT/harness/templates/adapter-template" "$DST/adapter"
printf '# PROGRESS — %s\n\n(아직 시작 전)\n\n### 막힘후보\n' "$NAME" > "$DST/PROGRESS.md"
printf 'state/\n' > "$DST/.gitignore"
ENGINE_REV=$(git -C "$SRCROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown")
(cd "$DST" && git init -q && git add -A && git commit -qm "scaffold: $NAME (엔진 $ENGINE_REV from $(basename "$SRCROOT"))")

echo "=== 자가검증 ==="
bash "$DST/harness/check-drift.sh" "$SRCROOT"                      # 엔진 동기 (#1/#19)
PYTHONDONTWRITEBYTECODE=1 python3 -B "$DST/.claude/hooks/test_hooks.py" | tail -1   # 훅 29종 (#16: -B)
bash "$DST/harness/test_verify_smoke.sh" | tail -1                  # verify 골격 스모크 (#18)
bash "$DST/harness/test_backlog_smoke.sh" | tail -1                 # 백로그 전진기 스모크 (#18 3차 봉합)

cat <<EOF
✓ 스캐폴드 완료: $DST  (워크로드: $NAME)
당일 체크리스트 — 사람이 깎는 건 adapter/ 내용물뿐:
 1. harness/ADAPTER-CONTRACT.md 정독 (5분 — 이 문서가 정본)
 2. adapter/SPEC.md — 기계 판정 가능한 S-ID로. 골든 입출력쌍 먼저 확보 (러너 없는 과제면 채점기가 곧 러너, §2)
 3. adapter/ladder.sh — 5함수 TODO 채우기 (참고: 1호 TS / 2호 Python)
 4. adapter/protected.txt TODO 줄 확정 → 전부 커밋 (verify는 dev 모드에서 미커밋이면 거부)
 5. 래칫 음성 대조군(#17): min=실측+1 → fail 확인 후 실측값 고정
 6. bash harness/verify.sh 가 "기대한 이유"로 fail/green 하는지 확인 → bash harness/start_run.sh <분>
EOF
