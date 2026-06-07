import { describe, it, expect } from 'vitest'
import { cafes, filterByWifiAndOpen24h } from '../src/cafes'

describe('[S3] 복합 필터 wifi AND open24h', () => {
  it('교집합은 정확히 c03,c06,c09 (3곳)', () => {
    const r = filterByWifiAndOpen24h(cafes)
    expect(r.length).toBe(3)
    expect(r.map(c => c.id).sort()).toEqual(['c03', 'c06', 'c09'])
    expect(r.every(c => c.wifi && c.open24h)).toBe(true)
  })
})
