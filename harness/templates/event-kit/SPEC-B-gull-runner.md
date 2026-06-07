# SPEC B — 부산 갈매기 러너 (codex-ralph가 무인으로 깎는 데모 워크로드)

## 불변 규칙
- 답안지: 이 SPEC + 골든값. 수정 금지. 에셋은 이모지/CSS만(이미지 생성 모델 안 씀 — Track 2 아님).
- 스택: Vite+TS+vitest/jsdom (검증된 패턴). 새 npm 의존성 추가 금지.

## 판정 방식
vitest 테스트명 `[S#]` 태그 → green_set 추출 (1호 GPX 패턴). 골든값은 아래에 박제 — **전부 검산 완료**.

## 기계 체크리스트
- [S1] 점프 물리 `jump(t)`: 포물선 y(t)=4H·(t/T)·(1−t/T), T=60틱·H=80px — 골든 3점: y(0)=0 · y(30)=80 · y(60)=0
- [S2] 충돌 판정 AABB `hit(a,b)`: 겹침=true · 떨어짐=false · **모서리 맞닿음(경계)=false** — 3골든
- [S3] 점수 `score(passed, ticks)` = passed×10 + floor(ticks/60) — 골든: (3, 300) → 35
- [S4] 상태머신: ready→(스페이스)→playing→(충돌)→gameover→(스페이스)→ready — 전이 4단언 + 불법 전이(ready→gameover 직행) 거부
- [S5] DOM 렌더(jsdom): 갈매기(🕊️)·장애물·점수 노드 존재 + gameover 시 "다시 도전" 노드
- [S6] 입력·루프: 스페이스 keydown → playing에서 점프 트리거, gameover에서 리셋 — 이벤트 단언

## 가정 — 사람이 닫는다
- [A1] 장애물 = 오륙도 바위(🪨)·등대(🗼) 이모지, 배경 타이틀 "부산 갈매기" (Track 3 양념) ‹CONFIRM›
- [A2] 난이도·속도 상수는 루프 재량 (게임성은 골든 비대상 — 물리·점수·전이만 기계 판정) ‹CONFIRM›
- [A3] 시각 폴리시(60fps 부드러움 등)는 데모 직전 사람 눈 검수 1회 ‹CONFIRM›
