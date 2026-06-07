# RUNBOOK — Ralphthon Busan 당일 작전 카드 (10-에이전트 워게임 종합, 6/7)

## 포지셔닝 한 문장 (경쟁 분석 — ralph-codex 레인은 포화, 유일 희소 = 답안지 격리)
> "다른 랄프 루프는 에이전트가 코드도 쓰고 채점기도 들고 있다 — 자기가 자기를 green 준다.
> 우리는 에이전트가 **채점기를 본 적이 없는 시험**을 친다."

## T+분 체크포인트 (타임박스 시뮬 — 현실 합계 225분 = 가용 상한. 컷은 기계 규칙)
| 시각 | 게이트 | 미달 시 |
|---|---|---|
| T+10 | **/goal 실기동 1회** (협상 불가) | S2b 셸 폴백으로 즉시 강등 |
| T+25 | S1 bash -n 전부 + verify 1회 발화 | 자동전진 포기, S5→1항목 단발 |
| T+60 | verify 스모크 핵심 3종(T1·T2·T4) green | S4 전체 컷 |
| T+90 | **MVD 도달** = S1+S3핵심+S2최소+1항목 DONE | 방어 모드 — 신규 0, 안정화만 |
| 데모-20 | 코드 동결 + 리허설 1회 | — |

**MVD(출품 성립선)**: 엔진 이식 + verify 스모크 3종 + "/goal(또는 폴백)이 verify 판정에 복종" 증명 + 1항목 GREEN→DONE.
**컷 순서**: S8→S7(로그만)→S6(install 컷, README 수기)→S4(3종만: T9·T11·T14)→S5 축소. **S1·S2 최소는 불가침.**

