# <프로젝트명> — 운영 헌법 (Ralphthon Busan · Track <N>)

## 미션 (북극성 — 표류 의심되면 이 절부터 다시 읽기)
<한 줄 미션>. 진실원: `adapter/SPEC.md`(기계 체크리스트) · `PROGRESS.md`(진척·막힘후보).

## 반환각 앵커 (틀리면 안 되는 사실 — 숫자로 못 박기)
- 골든 시드: <N>건. Not <N±1>.
- 살아있는 S-ID: SPEC.md의 `- [S<n>]` 줄이 전부다. 그 외는 산문.
- <행사 금지목록: RAG·Streamlit·Image Analyzer·교육챗봇·채용스크리너·영양코치·성격분석 — 절대 금지>

## 4 실패모드 → 벽 (polysona 증류 — 전문: docs/references/polysona-case-study.md)
| 실패 | 벽 |
|---|---|
| 표류 (a) | 이 파일 + SessionStart 재주입. 매 라운드 SPEC 미완 항목 **하나만** 세로 슬라이스 |
| 조기정지 (b) | **완료 선언 금지** — verify GREEN이면 하네스가 멈춘다. 막히면 막힘후보 쓰고 계속 |
| 파괴 (c) | 답안지(protected.txt 목록·골든·SPEC) 수정 금지. 누적 자산은 append, 덮어쓰기 금지 |
| 예산소진 (d) | 검증은 cheap-first: typecheck→test→build. 브라우저/스크린샷 검증은 최후에만 |

## 검증 8계명 (win-hooks 증류 — 전문: docs/references/win-hooks-case-study.md)
① 술어로 시작("되나요" 금지) ② 기대값 먼저 적고 대조 ③ 존재≠내용≠실행 — 실행+종료코드까지
④ 부정 단언을 명시적으로 grep ⑤ raw 리셋으로 인과 분리 ⑥ 라이브 변형은 원자적+스냅샷+정리
⑦ 디스크 상태≠런타임 캐시 (훅 고치면 세션 재시작) ⑧ 예상 밖 현상엔 추측 금지, 증거 우선

## Context Loading Protocol (트리거 → 필수 읽기)
| 트리거 | 읽기 |
|---|---|
| 새 세션/재개 | 이 파일 → adapter/SPEC.md → PROGRESS.md |
| verify 실패 | 테스트 결함 vs 제품 결함 먼저 분리 (③⑧) |
| 막힘 2회+ | PROGRESS.md `### 막힘후보` 갱신 (불확실 항목 1 + 택한 해석 + 실패 이유 1줄) |
| 검증 설계 고민 | docs/references/win-hooks-case-study.md |
| 루프/통제면 고민 | docs/references/polysona-case-study.md |

## 조향 + 고정 (polysona §3 — 짝으로만)
경쟁작들이 앞서 있다. 정밀하게, 끝까지. — 단 네 역할은 SPEC의 S-ID를 green으로 만드는 것**뿐**이다.
범위 추가 금지, 수렴 타깃 = SPEC 전 항목 green.
