import data from './data/cafes.json'

export type Outlets = 'many' | 'some' | 'few'

export interface Cafe {
  id: string
  name: string
  lat: number
  lng: number
  outlets: Outlets
  wifi: boolean
  open24h: boolean
  seats: number
}

export const cafes: Cafe[] = data as Cafe[]

/** 콘센트 등급 서열 (A4: many > some > few). 점수·필터 공용 단일 진실원. */
export const OUTLET_RANK: Record<Outlets, number> = { many: 3, some: 2, few: 1 }

/** 최소 콘센트 등급 이상인 카페만. min='many'면 many만, 'few'면 전부. */
export function filterByOutlets(list: Cafe[], min: Outlets): Cafe[] {
  return list.filter(c => OUTLET_RANK[c.outlets] >= OUTLET_RANK[min])
}

/** wifi ∧ open24h 교집합 (밤샘 공부 적합). */
export function filterByWifiAndOpen24h(list: Cafe[]): Cafe[] {
  return list.filter(c => c.wifi && c.open24h)
}

/** "대형" 좌석규모 임계값 (S9: 50석 이상, 포함 경계). 필터 정책 단일 진실원. */
export const LARGE_SEATS_MIN = 50

/** 좌석 LARGE_SEATS_MIN석 이상인 "대형" 카페만. 시드 기준 c03·c06·c07. */
export function filterByLargeSeats(list: Cafe[]): Cafe[] {
  return list.filter(c => c.seats >= LARGE_SEATS_MIN)
}

/** 이름 부분일치 검색(대소문자 무시). 공백뿐이면 필터 해제(전체 반환). */
export function filterByName(list: Cafe[], query: string): Cafe[] {
  const q = query.trim().toLowerCase()
  if (q === '') return list
  return list.filter(c => c.name.toLowerCase().includes(q))
}

/** 공부적합도 점수 = 콘센트등급(many3/some2/few1) + wifi(1) + open24h(1). 순수함수. */
export function score(cafe: Cafe): number {
  return OUTLET_RANK[cafe.outlets] + (cafe.wifi ? 1 : 0) + (cafe.open24h ? 1 : 0)
}

export interface ScoreBreakdown {
  outlets: number
  wifi: number
  open24h: number
  sum: number
}

/** 점수 설명용 구성요소. 합계는 score(cafe)와 같아야 한다. */
export function scoreBreakdown(cafe: Cafe): ScoreBreakdown {
  const outlets = OUTLET_RANK[cafe.outlets]
  const wifi = cafe.wifi ? 1 : 0
  const open24h = cafe.open24h ? 1 : 0
  return { outlets, wifi, open24h, sum: outlets + wifi + open24h }
}

/** 점수 내림차순 정렬, 동점은 id 오름차순. 입력 불변(새 배열 반환). */
export function sortByScore(list: Cafe[]): Cafe[] {
  return [...list].sort((a, b) => score(b) - score(a) || a.id.localeCompare(b.id))
}

/** 위경도 좌표 (카페·기준점 공용 최소 형태). */
export interface LatLng {
  lat: number
  lng: number
}

/** 기준점 = 홍대입구역 (SPEC v0.3 [S7] 고정). */
export const HONGDAE_STATION: LatLng = { lat: 37.5572, lng: 126.9245 }

/**
 * 두 좌표 사이 대권거리(km). 평면근사 아님 — 위경도를 라디안화해 구면 코사인 공식의
 * 수치 안정 변형(haversine)으로 계산. 같은 점은 0, 대칭. 순수함수.
 */
export function haversine(a: LatLng, b: LatLng): number {
  const R = 6371.0088 // 지구 평균반경(km). 정렬은 비율 불변이라 값만 영향.
  const toRad = (d: number) => (d * Math.PI) / 180
  const dLat = toRad(b.lat - a.lat)
  const dLng = toRad(b.lng - a.lng)
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(a.lat)) * Math.cos(toRad(b.lat)) * Math.sin(dLng / 2) ** 2
  return 2 * R * Math.asin(Math.sqrt(h))
}

/** 기준점에서 가까운 순(오름차순) 정렬, 동점은 id 오름차순. 입력 불변(새 배열 반환). */
export function sortByDistance(list: Cafe[], origin: LatLng): Cafe[] {
  return [...list].sort(
    (a, b) => haversine(origin, a) - haversine(origin, b) || a.id.localeCompare(b.id),
  )
}
