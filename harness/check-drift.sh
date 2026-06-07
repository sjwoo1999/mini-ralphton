#!/bin/bash
# 호기 간 엔진 동기 검문 (실패 노트 #6 역전파 규율 + #1 캐시 drift의 호기판 방지).
# 사용: bash harness/check-drift.sh <다른-인스턴스-루트>
# 엔진층(harness/ + .claude/hooks/)만 비교 — adapter/는 워크로드별이라 제외.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OTHER="${1:?사용: bash harness/check-drift.sh <other-repo-root>}"
[ -d "$OTHER" ] || { echo "✗ 경로 없음: $OTHER"; exit 1; }
RC=0
for d in harness .claude/hooks; do
  if diff -rq "$ROOT/$d" "$OTHER/$d" -x '__pycache__' -x '*.pyc' > /tmp/drift.txt 2>&1; then
    echo "✓ $d 동기"
  else
    echo "⚠ $d DRIFT:"; sed 's/^/    /' /tmp/drift.txt; RC=1
  fi
done
[ "$RC" -eq 0 ] && echo "엔진 완전 동기 — 역전파 클린" || echo "→ [harness] 커밋을 cherry-pick하거나 cp로 맞출 것"
exit "$RC"
