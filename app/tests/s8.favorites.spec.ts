import { describe, it, expect, beforeEach } from 'vitest'
import { cafes } from '../src/cafes'
import { toggleFavorite, getFavorites, isFavorite, FAVORITES_KEY } from '../src/favorites'
import { renderCafeList } from '../src/render'

// SPEC v0.4 [S8]: localStorage 누수 flaky 방지 — 매 테스트 전 초기화 필수
beforeEach(() => {
  localStorage.clear()
})

describe('[S8] 즐겨찾기 (localStorage 영속)', () => {
  it('미저장 시 빈 배열 []', () => {
    expect(getFavorites()).toEqual([])
    expect(isFavorite('c01')).toBe(false)
  })

  it('토글 → 포함', () => {
    toggleFavorite('c01')
    expect(isFavorite('c01')).toBe(true)
    expect(getFavorites()).toContain('c01')
  })

  it('재토글 → 제거', () => {
    toggleFavorite('c01')
    toggleFavorite('c01')
    expect(isFavorite('c01')).toBe(false)
    expect(getFavorites()).not.toContain('c01')
  })

  it('여러 개 토글 — id 오름차순으로 안정 정렬', () => {
    toggleFavorite('c05')
    toggleFavorite('c02')
    toggleFavorite('c09')
    expect(getFavorites()).toEqual(['c02', 'c05', 'c09'])
  })

  it('새 인스턴스(앱 재로드)가 localStorage에서 복원 — 인메모리 캐시 아님', () => {
    // 다른 코드경로(직접 시드)가 쓴 값을 "갓 읽기"가 복원함을 증명 → localStorage가 단일 진실원
    localStorage.setItem(FAVORITES_KEY, JSON.stringify(['c05', 'c02']))
    expect(getFavorites()).toEqual(['c02', 'c05']) // 토글 호출 없이 복원
    expect(isFavorite('c05')).toBe(true)
  })

  it('영속 키가 SPEC 계약(kagong:favorites)과 일치', () => {
    expect(FAVORITES_KEY).toBe('kagong:favorites')
    toggleFavorite('c03')
    expect(localStorage.getItem('kagong:favorites')).toBe(JSON.stringify(['c03']))
  })

  it('깨진 저장값은 안전하게 [] 로 폴백', () => {
    localStorage.setItem(FAVORITES_KEY, '{not json')
    expect(getFavorites()).toEqual([])
  })

  it('목록 항목에 ★ 토글 표시 — 즐겨찾기는 aria-pressed=true', () => {
    toggleFavorite('c03')
    const container = document.createElement('div')
    renderCafeList(container, cafes)

    const favBtn = container.querySelector('[data-cafe-id="c03"] .cafe-fav')
    expect(favBtn).not.toBeNull()
    expect(favBtn!.getAttribute('aria-pressed')).toBe('true')
    expect(favBtn!.textContent).toContain('★')

    const plainBtn = container.querySelector('[data-cafe-id="c01"] .cafe-fav')
    expect(plainBtn!.getAttribute('aria-pressed')).toBe('false')
    expect(plainBtn!.textContent).toContain('☆')
  })
})
