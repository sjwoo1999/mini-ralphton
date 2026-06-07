import { describe, it, expect } from 'vitest'
import { cafes, score } from '../src/cafes'
import { renderCafeList } from '../src/render'

describe('[S6] 점수 배지 "공부적합 N점"', () => {
  it('c03 항목에 "공부적합 5점" 표시', () => {
    const container = document.createElement('div')
    renderCafeList(container, cafes)
    const el = container.querySelector('[data-cafe-id="c03"]')
    expect(el).not.toBeNull()
    expect(el!.textContent).toContain('공부적합 5점')
  })

  it('모든 항목이 자기 점수를 "공부적합 N점"으로 표시', () => {
    const container = document.createElement('div')
    renderCafeList(container, cafes)
    for (const cafe of cafes) {
      const el = container.querySelector(`[data-cafe-id="${cafe.id}"]`)
      expect(el!.textContent).toContain(`공부적합 ${score(cafe)}점`)
    }
  })
})
