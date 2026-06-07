# PROGRESS — 카공지도 v0.1

## 상태
- [x] **S1** 데이터 로드·렌더 — `src/cafes.ts`(타입+시드 번들), `src/render.ts`(renderCafeList), `src/main.ts`. 시드 10곳 DOM 렌더 + 번들=골든 대조. green.
- [ ] S2 콘센트 필터 (many=4)
- [ ] S3 복합 필터 wifi∧open24h (c03,c06,c09=3)
- [ ] S4 공부적합도 점수 + 내림차순 정렬 (1위 c03)

## 핸드오프 메모
- 데이터는 `src/data/cafes.json`(시드 사본, 내용 동일). `src/cafes.ts`의 `cafes`로 노출.
- 렌더는 `<li data-cafe-id>` 단위 — 필터 슬라이스는 필터된 배열을 `renderCafeList`에 넘기면 됨.
- 다음 1수: S2 — `filterByOutlets(list, min)` 순수함수(many>some>few 서열, min 이상). 테스트 태그 `[S2]` 필수.

### 막힘후보
- 가장 불확실: S2 "최소등급" 해석 → outlets 서열 many=3>some=2>few=1, min 이상 포함으로 택함(A4 근거). 직전 실패: 없음(S1 첫 green).
