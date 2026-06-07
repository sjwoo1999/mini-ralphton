import { describe, expect, it, beforeEach } from 'vitest'
import { getFavorites } from '../src/favorites'
import { mountKagongApp } from '../src/ui'

function ids(root: HTMLElement): string[] {
  return [...root.querySelectorAll('[data-cafe-id]')].map(el => el.getAttribute('data-cafe-id')!)
}

describe('[spec-12] 즐겨찾기 필터 뷰', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('c01/c05 토글 → 즐겨찾기 뷰는 [c01,c05]만 렌더', () => {
    const root = document.createElement('div')
    mountKagongApp(root)

    root.querySelector<HTMLButtonElement>('[data-fav-id="c01"]')!.click()
    root.querySelector<HTMLButtonElement>('[data-fav-id="c05"]')!.click()
    root.querySelector<HTMLButtonElement>('[data-favorites-only]')!.click()

    expect(getFavorites()).toEqual(['c01', 'c05'])
    expect(ids(root)).toEqual(['c01', 'c05'])
    expect(root.querySelector('[data-filter-summary]')!.textContent).toBe('즐겨찾기 · 2곳')
  })

  it('토글 해제 후 즐겨찾기 뷰에서 해당 id가 사라짐', () => {
    const root = document.createElement('div')
    mountKagongApp(root)

    root.querySelector<HTMLButtonElement>('[data-fav-id="c01"]')!.click()
    root.querySelector<HTMLButtonElement>('[data-fav-id="c05"]')!.click()
    root.querySelector<HTMLButtonElement>('[data-favorites-only]')!.click()
    root.querySelector<HTMLButtonElement>('[data-fav-id="c01"]')!.click()

    expect(getFavorites()).toEqual(['c05'])
    expect(ids(root)).toEqual(['c05'])
  })
})
