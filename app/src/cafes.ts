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
