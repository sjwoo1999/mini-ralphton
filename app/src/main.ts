import './style.css'
import { mountKagongApp } from './ui'

const app = document.querySelector<HTMLDivElement>('#app')
if (app) {
  mountKagongApp(app)
}
