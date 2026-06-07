# AS-IS

## 목적
카공지도는 이미 S1~S9 하네스 슬라이스로 코어 동작을 확보했다.
이 문서는 구현된 사실과 사전에 닫힌 제품 판단을 분리해 기록한다.
제품 가치판단은 `/Users/sjwoo/dev/kagong-plan-v1.md`를 출처로 삼고, 실행 상태는 `PROGRESS.md`와 `app/tests/`를 출처로 삼는다.

## 현행 결정
| 항목 | 현행 값 | 출처 |
|---|---|---|
| 스택 | Vite + TypeScript + vitest/jsdom, 새 의존성 없음 | 출처: plan §0, app/package.json |
| 데이터 | 정적 시드 JSON 번들, 외부 API 없음 | 출처: plan §0, app/src/data/cafes.json |
| UI 범위 | 한국어 모바일 우선 단일 페이지 | 출처: plan §0 |
| 지도 | v0.x 범위 밖, Leaflet은 jsdom 검증 불가 | 출처: plan §0, plan §3.3 |
| 기준점 | 홍대입구역 좌표를 거리 계산 원점으로 사용 | 출처: PROGRESS S7, app/src/cafes.ts |
| 점수 공식 | 콘센트 등급, 와이파이, 24시간 여부를 합산 | 출처: plan §0, app/src/cafes.ts |
| 구현 상태 | S1~S9 green, 30개 테스트 통과 기준 | 출처: PROGRESS.md, app/tests |

## 빈 곳
코어 함수와 렌더는 존재하지만 제품 문서는 없었다.
왜 이 앱을 만들고, 누구에게 팔고, 어떤 조건에서 접는지는 S-ID만으로 설명되지 않는다.
그래서 PRD, ERD, FE-SPEC, BE-SPEC, BACKLOG를 분할 박제한다.

## 검산 원칙
시드 파일은 사람 소유 기준선이다.
문서는 시드의 숫자를 직접 답안처럼 외우지 않고 측정방법과 출처를 적는다.
체커는 파일 존재, 내용 구조, 실행 검산을 모두 통과해야 green으로 본다.
