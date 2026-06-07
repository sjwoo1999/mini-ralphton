# SPEC A — codex-ralph: verify-게이트 백로그 하네스, Codex판 (Ralphthon Track 1 출품작)

## 불변 규칙
- 행사 중 **새 public repo**에서 작성. 기존 mini-ralphton(Claude판)은 README "Prior Art / 사전 연구"로 출처 명시 — 원본 기여 구분(행사 규칙).
- 판정기 = 스모크 스위트(런타임 무관 셸). 코드보다 스모크 green이 완료의 정의.
- 토큰 경제가 1급 설계 축: codex exec가 매 호출 토큰을 보고함 → **토큰/green-항목 비율**을 데모 지표로 수집.

## 판정 방식
스모크 16종(verify 8 + backlog 8)이 합격 기준 — 전부 셸이라 Codex판 엔진 위에서 그대로 돌아야 함.

## 기계 체크리스트 (T1 — 코어, 행사 전반부)
- [S1] 엔진 골격 이식: `verify.sh`(4게이트 사다리)·`backlog_advance.sh`·루프 러너·`start_run.sh`가 새 repo에 — `bash -n` 전부 통과
- [S2] 루프층 = Codex `/goal` **objective 주입** (정찰 확정 6/7: continuation.md는 바이너리 임베드 — 편집 불가!):
  `/goal` objective에 "완료 조건 = `bash harness/verify.sh`가 VERIFY GREEN + 큐 소진. 그 전에 update_goal(complete) 금지"를 박는다
  (define-goal SKILL 공식 패턴: verification evidence를 objective에). AGENTS.md가 이중 앵커.
  - (S2 폴백 보험 — S-ID 아님) **셸 폴백 루프 (보험 1순위 — /goal 의미론이 어긋날 때)**: `codex_loop.sh` ~20줄 —
  `while ! bash harness/verify.sh; do codex exec resume --last "verify 출력 보고 미완 항목 계속" </dev/null; done`
  T+10분 /goal 실기동이 실패하면 즉시 이 경로로 강등 (데모 서사는 동일: "기계가 채점관")
- [S3] verify 스모크 8종 green (T1~T8 — GREEN·완성성·재현성·탬퍼·opt-out·테스트게이트·빈보호집합·dev비파괴)
- [S4] backlog 스모크 8종 green (T9~T16 — 전진·만료·소진·락·생존양보·실패재시도·낡은cursor·숫자cursor)
- [S5] 라이브 미니드릴: 토이 워크로드(골든쌍 1개) 2항목 캠페인이 codex로 점화→자동 전진→큐 소진 DONE — run.log로 증명
- [S6] 설치성: `install.sh` + README(설치 3줄·quickstart 30초·데모 영상 자리) — **빈 디렉토리에서 install→스모크 green 재현**이 검사
- [S7] 토큰 절감 출력 규칙: PROMPT 템플릿에 "라운드 보고 ≤3줄, 산문 거품 금지" + codex 토큰 보고를 `state/tokens.log`로 수집

## 티어 2 (스트레치 — 시간 남으면)
- [S8] 하이브리드 라우팅: 코드베이스 탐색·웹 리서치류 서브태스크를 저가/로컬 모델로 위임하는 어댑터 훅 (OmO oh-my-openagent 패턴)

## 가정 — 사람이 닫는다 (S-ID 금지)
- [A1] `/goal` 의미론 — 정찰로 절반 확정(5상태·예산·objective 주입·모델은 complete만 가능), **미지 = 헤드리스 여부**(TUI 전용 유력).
  **T+10분 실기동은 협상 불가** — 성공 시 /goal 경로, 실패 시 셸 폴백(S2 하위 보험). 어느 쪽이든 출품 성립 ‹CONFIRM›
- [A2] 데모 워크로드 = SPEC-B 갈매기 러너 ‹CONFIRM›
- [A3] 트랙 1 잠금, 부산 양념은 워크로드 쪽에서 ‹CONFIRM›
