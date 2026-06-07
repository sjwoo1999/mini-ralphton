// SPEC v0.4 [S8] 즐겨찾기. localStorage가 단일 진실원 — 인메모리 캐시 없음 →
// 새 인스턴스(앱 재로드)는 읽기만으로 자동 복원, 누수/desync 위험 없음.

/** 영속 키 (SPEC 계약 고정). */
export const FAVORITES_KEY = 'kagong:favorites'

/** 현재 즐겨찾기 id 목록(id 오름차순). 미저장·깨진 값은 안전하게 []. */
export function getFavorites(): string[] {
  const raw = localStorage.getItem(FAVORITES_KEY)
  if (raw === null) return []
  try {
    const parsed = JSON.parse(raw)
    if (!Array.isArray(parsed)) return []
    return parsed.filter((x): x is string => typeof x === 'string').sort()
  } catch {
    return [] // 깨진 JSON → 빈 목록 폴백
  }
}

/** id가 즐겨찾기에 있으면 true. */
export function isFavorite(id: string): boolean {
  return getFavorites().includes(id)
}

/** id를 토글(없으면 추가, 있으면 제거)하고 즉시 영속. 새 목록 반환. */
export function toggleFavorite(id: string): string[] {
  const set = new Set(getFavorites())
  if (set.has(id)) set.delete(id)
  else set.add(id)
  const next = [...set].sort()
  localStorage.setItem(FAVORITES_KEY, JSON.stringify(next))
  return next
}
