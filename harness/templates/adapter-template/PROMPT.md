# PROMPT — <워크로드명> run

## §build (phase=build 일 때 이 절만 따른다)
1. `adapter/SPEC.md`와 `PROGRESS.md`를 읽어라. PROGRESS의 미완 항목 중 **하나만** 골라 세로 슬라이스로 끝내라
   (테스트 작성 → 구현 → `bash harness/verify.sh` 확인). S1→S2→… 순서 권장.
2. 매 라운드 종료 전 의무: ① `git add -A && git commit` (메시지 접두 `[red]` 또는 `[green]`)
   ② PROGRESS.md 갱신 — 완료 항목 체크 + **다음 라운드 핸드오프 메모 3줄**.
3. verify 실패 시: 테스트 결함인지 제품 결함인지 **먼저 분리**하고 고쳐라.
4. 금지: 답안지(harness/, adapter/, .claude/, protected.txt에 적힌 전부) 수정 ·
   테스트 무력화(skip류) · 새 외부 의존성 추가(TODO: 워크로드에 맞게 구체화) · **완료 선언**
   ("다 했다"고 말하지 마라 — verify.sh가 green이면 하네스가 알아서 멈춘다. 너는 계속 일하면 된다).
5. **보고는 짧게 — 라운드 산문 ≤3줄.** 정중한 서두·요약 반복 금지. 토큰 = 예산이다 (caveman 원칙).
6. 매 라운드 PROGRESS.md 하단의 `### 막힘후보` 절을 갱신하라(없으면 생성): 지금 가장 불확실한
   SPEC 항목 1개 + 네가 택한 해석 + 직전 시도가 실패한 이유 한 줄. 막혔을 때 사람이 이 절을 읽는다.

## §finish (phase=finish 신호를 받으면 이 절만 따른다)
1. **코드 수정 금지** (훅이 차단한다). 할 일: ① `HANDOFF.md` 작성(중단 사유, 마지막 green 태그,
   빨간 이유, 다음 1수) ② `TODO-remaining.md` 작성(미완 SPEC 항목) ③ PROGRESS.md 최종 갱신.
2. 산출물을 다 썼으면 그냥 멈춰라 — 하네스가 종료를 허용한다.

## 계약 토큰 (훅이 키로 삼음 — 이 파일이 prose 근거)
phase 값: `build` | `finish` · 마커: `state/DONE`, `state/BUDGET_EXHAUSTED`, `state/STUCK_ON_COMPLETION`
