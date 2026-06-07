# PROGRESS — 카공지도 v0.1

## 상태
- [x] **S1** 데이터 로드·렌더 — `src/cafes.ts`(타입+시드 번들), `src/render.ts`(renderCafeList), `src/main.ts`. 시드 10곳 DOM 렌더 + 번들=골든 대조. green.
- [x] **S2** 콘센트 필터 — `filterByOutlets(list,min)` + `OUTLET_RANK`(many3>some2>few1). many=4곳 단언 green.
- [x] **S3** 복합 필터 — `filterByWifiAndOpen24h(list)`. c03,c06,c09=3 단언 green.
- [x] **S4** 공부적합도 점수 — `score(cafe)` 순수함수 + `sortByScore` 내림차순(동점 id 오름차순). 1위 c03 단언 green. `main.ts`가 점수순 기본 렌더.

## 핸드오프 메모
- 데이터는 `src/data/cafes.json`(시드 사본, 내용 동일). `src/cafes.ts`의 `cafes`로 노출.
- 렌더는 `<li data-cafe-id>` 단위 — 필터 슬라이스는 필터된 배열을 `renderCafeList`에 넘기면 됨.
- 다음 1수: S1-S4 전부 green. verify GREEN 확인 후 캠페인은 BACKLOG spec-2(v0.2 검색·점수배지 S5-S6)로 진행 가능.

### 막힘후보
- 가장 불확실: 없음 — S1-S4 전부 단언 green. localeCompare로 id 오름차순 타이브레이크 명시(안정정렬 비의존). 직전 실패: 없음.
