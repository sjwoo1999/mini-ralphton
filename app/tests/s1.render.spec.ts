import { describe, it, expect } from 'vitest'
import seed from './protected/cafes.seed.json'
import bundled from '../src/data/cafes.json'
import { cafes } from '../src/cafes'
import { renderCafeList } from '../src/render'

describe('[S1] 데이터 로드·렌더', () => {
  it('번들 데이터가 골든 시드와 동일하다', () => {
    expect(bundled).toEqual(seed)
    expect(cafes).toEqual(seed)
    expect(cafes.length).toBe(10)
  })

  it('시드 10곳을 이름·좌석수와 함께 DOM 목록으로 렌더한다', () => {
    const container = document.createElement('div')
    renderCafeList(container, cafes)
    const items = container.querySelectorAll('[data-cafe-id]')
    expect(items.length).toBe(10)
    for (const cafe of cafes) {
      const el = container.querySelector(`[data-cafe-id="${cafe.id}"]`)
      expect(el).not.toBeNull()
      expect(el!.textContent).toContain(cafe.name)
      expect(el!.textContent).toContain(String(cafe.seats))
    }
  })
})
