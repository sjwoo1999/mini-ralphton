#!/bin/bash
# 사용: bash harness/watch-live.sh [--replay]
# 무인 런의 대화록(jsonl)을 사람이 읽을 중계로 변환 — 💬 루프의 생각/말, 🔧 도구 행동.
# 기본: 라이브 follow (런 도중 실시간 중계 — 두 번째 터미널이나 Claude 세션 Monitor에 걸어두는 용도).
# --replay: 가장 최근 런을 처음부터 재생하고 종료 (사후 부검).
# 읽기 전용 관측 도구 — verify/start_run 어디서도 source되지 않음 (런 동작에 영향 0).
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJ="$HOME/.claude/projects/$(echo "$ROOT" | tr '/' '-')"
J=$(ls -t "$PROJ"/*.jsonl 2>/dev/null | head -1)
[ -n "$J" ] || { echo "✗ 대화록 없음: $PROJ (런이 한 번은 돌았어야 함)"; exit 1; }
echo "● 중계 소스: $(basename "$J")"
render() {
python3 -B -u -c '
import json, sys
for line in sys.stdin:
    try:
        o = json.loads(line)
    except Exception:
        continue
    m = o.get("message") or {}
    role, c = m.get("role"), m.get("content")
    if not isinstance(c, list):
        continue
    for b in c:
        t = b.get("type")
        if role == "assistant" and t == "text" and b.get("text", "").strip():
            print("\U0001F4AC " + b["text"].strip().replace("\n", " ")[:200], flush=True)
        elif role == "assistant" and t == "tool_use":
            inp = b.get("input", {})
            hint = inp.get("file_path") or inp.get("description") or str(inp.get("command", ""))[:70]
            print("\U0001F527 " + str(b.get("name")) + ": " + str(hint)[:90], flush=True)
'
}
if [ "${1:-}" = "--replay" ]; then
  render < "$J"
else
  tail -n +1 -f "$J" | render
fi
