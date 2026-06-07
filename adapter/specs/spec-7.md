# SPEC — 카공지도 v0.7: 검색 0건 빈 상태 누적 (기계 계약: harness/ADAPTER-CONTRACT.md §3)

> 제품: "카페에서 공부하기 좋은 곳"을 찾는 지도 앱. v0.1은 지도 없이 **목록+필터 코어 로직**만 (지도는 BACKLOG 항목2).
> 데이터 = `app/tests/protected/cafes.seed.json` (골든, 수정 금지) — 앱은 같은 스키마의 데이터를 `src/data/cafes.json`으로 두고 번들한다(내용은 시드와 동일해야 하며 테스트가 대조).

## 기계 판정 체크리스트
- [S1] 데이터 로드·렌더: `src/`에 카페 목록 컴포넌트 — 시드 10곳 전부를 이름·좌석수와 함께 DOM 목록으로 렌더 (테스트: jsdom에서 컨테이너에 10개 항목, 각 항목에 name 텍스트 존재)
- [S2] 콘센트 필터: `outlets` 필터(many/some/few 최소등급 선택) 적용 시 목록이 정확히 그 부분집합으로 갱신 — 시드 기준 many=4곳 단언 포함
- [S3] 복합 필터: wifi=true AND open24h=true 교집합 — 시드 기준 정확히 3곳(c03,c06,c09) 단언
- [S4] 공부적합도 점수: `score(cafe) = outlets등급(many3/some2/few1) + wifi(1) + open24h(1)` 순수함수 + 목록이 점수 내림차순 정렬 — 동점은 id 오름차순 타이브레이크, 시드 기준 1위 c03 단언

- [S5] 이름 검색: 입력 문자열 부분일치(대소문자 무시)로 목록 필터 — "카페" 검색 시 시드 기준 3곳(c01·c03·c06) 단언
- [S6] 점수 배지: 각 목록 항목에 S4 점수를 "공부적합 N점" 텍스트로 표시 — c03 항목에 "5점" 단언

- [S7] 거리순 정렬: `haversine(a,b)` km 순수함수 + `sortByDistance(list, origin)`. 기준점 = 홍대입구역 `(37.5572, 126.9245)` 고정 — 단언: 1위 c04(브루웍스 홍대, ~0.47km)·2위 c05·3위 c01, c04 거리 0.4~0.6km 범위, 동점은 id 오름차순

- [S8] 즐겨찾기: localStorage 키 `kagong:favorites` — `toggleFavorite(id)`/`getFavorites()`/`isFavorite(id)` + 목록 항목에 ★ 토글 표시. 단언: 토글→포함·재토글→제거·**새 인스턴스가 localStorage에서 복원**·미저장 시 `[]`. 테스트는 beforeEach에서 `localStorage.clear()` 필수(누수 flaky 방지)

- [S9] 좌석규모 필터: `seats >= 50` "대형" 필터 — 단언: 시드 기준 정확히 3곳 `c03·c06·c07` (id 집합 일치)

- [S10] 등급 배지: `tier(score)` 순수함수 — 5점=S / 4점=A / 3점 이하=B. 목록 항목에 "[S]"류 배지 표시. 단언: 시드 기준 S={c03,c06}·A={c01,c07,c09}·B=5곳 (집합 일치) + c03 항목에 S배지 DOM 존재

- [S11] 검색 0건: 결과 없는 검색어(예 "없는카페xyz") 시 목록 0개 + `결과 없음` 안내 노드 표시 — 단언: empty 노드 존재·목록 자식 0·검색어 지우면 10곳 복원

## 가정 — 루프가 택한 해석 (S-ID 없음, 사람이 ‹CONFIRM›으로 닫음)
- [A1] 스택: Vite+TS+vitest/jsdom (1호 GPX 동일 — 앱 셸 제공됨). 지도(Leaflet)는 v0.1 범위 밖, jsdom 렌더 테스트 금지(1호 교훈) ‹CONFIRM›
- [A2] 데이터는 시드 JSON 정적 번들 — 실데이터 수집·외부 API는 후속 항목 ‹CONFIRM›
- [A3] UI 한국어, 모바일 우선 단일 페이지 ‹CONFIRM›
- [A4] outlets 등급 서열: many > some > few ‹CONFIRM›
