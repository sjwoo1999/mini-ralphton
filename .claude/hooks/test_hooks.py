#!/usr/bin/env python3
"""mini-ralphton 훅 블랙박스 테스트. python3 test_hooks.py 로 실행."""
import json, os, shutil, subprocess, sys, tempfile
H = os.path.dirname(os.path.abspath(__file__))
PASS = FAIL = 0

def run(hook, payload, env=None):
    e = dict(os.environ, **(env or {}))
    return subprocess.run([sys.executable, os.path.join(H, hook)],
                          input=json.dumps(payload), capture_output=True, text=True, env=e)

def check(name, cond):
    global PASS, FAIL
    if cond: PASS += 1
    else: FAIL += 1; print(f"  FAIL: {name}")

def mkroot(anchor=True, phase="build"):
    root = tempfile.mkdtemp()
    os.makedirs(f"{root}/state"); os.makedirs(f"{root}/harness"); os.makedirs(f"{root}/app/src")
    if anchor:
        json.dump({"started_at_epoch": 0, "deadline_epoch": 9e9, "turn_cap": 40},
                  open(f"{root}/state/.budget-anchor", "w"))
    json.dump({"phase": phase, "turn_count": 0, "verify_hashes": [], "green_sets": []},
              open(f"{root}/state/state.json", "w"))
    return root

def edit(path): return {"tool_name": "Edit", "tool_input": {"file_path": path}}
def bash(cmd): return {"tool_name": "Bash", "tool_input": {"command": cmd}}

# --- pre_guard ---
r = mkroot(anchor=False)
check("PG1 anchor 없으면 전부 허용", run("pre_guard.py", edit(f"{r}/harness/SPEC.md"), {"MR_ROOT": r}).returncode == 0)
r = mkroot()
check("PG2 답안지 Edit 차단", run("pre_guard.py", edit(f"{r}/harness/SPEC.md"), {"MR_ROOT": r}).returncode == 2)
check("PG3 build phase src Edit 허용", run("pre_guard.py", edit(f"{r}/app/src/gpx/stats.ts"), {"MR_ROOT": r}).returncode == 0)
check("PG4 repo 밖 Write 차단", run("pre_guard.py", {"tool_name": "Write", "tool_input": {"file_path": "/tmp/evil.txt"}}, {"MR_ROOT": r}).returncode == 2)
check("PG5 .env 차단", run("pre_guard.py", edit(f"{r}/app/.env"), {"MR_ROOT": r}).returncode == 2)
check("PG6 답안지 향한 파괴 Bash 차단", run("pre_guard.py", bash("rm -rf harness/verify.sh"), {"MR_ROOT": r}).returncode == 2)
check("PG7 무해 Bash 허용", run("pre_guard.py", bash("npx vitest run"), {"MR_ROOT": r}).returncode == 0)
r = mkroot(phase="finish")
check("PG8 finish phase src Edit 차단", run("pre_guard.py", edit(f"{r}/app/src/gpx/stats.ts"), {"MR_ROOT": r}).returncode == 2)
check("PG9 finish phase HANDOFF 허용", run("pre_guard.py", edit(f"{r}/HANDOFF.md"), {"MR_ROOT": r}).returncode == 0)
check("PG10 깨진 stdin fail-open", subprocess.run([sys.executable, os.path.join(H, "pre_guard.py")],
      input="not-json", capture_output=True, text=True).returncode == 0)
r = mkroot()
check("PG11 무해 리다이렉션(2>&1) 허용", run("pre_guard.py", bash("bash harness/verify.sh 2>&1"), {"MR_ROOT": r}).returncode == 0)
check("PG12 답안지로의 리다이렉션 차단", run("pre_guard.py", bash("echo hacked > harness/SPEC.md"), {"MR_ROOT": r}).returncode == 2)

# --- stop_gate ---
# 가짜 verify: exit code와 report를 파일로 제어
def mkverify(root, code, green=None):
    v = f"{root}/fakeverify.sh"
    rep = json.dumps({"green_ids": green or []})
    open(v, "w").write(f"#!/bin/bash\nmkdir -p {root}/state\n"
                       f"printf '%s' '{rep}' > {root}/state/verify-report.json\n"
                       f"echo 'fake out code={code} green={green}'\nexit {code}\n")
    os.chmod(v, 0o755)
    return v

def stop(root, verify, extra_env=None):
    return run("stop_gate.py", {"stop_hook_active": False},
               {"MR_ROOT": root, "MR_VERIFY": verify, **(extra_env or {})})

