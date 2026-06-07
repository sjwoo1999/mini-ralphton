import { describe, expect, it } from 'vitest'
import { cafes, score, scoreBreakdown } from '../src/cafes'
import { renderCafeList } from '../src/render'

function parts(container: HTMLElement, id: string) {
  const card = container.querySelector(`[data-cafe-id="${id}"]`)!
  return {
    outlets: card.querySelector('[data-score-part="outlets"]')!.textContent,
    wifi: card.querySelector('[data-score-part="wifi"]')!.textContent,
    open24h: card.querySelector('[data-score-part="open24h"]')!.textContent,
    sum: card.querySelector<HTMLElement>('.cafe-breakdown')!.dataset.scoreSum,
  }
}

describe('[spec-8] 점수 분해 표시 (F8)', () => {
  it('c03 카드가 콘센트=3, 와이파이=1, 24시간=1, 합=5를 표시', () => {
    const container = document.createElement('div')
    renderCafeList(container, cafes)

    expect(parts(container, 'c03')).toEqual({
      outlets: '콘센트 +3',
      wifi: '와이파이 +1',
      open24h: '24시간 +1',
      sum: '5',
    })
    expect(scoreBreakdown(cafes.find(c => c.id === 'c03')!)).toEqual({
      outlets: 3,
      wifi: 1,
      open24h: 1,
      sum: 5,
    })
  })

  it('c05 카드가 0점 기여분까지 표시하고 합이 score와 일치', () => {
    const container = document.createElement('div')
    renderCafeList(container, cafes)

    expect(parts(container, 'c05')).toEqual({
      outlets: '콘센트 +1',
      wifi: '와이파이 +0',
      open24h: '24시간 +0',
      sum: '1',
    })
    const c05 = cafes.find(c => c.id === 'c05')!
    expect(scoreBreakdown(c05)).toEqual({ outlets: 1, wifi: 0, open24h: 0, sum: 1 })
    expect(scoreBreakdown(c05).sum).toBe(score(c05))
  })
})
