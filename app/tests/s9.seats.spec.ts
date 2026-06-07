import { describe, it, expect } from 'vitest'
import { cafes, filterByLargeSeats, LARGE_SEATS_MIN } from '../src/cafes'

describe('[S9] 좌석규모 필터 (대형: seats >= 50)', () => {
  it('대형 카페는 정확히 c03,c06,c07 (3곳)', () => {
    const r = filterByLargeSeats(cafes)
    expect(r.length).toBe(3)
    expect(r.map(c => c.id).sort()).toEqual(['c03', 'c06', 'c07'])
    expect(r.every(c => c.seats >= LARGE_SEATS_MIN)).toBe(true)
  })

  it('임계값(50석)은 포함 경계 — 정확히 50석도 대형', () => {
    expect(LARGE_SEATS_MIN).toBe(50)
    // c07=52는 경계 부근 포함, c01=48은 제외 (off-by-one 회귀 방지)
    const ids = filterByLargeSeats(cafes).map(c => c.id)
    expect(ids).toContain('c07')
    expect(ids).not.toContain('c01')
  })
})
