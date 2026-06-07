#!/usr/bin/env python3
"""Stop: 재주입 엔진 + verify 독립 재검산(2연속 green) + 정체/핑퐁/공회전 + 시간·턴 예산.
출력 {"decision":"block","reason":...} = 계속 / exit 0 무출력 = 종료 허용. fail-open.
계약 토큰의 prose 근거: harness/PROMPT.md §계약 토큰."""
import hashlib, json, os, re, subprocess, sys, time

TURN_FALLBACK_CAP = 40
HANDOFF_MAX_ASKS = 2

def root_dir():
    r = os.environ.get("MR_ROOT") or os.environ.get("CLAUDE_PROJECT_DIR") or \
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    return os.path.realpath(r)

def block(reason):
    print(json.dumps({"decision": "block", "reason": reason}))
    sys.exit(0)

def main():
    json.load(sys.stdin)  # 입력 소비 (형식 검증 겸)
    root = root_dir()
    st_dir = os.path.join(root, "state")
    anchor_p = os.path.join(st_dir, ".budget-anchor")
    if not os.path.exists(anchor_p):
        sys.exit(0)  # 관리 런 아님
    for m in ("DONE", "BUDGET_EXHAUSTED", "STUCK_ON_COMPLETION", "MANUAL_STOP"):
        if os.path.exists(os.path.join(st_dir, m)):
            sys.exit(0)
    anchor = json.load(open(anchor_p))
    st_p = os.path.join(st_dir, "state.json")
    try:
        st = json.load(open(st_p))
    except Exception:
        st = {"phase": "build", "turn_count": 0, "verify_hashes": [], "green_sets": []}
    st["turn_count"] = st.get("turn_count", 0) + 1
    now = time.time()

    def save():
        json.dump(st, open(st_p, "w"))

    def mark(name, reason=""):
        open(os.path.join(st_dir, name), "w").write(f"{now} {reason}".strip())
        if "MR_VERIFY" not in os.environ:  # 테스트 중엔 알림 생략
            inst = os.path.basename(root)  # 인스턴스명 — "mini-ralphton" 하드코딩이던 것 (다중 호기 구분)
            try:  # v2-2: 사람 알림 — 사이클이 끊기지 않게 (fail-open)
                subprocess.run(["osascript", "-e",
                    f'display notification "{inst}: {name} {reason}" with title "ralphton" sound name "Glass"'],
                    capture_output=True, timeout=5)
            except Exception:
                pass
            try:  # 들리는 채널 별도 확보 — 알림 권한이 꺼져 있어도 osascript는 rc=0이라 위만으론 전달 보장 없음
                subprocess.run(["afplay", "/System/Library/Sounds/Glass.aiff"],
                    capture_output=True, timeout=5)
            except Exception:
                pass
        save()
        sys.exit(0)

    # 예산 (시간 OR 턴)
    if now > anchor["deadline_epoch"] or st["turn_count"] > anchor.get("turn_cap", TURN_FALLBACK_CAP):
        handoff_ok = all(os.path.exists(os.path.join(root, f)) for f in ("HANDOFF.md", "TODO-remaining.md"))
        if not handoff_ok and st.get("handoff_asks", 0) < HANDOFF_MAX_ASKS:
            st["handoff_asks"] = st.get("handoff_asks", 0) + 1
            st["phase"] = "finish"
            save()
            block("BUDGET EXPIRED. adapter/PROMPT.md §finish를 따라 HANDOFF.md와 "
                  "TODO-remaining.md를 지금 작성하라. 코드 수정은 차단된다.")
        mark("BUDGET_EXHAUSTED")

    # finish window: max(15%, 하한). 하한은 anchor가 정함 — 절대 하한이 장난감 예산을 삼키는
    # 스케일 역전 방지 (실패 노트 #10: Run 1에서 12분 하한이 10분 예산 전체를 finish로 만듦)
    budget = anchor["deadline_epoch"] - anchor["started_at_epoch"]
    floor = anchor.get("finish_floor_sec", 720)
    if now > anchor["deadline_epoch"] - max(0.15 * budget, floor):
        st["phase"] = "finish"

    # 독립 재검산
    verify = os.environ.get("MR_VERIFY", os.path.join(root, "harness", "verify.sh"))
    def run_verify():
        p = subprocess.run(["bash", verify], capture_output=True, text=True, timeout=600, cwd=root)
        return p.returncode, (p.stdout + p.stderr)
    code, out = run_verify()
    try:
        green = json.load(open(os.path.join(st_dir, "verify-report.json"))).get("green_ids", [])
    except Exception:
        green = []
    # 해시는 마지막 줄(실패 사유)만 — 전체 출력엔 빌드 시간 등 노이즈가 섞여 동일실패 가드가 영구 미발동 (Run 6에서 루프가 신고한 버그)
    fail_line = out.splitlines()[-1] if out.splitlines() else ""
    st["verify_hashes"] = (st.get("verify_hashes", []) + [hashlib.sha1(fail_line.encode()).hexdigest()[:12]])[-5:]
    st["green_sets"] = (st.get("green_sets", []) + [",".join(green)])[-6:]
    # 공회전 카운터: "전진 = green 항목 수의 신기록". 늘지 않으면 라운드만 도는 것
    if len(green) > st.get("max_green", 0):
        st["max_green"] = len(green)
        st["no_progress"] = 0
    else:
        st["no_progress"] = st.get("no_progress", 0) + 1

    # 개선 ④ 관전 화면: 라운드 요약 1줄 (tail -f run.log로 green 추이가 보이게)
    try:
        with open(os.path.join(st_dir, "run.log"), "a") as f:
            f.write(f"{time.strftime('%H:%M:%S')} [gate] R{st['turn_count']} "
                    f"verify={'GREEN' if code == 0 else 'red'} green={len(green)} "
                    f"np={st['no_progress']} phase={st['phase']}\n")
    except Exception:
        pass

    if code == 0:
        code2, _ = run_verify()  # 완성은 까다롭게: 2연속 green
        if code2 == 0:
            mark("DONE")

    # v2-2 DIAGNOSIS: 막힘 원인의 기계 분류는 불가능 — 분류 대신 증거 정렬 (사람 5분 진단용)
    def diagnose(guard):
        try:
            spec_ids = []
            for ln in open(os.path.join(root, "adapter", "SPEC.md"), encoding="utf-8"):
                if ln.startswith("- [S") and "verify 레벨" not in ln:
                    m = re.match(r"- \[(S\d+)\]", ln)
                    if m:
                        spec_ids.append(m.group(1))
            missing = [s for s in spec_ids if s not in green]
        except Exception:
            missing = []
        prog_note = ""
        try:
            txt = open(os.path.join(root, "PROGRESS.md"), encoding="utf-8").read()
            if "### 막힘후보" in txt:
                prog_note = txt.split("### 막힘후보", 1)[1].strip()[:500]
        except Exception:
            pass
        try:
            with open(os.path.join(root, "DIAGNOSIS.md"), "w", encoding="utf-8") as f:
                f.write("# DIAGNOSIS — 런 정지 (사람 5분 진단용)\n\n"
                        f"- 발동 가드: {guard}\n"
                        f"- green 미달 첫 항목(의심 지점): {missing[0] if missing else '(전부 green — 판정기 자체를 의심)'}\n"
                        f"- 라운드 R{st['turn_count']} · green {len(green)}개 · no_progress {st.get('no_progress', 0)}\n\n"
                        "## verify tail\n```\n" + "\n".join(out.splitlines()[-15:]) + "\n```\n\n"
                        f"## 루프의 막힘후보 메모 (PROGRESS에서)\n{prog_note or '(기록 없음)'}\n\n"
                        "## 다음 행동\nSPEC 보강 → `bash harness/start_run.sh <분>` 재점화 (SPEC diff가 부트 프롬프트에 자동 주입됨)\n")
        except Exception:
            pass

    vh, gs = st["verify_hashes"], st["green_sets"]
    if code != 0 and len(vh) >= 3 and vh[-1] == vh[-2] == vh[-3]:
        diagnose("동일 실패 3연속")
        mark("STUCK_ON_COMPLETION", "동일실패")
    if len(gs) >= 4 and gs[-1] == gs[-3] and gs[-2] == gs[-4] and gs[-1] != gs[-2]:
        diagnose("green-set 핑퐁 진동")
        mark("STUCK_ON_COMPLETION", "핑퐁")
    if code != 0 and st["no_progress"] >= 5:
        diagnose("공회전 — 5라운드 연속 green 신기록 없음")
        mark("STUCK_ON_COMPLETION", "공회전")
        # (실패 해시가 매번 달라도 잡힘 — 동일실패/핑퐁이 못 잡는 "무의미한 다른 수정" 커버)

    save()
    tail = "\n".join(out.splitlines()[-15:])
    block(f"[round {st['turn_count']}] [phase={st['phase']}] verify 미통과 — 계속하라.\n"
          f"adapter/PROMPT.md §{st['phase']} 와 PROGRESS.md를 다시 읽고 한 슬라이스만 전진.\n"
          f"green={green}\n--- verify tail ---\n{tail}")

try:
    main()
except SystemExit:
    raise
except Exception:
    sys.exit(0)  # fail-open
