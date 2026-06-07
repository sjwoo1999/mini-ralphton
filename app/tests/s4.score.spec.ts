import { describe, it, expect } from 'vitest'
import { cafes, score, sortByScore } from '../src/cafes'

describe('[S4] 공부적합도 점수 + 내림차순 정렬', () => {
  it('score = outlets등급 + wifi + open24h', () => {
    const byId = Object.fromEntries(cafes.map(c => [c.id, c]))
    expect(score(byId['c03'])).toBe(5) // many3 + wifi1 + 24h1
    expect(score(byId['c01'])).toBe(4) // many3 + wifi1
    expect(score(byId['c02'])).toBe(3) // some2 + wifi1
    expect(score(byId['c05'])).toBe(1) // few1
  })

  it('내림차순 정렬, 동점은 id 오름차순 — 1위 c03', () => {
    const sorted = sortByScore(cafes)
    expect(sorted[0].id).toBe('c03')
    expect(sorted.map(c => c.id)).toEqual([
      'c03', 'c06', 'c01', 'c07', 'c09', 'c02', 'c08', 'c04', 'c05', 'c10',
    ])
    // 동점(c03=c06=5)에서 id 오름차순 타이브레이크
    expect(score(sorted[0])).toBe(score(sorted[1]))
    expect(sorted[0].id < sorted[1].id).toBe(true)
  })

  it('순수함수 — 입력 배열을 변형하지 않는다', () => {
    const before = cafes.map(c => c.id)
    sortByScore(cafes)
    expect(cafes.map(c => c.id)).toEqual(before)
  })
})
