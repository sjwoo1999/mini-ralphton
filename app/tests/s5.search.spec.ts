import { describe, it, expect } from 'vitest'
import { cafes, filterByName } from '../src/cafes'

describe('[S5] 이름 검색 (부분일치·대소문자 무시)', () => {
  it('"카페" 검색은 정확히 c01,c03,c06 (3곳)', () => {
    const r = filterByName(cafes, '카페')
    expect(r.length).toBe(3)
    expect(r.map(c => c.id).sort()).toEqual(['c01', 'c03', 'c06'])
  })

  it('대소문자 무시 — "H"가 "24h 카페인 강남"(c06)을 매치', () => {
    const r = filterByName(cafes, 'H')
    expect(r.map(c => c.id)).toContain('c06')
  })

  it('공백·빈 문자열은 전체 목록을 그대로 반환 (필터 해제)', () => {
    expect(filterByName(cafes, '').length).toBe(cafes.length)
    expect(filterByName(cafes, '   ').length).toBe(cafes.length)
  })
})
