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
