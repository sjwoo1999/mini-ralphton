# PROGRESS — 카공지도 v0.2

## 상태
- [x] **S1** 데이터 로드·렌더 — `src/cafes.ts`(타입+시드 번들), `src/render.ts`(renderCafeList), `src/main.ts`. 시드 10곳 DOM 렌더 + 번들=골든 대조. green.
- [x] **S2** 콘센트 필터 — `filterByOutlets(list,min)` + `OUTLET_RANK`(many3>some2>few1). many=4곳 단언 green.
- [x] **S3** 복합 필터 — `filterByWifiAndOpen24h(list)`. c03,c06,c09=3 단언 green.
- [x] **S4** 공부적합도 점수 — `score(cafe)` 순수함수 + `sortByScore` 내림차순(동점 id 오름차순). 1위 c03 단언 green. `main.ts`가 점수순 기본 렌더.
- [x] **S5** 이름 검색 — `filterByName(list,query)` trim→toLowerCase→includes. 공백/빈문자열은 전체 반환. "카페"=c01·c03·c06=3 단언 green.
- [x] **S6** 점수 배지 — `render.ts`가 `score(cafe)`로 `<span class="cafe-score">공부적합 N점</span>` 출력. c03="공부적합 5점" 단언 green.

## 핸드오프 메모
- 데이터는 `src/data/cafes.json`(시드 사본, 내용 동일). `src/cafes.ts`의 `cafes`로 노출. 점수 단일 진실원 = `score()`(render도 import해 재계산 안 함).
- 렌더는 `<li data-cafe-id>` 단위 — 필터 슬라이스는 필터된 배열을 `renderCafeList`에 넘기면 됨. 배지(S6)는 모든 항목에 자동 부착.
- 다음 1수: SPEC v0.2(S1-S6) 전부 단언 green. 후속은 BACKLOG(지도 항목2, 검색 UI 입력박스 배선 등)로 진행 가능 — main.ts는 아직 검색 input 미배선(코어 로직만).

### 막힘후보
- 가장 불확실: 없음 — S1-S6 전부 단언 green. S5 "카페"가 c06 "카페인"을 부분일치로 잡는지(단어경계 아님) 확인됨. 직전 실패: 없음.
