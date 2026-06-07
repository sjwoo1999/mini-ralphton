import { cafes, sortByScore } from './cafes'
import { renderCafeList } from './render'

const app = document.querySelector<HTMLDivElement>('#app')
if (app) {
  const heading = document.createElement('h1')
  heading.textContent = '카공지도'
  app.appendChild(heading)
  const listRoot = document.createElement('div')
  app.appendChild(listRoot)
  renderCafeList(listRoot, sortByScore(cafes))
}
