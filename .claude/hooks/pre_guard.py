#!/usr/bin/env python3
"""PreToolUse: 답안지 격리 + 외부경로/.env deny + finish-phase 권한 프리셋.
exit 2 = 차단(stderr가 모델에게 전달). 그 외 = 허용. fail-open.
보호 목록은 adapter/protected.txt 단일 진실원 (v2-1) — verify.sh와 공용."""
import json, os, re, sys

# fallback: protected.txt 부재 시(테스트 임시루트 등) 보수적 기본값
DEFAULT_PROTECTED = ["harness/", "adapter/", "fixtures/", "app/tests/protected/", ".claude/",
                     "app/tsconfig.json", "app/vitest.config.ts", "app/package.json"]
FINISH_ALLOW = ["PROGRESS.md", "HANDOFF.md", "TODO-remaining.md", "state/"]
# 개선 ③: 리다이렉션은 "타깃이 답안지일 때만" 차단 — `2>&1` 같은 무해 리다이렉션 오탐 제거 (Run 3 관찰)
DESTRUCTIVE = re.compile(r"(^|[;&|]\s*)(rm|mv|cp|chmod|chattr|ln|tee|truncate)\s|git\s+(checkout|restore|reset)")
REDIR_TARGET = re.compile(r">>?\s*([^\s&|;]+)")

def load_protected(root):
    try:
        out = []
        for ln in open(os.path.join(root, "adapter", "protected.txt")):
            ln = ln.strip()
            if ln and not ln.startswith("#"):
                out.append(ln)
        if out:
            return out
    except Exception:
        pass
    return DEFAULT_PROTECTED

def deny(msg):
    sys.stderr.write(msg)
    sys.exit(2)

def main():
    data = json.load(sys.stdin)
    root = os.environ.get("MR_ROOT") or os.environ.get("CLAUDE_PROJECT_DIR") or \
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    root = os.path.realpath(root)
    if not os.path.exists(os.path.join(root, "state", ".budget-anchor")):
        sys.exit(0)  # 관리 런 아님 — 개발 세션 방해 금지
    protected = load_protected(root)
    tool, ti = data.get("tool_name", ""), data.get("tool_input", {})
    try:
        phase = json.load(open(os.path.join(root, "state", "state.json"))).get("phase", "build")
    except Exception:
        phase = "build"

    if tool in ("Edit", "Write", "MultiEdit", "NotebookEdit"):
        p = os.path.realpath(ti.get("file_path", ""))
        if not p.startswith(root + os.sep):
            deny(f"BLOCKED: 프로젝트 밖 쓰기 금지: {p}")
        rel = os.path.relpath(p, root)
        if os.path.basename(p).startswith(".env"):
            deny("BLOCKED: env 파일 금지")
        for prot in protected:
            if rel == prot.rstrip("/") or rel.startswith(prot):
                deny(f"BLOCKED: 답안지({rel})는 수정 금지. SPEC을 코드로 충족시켜라.")
        if phase == "finish" and not any(rel == a.rstrip("/") or rel.startswith(a) for a in FINISH_ALLOW):
            deny("BLOCKED: finish phase — 코드 수정 금지. HANDOFF.md/TODO-remaining.md/PROGRESS.md만.")
    elif tool == "Bash":
        cmd = ti.get("command", "")
        if DESTRUCTIVE.search(cmd) and any(tok in cmd for tok in protected):
            deny("BLOCKED: 답안지를 향한 파괴적 쉘 명령 금지.")
        for tgt in REDIR_TARGET.findall(cmd):  # 리다이렉션은 타깃 기준으로만
            if any(tok in tgt for tok in protected):
                deny(f"BLOCKED: 답안지로의 리다이렉션 금지 ({tgt}).")
    sys.exit(0)

try:
    main()
except SystemExit:
    raise
except Exception:
    sys.exit(0)  # fail-open: 훅 버그가 런을 벽돌로 만들지 않게
