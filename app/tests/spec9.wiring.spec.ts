import { describe, expect, it, beforeEach } from 'vitest'
import { mountKagongApp } from '../src/ui'

function ids(root: HTMLElement): string[] {
  return [...root.querySelectorAll('[data-cafe-id]')].map(el => el.getAttribute('data-cafe-id')!)
}

describe('[spec-9] 입력 배선 (F2/F3/F4)', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('콘센트 select=many change → many 골든 집합만 렌더', () => {
    const root = document.createElement('div')
    mountKagongApp(root)

    const select = root.querySelector<HTMLSelectElement>('[data-filter-outlets]')!
    select.value = 'many'
    select.dispatchEvent(new Event('change'))

    expect(ids(root).sort()).toEqual(['c01', 'c03', 'c06', 'c07'])
  })

  it('검색 input "카페" → 이름 골든 집합만 렌더', () => {
    const root = document.createElement('div')
    mountKagongApp(root)

    const input = root.querySelector<HTMLInputElement>('[data-search]')!
    input.value = '카페'
    input.dispatchEvent(new Event('input'))

    expect(ids(root).sort()).toEqual(['c01', 'c03', 'c06'])
  })

  it('점수순 정렬 클릭 → 첫 항목 c03, 동점 상위 2개 c03/c06', () => {
    const root = document.createElement('div')
    mountKagongApp(root)

    root.querySelector<HTMLButtonElement>('[data-sort-distance]')!.click()
    expect(ids(root)[0]).toBe('c04')

    root.querySelector<HTMLButtonElement>('[data-sort-score]')!.click()
    expect(ids(root)[0]).toBe('c03')
    expect(ids(root).slice(0, 2)).toEqual(['c03', 'c06'])
  })
})
