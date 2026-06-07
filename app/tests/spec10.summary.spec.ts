import { describe, expect, it, beforeEach } from 'vitest'
import { mountKagongApp } from '../src/ui'

describe('[spec-10] 활성 필터 요약 (F5)', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('콘센트=many 적용 → 조건과 골든 결과수 4를 헤더 요약에 표시', () => {
    const root = document.createElement('div')
    mountKagongApp(root)

    const select = root.querySelector<HTMLSelectElement>('[data-filter-outlets]')!
    select.value = 'many'
    select.dispatchEvent(new Event('change'))

    expect(root.querySelector('[data-filter-summary]')!.textContent).toBe('콘센트 많음 · 4곳')
    expect(root.querySelectorAll('[data-cafe-id]')).toHaveLength(4)
  })

  it('필터 해제 상태는 전체 10곳을 표시', () => {
    const root = document.createElement('div')
    mountKagongApp(root)

    expect(root.querySelector('[data-filter-summary]')!.textContent).toBe('전체 10곳')
    expect(root.querySelectorAll('[data-cafe-id]')).toHaveLength(10)
  })
})