r = mkroot(anchor=False)
check("SG1 anchor 없으면 침묵 통과", stop(r, "/bin/true").returncode == 0 and not run("stop_gate.py", {}, {"MR_ROOT": r}).stdout.strip())
r = mkroot(); open(f"{r}/state/DONE", "w").write("1")
check("SG2 DONE이면 통과", stop(r, mkverify(r, 1)).stdout.strip() == "")
r = mkroot(); open(f"{r}/state/MANUAL_STOP", "w").write("1")
check("SG2b MANUAL_STOP이면 통과(침묵)", stop(r, mkverify(r, 1)).stdout.strip() == "")
r = mkroot()
out = stop(r, mkverify(r, 1, ["S1"]))
check("SG3 verify red → block 재주입", '"decision": "block"' in out.stdout or '"decision":"block"' in out.stdout)
check("SG4 turn_count 증가", json.load(open(f"{r}/state/state.json"))["turn_count"] == 1)
r = mkroot(); v = mkverify(r, 0, ["S1"])
stop(r, v)
check("SG5 verify 2연속 green → DONE 생성", os.path.exists(f"{r}/state/DONE"))
r = mkroot(); v = mkverify(r, 1, ["S1"])
for _ in range(3): stop(r, v)
check("SG6 동일 실패 3연속 → STUCK", os.path.exists(f"{r}/state/STUCK_ON_COMPLETION"))
r = mkroot()  # 핑퐁: green set A,B,A,B (실패 해시는 다르게 — code는 같지만 출력에 green 포함)
for g in (["S1"], ["S2"], ["S1"], ["S2"]): stop(r, mkverify(r, 1, g))
check("SG7 green-set 핑퐁 → STUCK", os.path.exists(f"{r}/state/STUCK_ON_COMPLETION"))
r = mkroot()
json.dump({"started_at_epoch": 0, "deadline_epoch": 1, "turn_cap": 40},
          open(f"{r}/state/.budget-anchor", "w"))  # 이미 만료
v = mkverify(r, 1)
o1, o2, o3 = stop(r, v), stop(r, v), stop(r, v)
check("SG8 만료+핸드오프 없음 → 2회는 block", '"block"' in o1.stdout and '"block"' in o2.stdout)
check("SG9 3회째 → BUDGET_EXHAUSTED", os.path.exists(f"{r}/state/BUDGET_EXHAUSTED") and '"block"' not in o3.stdout)
r = mkroot()
json.dump({"started_at_epoch": 0, "deadline_epoch": 1, "turn_cap": 40}, open(f"{r}/state/.budget-anchor", "w"))
open(f"{r}/HANDOFF.md", "w").write("x"); open(f"{r}/TODO-remaining.md", "w").write("x")
o = stop(r, mkverify(r, 1))
check("SG10 만료+핸드오프 있음 → 즉시 EXHAUSTED", os.path.exists(f"{r}/state/BUDGET_EXHAUSTED") and '"block"' not in o.stdout)
check("SG11 깨진 stdin fail-open", subprocess.run([sys.executable, os.path.join(H, "stop_gate.py")],
      input="bad", capture_output=True, text=True).returncode == 0)
r = mkroot()  # 공회전: 출력은 매번 다르고(동일실패 가드 회피) green은 영원히 빈 집합
def mkverify_noisy(root, code, green=None):
    v = f"{root}/fakenoisy.sh"
    rep = json.dumps({"green_ids": green or []})
    open(v, "w").write(f"#!/bin/bash\nmkdir -p {root}/state\n"
                       f"printf '%s' '{rep}' > {root}/state/verify-report.json\n"
                       f"echo \"noise $RANDOM\"\nexit {code}\n")
    os.chmod(v, 0o755)
    return v
v = mkverify_noisy(r, 1, [])
for _ in range(5): stop(r, v)
check("SG12 공회전(무전진 5연속) → STUCK", os.path.exists(f"{r}/state/STUCK_ON_COMPLETION"))
check("SG13 STUCK 시 DIAGNOSIS.md 생성 (v2-2)", os.path.exists(f"{r}/DIAGNOSIS.md") and "공회전" in open(f"{r}/DIAGNOSIS.md").read())

# --- post_heartbeat ---
r = mkroot()
run("post_heartbeat.py", {"tool_name": "Edit"}, {"MR_ROOT": r})
check("PH1 heartbeat 생성", os.path.exists(f"{r}/state/heartbeat"))
check("PH2 run.log 1줄", os.path.exists(f"{r}/state/run.log") and "Edit" in open(f"{r}/state/run.log").read())
r = mkroot(anchor=False)
run("post_heartbeat.py", {"tool_name": "Edit"}, {"MR_ROOT": r})
check("PH3 anchor 없으면 무동작", not os.path.exists(f"{r}/state/heartbeat"))

print(f"{PASS + FAIL} tests: {PASS} passed, {FAIL} failed")
sys.exit(1 if FAIL else 0)
