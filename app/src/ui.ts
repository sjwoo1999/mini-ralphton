import {
  cafes,
  filterByName,
  filterByOutlets,
  HONGDAE_STATION,
  sortByDistance,
  sortByScore,
  type Cafe,
  type Outlets,
} from './cafes'
import { renderCafeList } from './render'

export type SortMode = 'score' | 'distance'
export type OutletFilter = 'all' | Outlets

export interface CafeUiState {
  outlets: OutletFilter
  query: string
  sort: SortMode
}

export const DEFAULT_UI_STATE: CafeUiState = {
  outlets: 'all',
  query: '',
  sort: 'score',
}

export function getVisibleCafes(list: Cafe[], state: CafeUiState): Cafe[] {
  let result = list
  if (state.outlets !== 'all') result = filterByOutlets(result, state.outlets)
  result = filterByName(result, state.query)
  return state.sort === 'distance' ? sortByDistance(result, HONGDAE_STATION) : sortByScore(result)
}

export function summarizeFilters(state: CafeUiState, count: number): string {
  const parts: string[] = []
  if (state.outlets === 'many') parts.push('콘센트 많음')
  else if (state.outlets === 'some') parts.push('콘센트 보통 이상')
  else if (state.outlets === 'few') parts.push('콘센트 전체 등급')
  if (state.query.trim()) parts.push(`검색 ${state.query.trim()}`)
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

  controls.append(outletSelect, searchInput, scoreButton, distanceButton)

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

  root.append(heading, summary, controls, listRoot)
  render()
}
