# PROGRESS — 카공지도 v0.5

## 상태
- [x] **S1** 데이터 로드·렌더 — `src/cafes.ts`(타입+시드 번들), `src/render.ts`(renderCafeList), `src/main.ts`. 시드 10곳 DOM 렌더 + 번들=골든 대조. green.
- [x] **S2** 콘센트 필터 — `filterByOutlets(list,min)` + `OUTLET_RANK`(many3>some2>few1). many=4곳 단언 green.
- [x] **S3** 복합 필터 — `filterByWifiAndOpen24h(list)`. c03,c06,c09=3 단언 green.
- [x] **S4** 공부적합도 점수 — `score(cafe)` 순수함수 + `sortByScore` 내림차순(동점 id 오름차순). 1위 c03 단언 green. `main.ts`가 점수순 기본 렌더.
- [x] **S5** 이름 검색 — `filterByName(list,query)` trim→toLowerCase→includes. 공백/빈문자열은 전체 반환. "카페"=c01·c03·c06=3 단언 green.
- [x] **S6** 점수 배지 — `render.ts`가 `score(cafe)`로 `<span class="cafe-score">공부적합 N점</span>` 출력. c03="공부적합 5점" 단언 green.
- [x] **S7** 거리순 정렬 — `haversine(a,b)` km 순수함수 + `sortByDistance(list, origin)`(오름차순, 동점 id). 기준점 `HONGDAE_STATION=(37.5572,126.9245)`. 1위 c04(0.467km)·2위 c05·3위 c01, c04 0.4~0.6km 단언 green.
- [x] **S8** 즐겨찾기 — `src/favorites.ts`: `toggleFavorite(id)`/`getFavorites()`/`isFavorite(id)` + `FAVORITES_KEY='kagong:favorites'`. localStorage 단일 진실원(인메모리 캐시 없음 → 새 인스턴스 자동 복원). render에 `.cafe-fav` ★/☆ 버튼(`aria-pressed`) 자동 부착. 토글/재토글/복원/미저장[]/깨진값 폴백 단언 green.
- [x] **S9** 좌석규모 필터 — `src/cafes.ts`: `filterByLargeSeats(list)` + `LARGE_SEATS_MIN=50`(포함 경계). 시드 기준 "대형"(seats>=50)=c03·c06·c07 정확히 3곳 id집합 단언 + 임계값 off-by-one 회귀(c07=52 포함·c01=48 제외) green. 임계값을 데이터가 아닌 술어 상수로 둠(골든 정책-free 유지).

## 핸드오프 메모
- 데이터는 `src/data/cafes.json`(시드 사본, 내용 동일). `src/cafes.ts`의 `cafes`로 노출. 점수 단일 진실원 = `score()`, 거리 단일 진실원 = `haversine()`(sortByDistance가 재계산 안 하고 compose).
- 렌더는 `<li data-cafe-id>` 단위 — 정렬/필터 슬라이스는 결과 배열을 `renderCafeList`에 넘기면 됨. 배지(S6)·★토글(S8)은 모든 항목에 자동 부착. render가 `isFavorite()`를 항목마다 호출(localStorage 라이브 read).
- 즐겨찾기 영속 = localStorage가 곧 상태. 함수는 매 호출 라이브 read/write-through → 재로드·다중 인스턴스 desync 없음. 깨진 JSON/비배열은 `[]` 폴백.
- 다음 1수: SPEC v0.5(S1-S9) 전부 단언 green(30/30). 후속은 BACKLOG(지도 항목2, 검색·정렬·★토글·필터 클릭 UI 배선) — main.ts는 아직 입력/토글 이벤트 미배선(코어 로직만). 좌석필터 UI 배선 시 `filterByLargeSeats` 토글 체크박스 → 결과배열 `renderCafeList`. 필터 합성(검색∩대형∩…)은 결과배열을 순차 compose하면 됨.

### 막힘후보
- 가장 불확실: S9 "대형" 임계값의 경계 의미 — `seats >= 50`(포함)으로 해석(c07=52 포함, c01=48 제외 → 정확히 3곳). SPEC가 id집합(c03·c06·c07)을 못박아 경계 모호성 없음. 택한 해석: 임계값=술어 상수(`LARGE_SEATS_MIN`), 데이터 정책-free. 직전 실패: 없음(첫 red는 함수/상수 미존재 import undefined, 구현 후 30/30 green).
