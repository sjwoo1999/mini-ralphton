import {
  cafes,
  filterByName,
  filterNightStudyPreset,
  filterByOutlets,
  HONGDAE_STATION,
  sortByDistance,
  sortByScore,
  type Cafe,
  type Outlets,
} from './cafes'
import { renderCafeList } from './render'
import { getFavorites, toggleFavorite } from './favorites'

export type SortMode = 'score' | 'distance'
export type OutletFilter = 'all' | Outlets

export interface CafeUiState {
  outlets: OutletFilter
  query: string
  sort: SortMode
  nightPreset: boolean
  favoritesOnly: boolean
}

export const DEFAULT_UI_STATE: CafeUiState = {
  outlets: 'all',
  query: '',
  sort: 'score',
  nightPreset: false,
  favoritesOnly: false,
}

export function getVisibleCafes(list: Cafe[], state: CafeUiState): Cafe[] {
  let result = list
  if (state.nightPreset) result = filterNightStudyPreset(result)
  if (state.outlets !== 'all') result = filterByOutlets(result, state.outlets)
  result = filterByName(result, state.query)
  if (state.favoritesOnly) {
    const favoriteIds = new Set(getFavorites())
    result = result.filter(c => favoriteIds.has(c.id))
  }
  return state.sort === 'distance' ? sortByDistance(result, HONGDAE_STATION) : sortByScore(result)
}

export function summarizeFilters(state: CafeUiState, count: number): string {
  const parts: string[] = []
  if (state.outlets === 'many') parts.push('콘센트 많음')
  else if (state.outlets === 'some') parts.push('콘센트 보통 이상')
  else if (state.outlets === 'few') parts.push('콘센트 전체 등급')
  if (state.query.trim()) parts.push(`검색 ${state.query.trim()}`)
  if (state.nightPreset) parts.push('심야 카공')
  if (state.favoritesOnly) parts.push('즐겨찾기')
  if (parts.length === 0) return `전체 ${count}곳`
  return `${parts.join(' · ')} · ${count}곳`
}

export function mountKagongApp(root: HTMLElement): void {
  const state: CafeUiState = { ...DEFAULT_UI_STATE }
  root.replaceChildren()

  const heading = document.createElement('h1')
  heading.textContent = '카공지도'

  const controls = document.createElement('section')
  controls.setAttribute('aria-label', '카공지도 필터')

  const summary = document.createElement('p')
  summary.setAttribute('data-filter-summary', '')

  const outletSelect = document.createElement('select')
  outletSelect.setAttribute('data-filter-outlets', '')
  for (const [value, label] of [
    ['all', '콘센트 전체'],
    ['many', '콘센트 많음'],
    ['some', '콘센트 보통 이상'],
    ['few', '콘센트 전체 등급'],
  ] as const) {
    const option = document.createElement('option')
    option.value = value
    option.textContent = label
    outletSelect.appendChild(option)
  }

  const searchInput = document.createElement('input')
  searchInput.type = 'search'
  searchInput.placeholder = '카페 검색'
  searchInput.setAttribute('data-search', '')

  const scoreButton = document.createElement('button')
  scoreButton.type = 'button'
  scoreButton.setAttribute('data-sort-score', '')
  scoreButton.textContent = '점수순'

  const distanceButton = document.createElement('button')
  distanceButton.type = 'button'
  distanceButton.setAttribute('data-sort-distance', '')
  distanceButton.textContent = '거리순'

  const nightButton = document.createElement('button')
  nightButton.type = 'button'
  nightButton.setAttribute('data-night-preset', '')
  nightButton.textContent = '심야 카공'

  const favoritesButton = document.createElement('button')
  favoritesButton.type = 'button'
  favoritesButton.setAttribute('data-favorites-only', '')
  favoritesButton.textContent = '즐겨찾기'

  controls.append(outletSelect, searchInput, scoreButton, distanceButton, nightButton, favoritesButton)

  const listRoot = document.createElement('div')
  listRoot.setAttribute('data-list-root', '')

  const render = () => {
    const visible = getVisibleCafes(cafes, state)
    summary.textContent = summarizeFilters(state, visible.length)
    renderCafeList(listRoot, visible)
  }

  outletSelect.addEventListener('change', () => {
    state.outlets = outletSelect.value as OutletFilter
    render()
  })
  searchInput.addEventListener('input', () => {
    state.query = searchInput.value
    render()
  })
  scoreButton.addEventListener('click', () => {
    state.sort = 'score'
    render()
  })
  distanceButton.addEventListener('click', () => {
    state.sort = 'distance'
    render()
  })
  nightButton.addEventListener('click', () => {
    state.nightPreset = !state.nightPreset
    nightButton.setAttribute('aria-pressed', String(state.nightPreset))
    render()
  })
  favoritesButton.addEventListener('click', () => {
    state.favoritesOnly = !state.favoritesOnly
    favoritesButton.setAttribute('aria-pressed', String(state.favoritesOnly))
    render()
  })
  listRoot.addEventListener('click', event => {
    const button = (event.target as Element).closest<HTMLButtonElement>('[data-fav-id]')
    if (!button) return
    toggleFavorite(button.dataset.favId!)
    render()
  })

  root.append(heading, summary, controls, listRoot)
  render()
}
