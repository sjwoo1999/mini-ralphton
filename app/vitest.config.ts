import { defineConfig } from 'vitest/config'
export default defineConfig({
  test: {
    environment: 'jsdom',          // DOMParser 제공 (GPX 파싱 테스트용)
    include: ['tests/**/*.spec.ts'],
    coverage: { provider: 'v8', reporter: ['json-summary'], include: ['src/**'] },
  },
})
