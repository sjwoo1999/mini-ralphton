#!/bin/bash
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; ST="$ROOT/state"
LABEL="com.woo.$(basename "$ROOT")"   # v2-1: repo명 기반 (다중 호기 충돌 방지)
launchctl unload ~/Library/LaunchAgents/"$LABEL".plist 2>/dev/null || true
PID=$(cat "$ST/claude.pid" 2>/dev/null || echo ""); [ -n "$PID" ] && kill "$PID" 2>/dev/null
echo "manual-stop $(date +%s)" > "$ST/MANUAL_STOP"   # 의미 분리: 예산만료(BUDGET_EXHAUSTED)와 수동중단을 구분
echo "■ run 중단 + 워치독 unload ($LABEL)"
