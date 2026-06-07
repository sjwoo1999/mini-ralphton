import { describe, it, expect } from 'vitest'
import { cafes, filterByOutlets } from '../src/cafes'

describe('[S2] 콘센트 필터 (최소등급)', () => {
  it('many 최소등급 → many 4곳만', () => {
    const r = filterByOutlets(cafes, 'many')
    expect(r.length).toBe(4)
    expect(r.map(c => c.id).sort()).toEqual(['c01', 'c03', 'c06', 'c07'])
  })

  it('some 최소등급 → many+some (서열 many>some>few)', () => {
    const r = filterByOutlets(cafes, 'some')
    expect(r.every(c => c.outlets === 'many' || c.outlets === 'some')).toBe(true)
    expect(r.some(c => c.outlets === 'few')).toBe(false)
    expect(r.length).toBe(7)
  })

  it('few 최소등급 → 전부', () => {
    expect(filterByOutlets(cafes, 'few').length).toBe(10)
  })
})
