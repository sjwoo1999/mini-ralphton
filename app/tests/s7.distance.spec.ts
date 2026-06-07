import { describe, it, expect } from 'vitest'
import { cafes, haversine, sortByDistance, HONGDAE_STATION } from '../src/cafes'

// 기준점 = 홍대입구역 (SPEC v0.3 [S7] 고정)
const ORIGIN = { lat: 37.5572, lng: 126.9245 }

describe('[S7] 거리순 정렬 (haversine + sortByDistance)', () => {
  it('haversine km — 홍대입구역→c04(브루웍스 홍대)는 0.4~0.6km', () => {
    const c04 = cafes.find(c => c.id === 'c04')!
    const d = haversine(ORIGIN, c04)
    expect(d).toBeGreaterThanOrEqual(0.4)
    expect(d).toBeLessThanOrEqual(0.6)
  })

  it('haversine — 같은 점은 0, 대칭(a→b == b→a)', () => {
    const a = cafes[0]
    const b = cafes[1]
    expect(haversine(a, a)).toBe(0)
    expect(haversine(a, b)).toBeCloseTo(haversine(b, a), 10)
  })

  it('거리 오름차순 — 1위 c04·2위 c05·3위 c01', () => {
    const sorted = sortByDistance(cafes, ORIGIN)
    expect(sorted[0].id).toBe('c04')
    expect(sorted[1].id).toBe('c05')
    expect(sorted[2].id).toBe('c01')
  })

  it('동점은 id 오름차순 타이브레이크', () => {
    // 좌표가 동일한 두 카페를 합성 → 거리 동점 강제, id 오름차순 보장
    const tie = [
      { ...cafes[0], id: 'z02' },
      { ...cafes[0], id: 'z01' },
    ]
    const sorted = sortByDistance(tie, ORIGIN)
    expect(sorted.map(c => c.id)).toEqual(['z01', 'z02'])
  })

  it('순수함수 — 입력 배열을 변형하지 않는다', () => {
    const before = cafes.map(c => c.id)
    sortByDistance(cafes, ORIGIN)
    expect(cafes.map(c => c.id)).toEqual(before)
  })

  it('HONGDAE_STATION 상수가 SPEC 좌표와 일치', () => {
    expect(HONGDAE_STATION).toEqual(ORIGIN)
  })
})
