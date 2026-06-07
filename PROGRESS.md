# PROGRESS — 카공지도 v0.1

## 상태
- [x] **S1** 데이터 로드·렌더 — `src/cafes.ts`(타입+시드 번들), `src/render.ts`(renderCafeList), `src/main.ts`. 시드 10곳 DOM 렌더 + 번들=골든 대조. green.
- [x] **S2** 콘센트 필터 — `filterByOutlets(list,min)` + `OUTLET_RANK`(many3>some2>few1). many=4곳 단언 green.
- [x] **S3** 복합 필터 — `filterByWifiAndOpen24h(list)`. c03,c06,c09=3 단언 green.
- [ ] S4 공부적합도 점수 + 내림차순 정렬 (1위 c03)

## 핸드오프 메모
- 데이터는 `src/data/cafes.json`(시드 사본, 내용 동일). `src/cafes.ts`의 `cafes`로 노출.
- 렌더는 `<li data-cafe-id>` 단위 — 필터 슬라이스는 필터된 배열을 `renderCafeList`에 넘기면 됨.
- 다음 1수: S4 — `score(cafe)` 순수함수 + `sortByScore(list)` 내림차순, 동점 id 오름차순. 1위 c03. 태그 `[S4]`.

### 막힘후보
- 가장 불확실: S4 동점 타이브레이크 "id 오름차순" — 안정정렬 보장 위해 비교함수에 id 2차키 명시 예정. 직전 실패: 없음(S2 green).
