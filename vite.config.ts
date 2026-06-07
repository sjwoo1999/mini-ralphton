import { defineConfig } from 'vitest/config';

export default defineConfig({
  root: 'app',
  build: {
    outDir: '../dist',
    emptyOutDir: true
  },
  test: {
    environment: 'jsdom',
    include: ['tests/**/*.test.ts'],
    reporters: ['verbose']
  }
});
