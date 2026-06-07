# FE-SPEC

## 3.1 화면 구조
카공지도는 단일 페이지 앱이다.
모바일 우선 리스트가 기본이며, 지도 렌더링은 현재 범위에서 제외한다.
첫 화면은 카페 카드를 보여주고, 사용자는 필터와 정렬로 후보를 좁힌다.
모든 F#는 정확히 하나의 G#를 인용한다.
jsdom으로 검증 가능한 것만 F#에 배정한다.

```text
[헤더: 카공지도 + 활성 필터 요약]
[필터바: 콘센트 / 와이파이 / 24시간 / 좌석 / 검색]
[정렬 토글: 점수순 / 거리순]
[카페 리스트: 카드 반복]
  - 이름
  - 공부적합 점수 배지
  - 점수 분해
  - 즐겨찾기 버튼
```

## 3.2 컴포넌트 추적표
| 추적 | 항목 | jsdom 단언 | 상태 |
|---|---|---|---|
| F1 ← G1 | 카페 리스트 렌더 | `<li data-cafe-id>`가 시드 전체를 렌더하고 각 name, seats 텍스트가 존재 | 구현됨 spec-1 S1 |
| F2 ← G2 | 필터바 UI 배선 | 콘센트, 와이파이, 24시간, 좌석 입력 이벤트가 리스트 부분집합을 갱신 | 구현됨 spec-9 |
| F3 ← G3 | 검색 입력 배선 | 검색어 입력 이벤트가 이름 부분검색 결과를 리스트에 반영 | 구현됨 spec-9 |
| F4 ← G1 | 정렬 토글 | 점수순과 거리순 토글이 첫 항목 id를 결정적으로 바꿈 | 구현됨 spec-9 |
| F5 ← G5 | 활성 필터 요약 | 현재 적용 조건과 결과 수가 헤더 텍스트로 표시 | 구현됨 spec-10 |
| F6 ← G1 | 점수 배지 | `.cafe-score`에 `공부적합 N점` 형식이 표시 | 구현됨 spec-6 S6 |
| F7 ← G4 | 즐겨찾기 토글 버튼 | `.cafe-fav` 클릭이 `aria-pressed`와 localStorage를 갱신 | 구현됨 spec-8 S8 |
| F8 ← G5 | 점수 분해 표시 | 카드에 콘센트, 와이파이, 24시간, 좌석 판단 노드가 분리 표시 | 구현됨 spec-8 |

## 3.3 구현됨 표기 근거
F1은 `app/tests/s1.render.spec.ts`가 `data-cafe-id` 렌더와 텍스트 존재를 검증한다.
F2, F3, F4는 `app/tests/spec9.wiring.spec.ts`가 select, input, sort button 이벤트와 골든 id 집합을 검증한다.
F5는 `app/tests/spec10.summary.spec.ts`가 `data-filter-summary` 텍스트와 결과 수를 검증한다.
F6은 `app/tests/s6.badge.spec.ts`가 `.cafe-score`와 공부적합 문구를 검증한다.
F7은 `app/tests/s8.favorites.spec.ts`가 `.cafe-fav`, `aria-pressed`, localStorage 반영을 검증한다.
F8은 `app/tests/spec8.breakdown.spec.ts`가 `data-score-part`와 `data-score-sum`을 검증한다.
spec-11은 `app/tests/spec11.night.spec.ts`가 심야 프리셋 버튼과 완전 특성화를 검증한다.
spec-12는 `app/tests/spec12.favview.spec.ts`가 즐겨찾기 뷰와 localStorage 집합 일치를 검증한다.

## 3.4 jsdom 검증 경계
jsdom은 DOM 노드, 텍스트, 이벤트, localStorage를 검증할 수 있다.
그래서 리스트 렌더, 점수 배지, 즐겨찾기 토글은 자동 검증 대상이다.
지도 이동, 타일 로딩, 실제 모바일 스크롤 감각은 jsdom 범위가 아니다.
검증 불가능한 항목을 구현됨으로 표기하지 않는다.

## 3.5 사람 눈 검수
Leaflet 지도 품질, 모바일 반응형 여백, 60fps 체감, 색 대비는 사람 눈 검수 칸에 둔다.
이 칸은 F#를 부여하지 않는다.
자동 체커가 볼 수 없는 것을 자동 green으로 주장하지 않는다.
