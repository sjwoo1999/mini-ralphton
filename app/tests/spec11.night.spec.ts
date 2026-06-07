import { describe, expect, it, beforeEach } from 'vitest'
import { cafes, filterNightStudyPreset } from '../src/cafes'
import { mountKagongApp } from '../src/ui'

function ids(root: HTMLElement): string[] {
  return [...root.querySelectorAll('[data-cafe-id]')].map(el => el.getAttribute('data-cafe-id')!)
}

describe('[spec-11] 심야 카공 모드 프리셋', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('프리셋 클릭 → c03/c06 골든 집합만 렌더', () => {
    const root = document.createElement('div')
    mountKagongApp(root)

    root.querySelector<HTMLButtonElement>('[data-night-preset]')!.click()

    expect(ids(root).sort()).toEqual(['c03', 'c06'])
    expect(root.querySelector('[data-filter-summary]')!.textContent).toBe('심야 카공 · 2곳')
  })

  it('완전 특성화: 조건을 만족하는 모든 카페와 결과가 일치', () => {
    const result = filterNightStudyPreset(cafes)

    expect(result.map(c => c.id).sort()).toEqual(['c03', 'c06'])
    expect(result.every(c => c.open24h && c.seats >= 50 && c.outlets === 'many')).toBe(true)
    expect(cafes.filter(c => c.open24h && c.seats >= 50 && c.outlets === 'many').map(c => c.id).sort()).toEqual([
      'c03',
      'c06',
    ])
  })
})
