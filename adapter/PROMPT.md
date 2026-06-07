# PROMPT — 카공지도 v0.1 run

## §build (phase=build 일 때 이 절만 따른다)
1. `adapter/SPEC.md`와 `PROGRESS.md`를 읽어라. 미완 S 항목 중 **하나만** 골라 세로 슬라이스로 끝내라
   (테스트 작성 → 구현 → `bash harness/verify.sh`). S1→S2→… 순서 권장. 테스트는 `app/tests/*.spec.ts`, 테스트명에 `[S#]` 태그 필수(채점기가 태그로 green 산출).
2. 매 라운드 종료 전: ① `git add -A && git commit` (`[red]`/`[green]` 접두) ② PROGRESS.md 갱신 + 핸드오프 메모 3줄.
3. verify 실패 시: 테스트 결함 vs 제품 결함 먼저 분리.
4. 금지: 답안지(protected.txt 목록) 수정 · 시드 JSON(tests/protected/) 수정 · **새 npm 의존성 추가**(셸 제공됨, leaflet 포함) ·
   Leaflet 렌더를 jsdom에서 테스트(1호 교훈 — v0.1엔 지도 없음) · `.skip/.only/@ts-ignore` · **완료 선언 금지**
   (verify GREEN이면 하네스가 알아서 멈춘다).
5. 매 라운드 PROGRESS.md `### 막힘후보` 갱신: 가장 불확실한 항목 1 + 택한 해석 + 직전 실패 이유 1줄.

## §finish (phase=finish 신호 시)
1. 코드 수정 금지. HANDOFF.md(중단 사유·마지막 green·다음 1수) + TODO-remaining.md + PROGRESS 최종.
2. 다 썼으면 멈춰라.

## 계약 토큰
phase: `build` | `finish` · 마커: `state/DONE`, `state/BUDGET_EXHAUSTED`, `state/STUCK_ON_COMPLETION`