## 보험 3 (사전부검 — 가장 싼 순)
1. `codex_loop.sh` 폴백 20줄 — **오전 첫 30분에 먼저** (부검 #1·2·3·5 동시 차단)
2. `.gitignore` 시크릿: `auth.json` `*.toml` `*.sqlite` `.codex/` `.env` `state/` — **첫 커밋 전**, repo는 `~/dev/` 격리 경로, 푸시 전 `git log -p | grep -iE 'sk-|auth|token'`
3. 사전 점화 런 + 화면 녹화 — 데모는 "이미 달리는 열차"(런 B를 무대 −90초 점화)

## 데모 3분 (연출 — 주인공은 [gate] 줄, 갈매기는 22% 증거물)
- 화면: tmux 3분할 (좌상 run.log tail / 좌하 watch-live / 우 게임)
- 훅(5초): "AI한테 '다 했어?' 물으면 항상 '네'라고 합니다. 그래서 저흰 안 물어봅니다 — **기계한테 채점을 시켰어요.**"
- 0:35 **치트캐치 장면** (경쟁분석: 무대 위 누구도 못 보여주는 것): 한 글자 일부러 깨기 → 게임 부서짐(우) + [gate] RED(좌) → 루프가 자가 수정 → GREEN. 90초 내 못 고치면 `git checkout` 수동 복구
- 마무리 30초 (심사위원 +1점 컷): **남의 빈 repo에 install → 깨진 코드 → RED → GREEN** — "재사용성"을 화면으로
- 계기판: "토큰/green 항목" 큰 숫자 한 줄
- 백업 3층: 라이브 → 녹화 1.5배속 → run.log cat. 전환 멘트 준비, 3초 안에

## 규정 레드라인 (심사관 — 보수 판정)
1. **코드 파일 복사 절대 금지** — 스모크·verify 포함. 스펙 보고 새로 친다. 변수명·로그 문구 **새로 작명** (지문 회피가 아니라 의심 원천 제거)
2. 기존 코드 창을 옆에 띄우지 않는다 (보면 닮는다)
3. 증분 커밋 — 첫 커밋은 README+스펙 인용만, 코드는 작게 여러 번
4. README에 "가져온 것(사전 스펙·방법론) / 현장에서 만든 것(모든 코드)" **2열 표** 자진 공개
5. 케이스스터디 문서는 인용 근거로만 — 산출물로 제출 금지

## 설치성 (DX — S6 시간 나면)
- `git clone … && cd … && ./install.sh` 한 줄 (curl|bash 기각 — git tracked 전제). `~/.codex` 불가침, repo-로컬만
- install 마지막 = 스모크 자가증명 (0 failed 아니면 비-0 종료)
- Impact 산 증거: **다른 참가자 머신에서 install→green 1건** 만들고 README `## Adopted at Ralphthon`에 박기

## 워크로드 노트 (악마 보강 — 갈매기는 Impact를 증명 못 한다)
- 본 데모 척추 = 치트캐치 + "남의 repo에 게이트" (반복업무 절감의 직접 증거)
- 갈매기 = 30~40초 증거물 (Live용 시각 자산). 여유 있으면 "테스트 백필 미니 드릴"을 제2 워크로드로 (우리 49→134 실적 서사와 연결)

## 폴백 루프 의미론 — 실탄 검증 완료 (6/7 오후, /tmp 프로브)
- `codex exec` 기본 샌드박스 = **read-only — 쓰기 플래그 없으면 루프가 코드를 못 깎는다!**
  → 반드시 `--sandbox workspace-write` (또는 `-s workspace-write`)
- `codex exec resume --last` = **헤드리스 세션 연속 확인** (2발이 1발의 파일 맥락 기억, 파일 수정 성공)
- 폴백 루프 골격 (행사장에서 새로 친다 — 의미론만 지참):
  while ! verify → `codex exec -s workspace-write resume --last "<verify 출력 + 계속>" </dev/null`
- danger-full-access는 금지 (샌드박스가 우리 답안지 격리의 우군)

## 폴더별 AGENTS.md (강의: "폴더별로 하나씩" — Codex는 디렉토리 스코프로 읽는다)
각 폴더(harness/·adapter/·app/)에 스코프 규칙을 배치 — 이 repo에 이미 깔려 있으면 존재만 확인 (키트 원본: event-kit/agents-tree/): `harness/AGENTS.md`(답안지 — Do not edit),
`adapter/AGENTS.md`(SPEC 불가침), `app/AGENTS.md`(작업장 규칙). 루트 AGENTS.md(헌법)와 4겹 스코프 —
에이전트가 위험 폴더에 *들어서는 순간* Do-not이 컨텍스트에 박힌다. 격리의 prose 층 보강 (lazycodex /init-deep과 같은 패턴).

## Codex 네이티브 훅 — 이종 정찰 확정 (Codex 0.137.0, hooks stable=true)
- SessionStart(startup/resume/clear matcher)·PermissionRequest(allow/deny)·PreCompact/PostCompact(continue:false 가능)·PreToolUse(Bash·apply_patch 일부) **전부 네이티브 존재**. ConfigChange는 없음(셸 보호집합으로 대체).
- **T+10 체크리스트 추가**: `.codex/hooks.json`(또는 config hooks 표면)에 Stop류 훅으로 verify를 걸 수 있는지 1회 실기동 — 되면 S2 정공법(Claude판 stop_gate 동형), 안 되면 objective 주입+셸 폴백 순.
- 야간 자율 승인 = Codex PermissionRequest 훅 + execpolicy (NIGHT-MANDATE의 Codex판 기계화 경로).
- async wake 미지원 — 워치독/전진기는 셸 유지 (번역표 MED 확신).
- T3 요지: Codex는 /goal(목표 상태)+훅+승인이 한 설계면 — Claude판보다 통합적. 단 영속 깨우기는 셸이 우위.

## /goal 정찰 확정 사실 (행사장에서 다시 안 찾아도 됨)
- 도구 3개: create_goal{objective, token_budget} / update_goal{complete만} / get_goal
- continuation·budget_limit 템플릿은 **바이너리 임베드** — 편집 불가. 주입은 **objective 문자열**로
- TUI: `/goal <objective>` · pause · resume · clear. goals_1.sqlite thread당 1 goal
- objective는 `<untrusted_objective>` 래핑 — 상위 지시 아님. 핵심 규율은 AGENTS.md에 이중 앵커
