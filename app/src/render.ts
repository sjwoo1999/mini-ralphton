import type { Cafe } from './cafes'

const OUTLET_LABEL: Record<Cafe['outlets'], string> = {
  many: '콘센트 많음',
  some: '콘센트 보통',
  few: '콘센트 적음',
}

/** 카페 목록을 컨테이너에 렌더한다(기존 내용은 비운다). 순수 DOM — 지도 없음(v0.1). */
export function renderCafeList(container: HTMLElement, list: Cafe[]): void {
  container.replaceChildren()
  const ul = document.createElement('ul')
  ul.className = 'cafe-list'
  for (const cafe of list) {
    const li = document.createElement('li')
    li.className = 'cafe-item'
    li.setAttribute('data-cafe-id', cafe.id)
    const badges = [
      OUTLET_LABEL[cafe.outlets],
      cafe.wifi ? '와이파이' : null,
      cafe.open24h ? '24시간' : null,
    ].filter(Boolean).join(' · ')
    li.innerHTML =
      `<span class="cafe-name">${cafe.name}</span>` +
      `<span class="cafe-seats">${cafe.seats}석</span>` +
      `<span class="cafe-badges">${badges}</span>`
    ul.appendChild(li)
  }
  container.appendChild(ul)
}
