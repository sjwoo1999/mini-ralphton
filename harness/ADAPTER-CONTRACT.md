# ADAPTER-CONTRACT — 엔진↔카트리지 정본 계약 (v1, 2026-06-06)

> 이 문서가 코드와 어긋나면 **문서를 신뢰**하고 코드를 고칠지 결정한다.
> 기원: 6/6 5-에이전트 감사 — 계약이 두 예시 ladder와 verify.sh의 grep 패턴에만 암묵 존재했음 (실패노트 #19).
> 새 카트리지(3호~)는 이 문서만 읽고 작성 가능해야 한다. 부족하면 이 문서를 보강하는 게 수리다.
> **시작은 스캐폴더로**: `bash harness/new-cartridge.sh <새-repo> "<과제>"` — 엔진 복사 + `harness/templates/adapter-template/` 전개 + 자가검증까지 자동. 손 복사 금지.

## 1. ladder.sh가 제공해야 하는 함수 (verify.sh가 source 후 순서대로 호출)

| 함수 | 의무 | 실패 표현 |
|---|---|---|
| `ladder_typecheck` | 타입/문법 검사 (캐시 언어는 캐시 무력화 필수 — #16) | `fail "<이유>"` |
| `ladder_test` | 판정기 실행 | **종료코드만 반환** (판정은 verify 골격) |
| `ladder_green` | `$ST/verify-report.json`에 `{"green_ids":["S1",...]}` 기록 | — |
| `ladder_build` | 빌드/패키징 (없으면 `:`) | `fail "<이유>"` |
| `ladder_gaming` | 게이밍 검사 (skip류 금지 + 래칫 — 언어 종속) | `fail "<이유>"` |

주입받는 것: `$ROOT` / `$APP`(=`$ROOT/app` 관례) / `$ST`(=`$ROOT/state`), `fail()`.

- **멱등 의무**: reproducibility=true면 `ladder_test`+`ladder_green`이 재현성 2차(격리 HOME)에서 **1회 더** 호출된다 — 두 함수는 반복 실행에 안전해야 한다.

## 2. green_ids의 의미 — 일반화 (#19)

- green_ids = **기계 판정기가 "충족" 판정한 SPEC S-ID 집합**. 테스트 러너(vitest/pytest)는 판정기의 *한 구현*일 뿐이다.
- 러너가 없는 워크로드(변환기·생성기 등)는 **골든 입출력쌍 채점기를 테스트 스위트로 작성**한다 —
  "러너가 없다"는 "러너를 아직 안 만들었다"이다. (3호 예: 실제 final-prd.md 샘플 N개 → 기대 SPEC 구조 단언)
- **사람만 닫을 수 있는 항목(‹CONFIRM›, 가정 `[A*]` 등)에는 S-ID를 부여하지 않는다.**
  완성성 검사(④-3, green ⊇ S전항목)가 S-ID만 세기 때문 — 기계 판정 불가한 S-ID는 영구 STUCK을 만든다.

## 3. SPEC.md 기계 계약 (정본)

- 기계 판정 대상 줄: `- [S<n>] <설명>`. 소비자별 매칭은 **표현이 다르다** (6/6 감사 정정 — "4곳 동일"은 거짓이었음):
  - verify.sh ④-3 / 1호 ladder_gaming: `^\- \[S[0-9]+\]` (행 앵커 정규식, **SPEC.md를 읽음**)
  - stop_gate(진단): `startswith("- [S")` — 행 앵커 없음, 같은 줄 형식이면 일치
  - green 산출기(green_set.js/green_py.py): **SPEC.md를 읽지 않는다** — 판정기 산출물(테스트명/커버리지)에서 `[S<n>]` 태그를 추출. SPEC의 S-ID와 판정기 쪽 태그를 **양쪽 다** 맞춰야 green이 잡힌다.
- `verify 레벨` 토큰이 든 S줄은 완성성 집계에서 제외 (사다리 자체가 보증하는 항목).
- 그 외 모든 텍스트(섹션·가정·‹CONFIRM›·WHY 주석)는 기계가 무시한다 — 사람·루프용 산문.
- placeholder S-ID 금지: 템플릿 예시는 주석 상태로 배포된다 — **기계 판정 가능해진 항목만 살려라** (살아있는 S줄은 즉시 완성성 게이트의 빚이다).

## 4. baseline.json 스키마 — 생산자·소비자 (NEVER #7)

| 키 | 소비자 | 부재 시 |
|---|---|---|
| `reproducibility` | verify.sh ④-0 (`false` = 재현성 2차 생략) | `true` (검사 켜짐) |
| `min_test_count` `min_assertion_count` `min_coverage_lines_pct` 등 래칫 | adapter `ladder_gaming` / green 산출기 | 어댑터 정의 |

- **래칫 키를 0으로 두면 그 방어는 no-op이다 (#17)** — 키를 두려면 음성 대조군(실제 fail 재현) 실증을 동봉하라.
- ladder가 baseline 키를 읽을 땐 **하드 서브스크립트 금지** — `.get(키, 기본값)` 또는 `${var:-기본}` (키 누락이 "ratchet fail"로 위장된 KeyError 미궁을 만든다. 1·2호 ladder를 복사하면 그쪽 baseline 키도 함께 가져와라).
- 단언 카운트 grep은 **헬퍼 정의(`def check`)와 docstring 산문을 제외**하라 — 유령 카운트가 래칫을 부풀려 정당한 리팩터를 거짓 fail시킨다 (#21, 2호에서 54→49 교정).

## 5. MR_REVERSE — 실효 정직표 (#17 장착≠작동)

- verify ④-0 2차가 `MR_REVERSE=1`을 export. 어댑터는 지원 시 테스트 역순 실행, 미지원 무해(no-op).
- **현재 실효: 어느 호기도 "순서 의존 → green 흔들림" 탐지를 보증하지 않는다.**
  - 1호(vitest): 미지원 = no-op. 2차는 격리 HOME 효과만.
  - 2호(coverage): 역순 실행되나 green_ids가 coverage 누적(`-a`)이라 순서 무관 — rc 차이만 탐지.
- 새 어댑터가 이 신호를 받으면, 받았다는 사실이 아니라 **fail을 낸 음성 대조군**으로 실효를 증명하라.
- 읽을 땐 반드시 `"${MR_REVERSE:-0}"` — 1차 호출 시점엔 미정의라 무가드 `$MR_REVERSE`는 set -u 크래시 (#21 드릴 실측).

## 6. 검증 비용 사다리 배치 (#14)

- **매 라운드** (verify 루프, 초 단위만): typecheck → test → 재현성 2차 → build → gaming → 완성성.
- **승격 1회** (분 단위, 루프 밖): 뮤테이션 게이트. `mutation_gate.py`는 준엔진 — 새 카트리지는 2호 것을 복제하되,
  **check-drift 비교 범위(harness/ + .claude/hooks/) 밖**임을 인지하고 수동 동기 (#19 사각).

## 7. $ST 산출물 — 생산자·소비자·청소자 3자 대조 (#20)

| 파일 | 생산 | 소비 | 청소 |
|---|---|---|---|
| `verify-report.json` | ladder_green | stop_gate · verify ④-3 | start_run(#20) + verify가 매회 초기화 |
| `.report1.json` | verify ④-0 (1차 백업) | verify ④-0 | start_run(#20) |
| `claude.pid` | start_run | 이중점화 가드 · stop_run · watchdog | start_run(#20, 가드 검사 후) |
| `run.log` `session.log` `watchdog.log` | 훅/claude/워치독 | 사람 (진단) | start_run이 `.prev`로 로테이트(#20) |
| `.golden-green` 등 어댑터 사설 파일 | 어댑터 자유 | 어댑터 | **어댑터가 매 실행 초두에 직접 청소** |

새 상태 파일을 추가할 때는 이 표에 3자(생산·소비·청소)를 먼저 적는다 — 한 칸이라도 비면 고아 잔재가 된다.
- 러너 없는 워크로드의 표준 배관: `ladder_test`(채점기 실행, rc만) → 채점 결과를 `$ST/.grade-out` 같은 사설 파일에 → `ladder_green`이 읽어 green_ids 변환. 이 패턴이면 §1 분리 계약과 충돌 없다 (#21 드릴 검증).

## 8. 셸 작성 규칙 — 당일 크래시 함정 (#21 드릴에서 전부 실제로 밟음)

- **변수 직후 멀티바이트(한글·≠ 등) 금지** — bash가 바이트를 변수명에 끌어들여 unbound variable 크래시. fail 메시지에 변수를 쓰면 **반드시 `${var}` 중괄호**. (스모크 T3가 엔진에서, 드릴이 어댑터에서 각각 실증)
- 게이밍 금지 grep은 정당한 코드를 오탐하지 않게 좁혀라 — 예: "무조건 exit 0" 탐지가 `sys.exit(0 if ok else 1)`을 잡으면 안 된다. 패턴을 짠 뒤 **정상 카트리지에 한 번 돌려 오탐 0을 확인**하고 박아라.
- verify는 `bash 3.2`(macOS /bin/bash)에서 돈다 — 4.x 전용 문법(연관배열, `&>>` 등) 금지.

## 9. 백로그 큐 — 예산 소진형 야간 런 (6/7 설계: 완주 기준은 신성, 일감은 큐로)

- 원칙 3분리: **기준**(green=DONE, 불변) / **예산**(anchor 시계) / **일감**(이 큐). "7시간 안 채웠다"의 해법은 기준 인플레가 아니라 일감 공급 — 기준을 시간에 묶으면 Goodhart(토톨로지·임계 조작)가 온다.
- `adapter/BACKLOG.md`: **사람이 런 전에** 작성하는 유한 큐. 형식: `- specs/<spec파일>  <메모>` 한 줄 하나, 위→아래 소비.
  점화 전 사람이 첫 항목을 `adapter/SPEC.md`로 활성화해 두고 시작 (cursor=1 암묵).
- 전진 체인: 항목 N 런이 **진짜 DONE** → 워치독(180초 틱)이 감지 → `backlog_advance.sh`가
  [예산 잔여 + 다음 항목 존재] 확인 → SPEC 스왑·**커밋**(런모드 탬퍼 오인 방지) → cursor++ → `MR_KEEP_PLIST=1 start_run` 재점화
  (anchor 미만료라 시계 유지 + SPEC diff 부트 주입 = fresh context가 바뀐 일감만 받음). 큐 소진 → DONE 유지 = 캠페인 완주.
- 항목 중 하나가 STUCK → 체인 정지(전진은 DONE에만 발화), DIAGNOSIS 남음 — 막힌 채 큐를 건너뛰지 않는다.
- 상태파일 3자 (§7 연장): `BACKLOG.md`·`specs/*`(생산 사람 / 소비 전진기 / 청소 사람) · `state/.backlog-cursor`(생산·소비 전진기 / **청소 사람 — 새 캠페인 시작 시 rm 필수**, start_run은 안 지움: 항목 간 생존이 설계) · `state/.advance-lock`(전진기 자체, 10분 묵으면 자가 회수).
- 함정 박제: 전진기가 일반 start_run을 부르면 **자기(워치독) launchd 잡을 unload해 도중 사망** — MR_KEEP_PLIST=1 필수.
