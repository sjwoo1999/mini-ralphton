#!/usr/bin/env python3
"""PostToolUse: heartbeat touch + run.log append (관찰 가능성). fail-open."""
import json, os, sys, time
try:
    data = json.load(sys.stdin)
    root = os.environ.get("MR_ROOT") or os.environ.get("CLAUDE_PROJECT_DIR") or \
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    st = os.path.join(os.path.realpath(root), "state")
    if os.path.exists(os.path.join(st, ".budget-anchor")):
        open(os.path.join(st, "heartbeat"), "w").write(str(time.time()))
        with open(os.path.join(st, "run.log"), "a") as f:
            f.write(f"{time.strftime('%H:%M:%S')} {data.get('tool_name', '?')}\n")
except Exception:
    pass
sys.exit(0)
