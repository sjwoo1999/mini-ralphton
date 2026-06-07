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

/** 점수 내림차순 정렬, 동점은 id 오름차순. 입력 불변(새 배열 반환). */
export function sortByScore(list: Cafe[]): Cafe[] {
  return [...list].sort((a, b) => score(b) - score(a) || a.id.localeCompare(b.id))
}
