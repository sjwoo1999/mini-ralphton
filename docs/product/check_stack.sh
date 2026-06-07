#!/usr/bin/env bash
set -euo pipefail

node <<'NODE'
const fs = require('fs')
const path = require('path')

const root = process.cwd()
const checkOnly = process.env.CHECK_ONLY || ''
const files = {
  'DOCS-GUARD': path.join(root, 'docs/AGENTS.md'),
  'AS-IS': path.join(root, 'docs/product/AS-IS.md'),
  PRD: process.env.STACK_PRD_PATH || path.join(root, 'docs/product/PRD.md'),
  ERD: path.join(root, 'docs/product/ERD.md'),
  'FE-SPEC': path.join(root, 'docs/product/FE-SPEC.md'),
  'BE-SPEC': path.join(root, 'docs/product/BE-SPEC.md'),
  BACKLOG: path.join(root, 'docs/product/BACKLOG.md'),
}
const seedPath = path.join(root, 'app/tests/protected/cafes.seed.json')
const testDir = path.join(root, 'app/tests')
const seed = JSON.parse(fs.readFileSync(seedPath, 'utf8'))

const selected = Object.keys(files).filter(id => !checkOnly || id === checkOnly)
if (checkOnly && selected.length === 0) {
  console.log(`RED ${checkOnly} unknown check id`)
  process.exit(1)
}

const failures = []
const read = (id) => fs.existsSync(files[id]) ? fs.readFileSync(files[id], 'utf8') : ''
const lines = (text) => text.trimEnd().split(/\r?\n/)
const countLines = (text) => text.trimEnd() ? lines(text).length : 0
const fail = (id, why) => failures.push(`RED ${id} ${why}`)
const requireFile = (id, minLines) => {
  if (!fs.existsSync(files[id])) {
    fail(id, 'missing file')
    return ''
  }
  const text = read(id)
  if (countLines(text) < minLines) fail(id, `line count below ${minLines}`)
  return text
}
const requireTokens = (id, text, tokens) => {
  for (const token of tokens) {
    if (!text.includes(token)) fail(id, `missing token ${token}`)
  }
}
const sectionBodyLines = (text, heading) => {
  const all = lines(text)
  const start = all.findIndex(line => line.trim() === heading)
  if (start < 0) return -1
  let end = all.length
  for (let i = start + 1; i < all.length; i += 1) {
    if (/^##\s+/.test(all[i])) {
      end = i
      break
    }
  }
  return all.slice(start + 1, end).filter(line => line.trim()).length
}
const grepEach = (id, text, patterns) => {
  for (const pattern of patterns) {
    if (!new RegExp(pattern, 'm').test(text)) fail(id, `missing pattern ${pattern}`)
  }
}

for (const id of selected) {
  if (id === 'DOCS-GUARD') {
    const text = requireFile(id, 6)
    requireTokens(id, text, ['박제 산출물 전용', '골든', '수정 금지'])
    if (/app\/tests\/protected\/cafes\.seed\.json.*수정 가능/.test(text)) fail(id, 'seed guard inverted')
  }

  if (id === 'AS-IS') {
    const text = requireFile(id, 15)
    requireTokens(id, text, ['출처'])
    const count = (text.match(/출처/g) || []).length
    if (count < 5) fail(id, '출처 count below 5')
  }

  if (id === 'PRD') {
    const text = requireFile(id, 80)
    const headings = ['## 1.1 문제 정의', '## 1.2 타깃 사용자', '## 1.3 가치 가설', '## 1.4 목표', '## 1.5 비범위', '## 1.6 킬 기준', '## 1.7 악마의 절']
    requireTokens(id, text, headings)
    requireTokens(id, text, ['G1', 'G2', 'G3', 'G4', 'G5', '공부적합', '순위'])
    for (const bad of ['TODO', 'TBD', '작성예정']) {
      if (text.includes(bad)) fail(id, `forbidden token ${bad}`)
    }
    const minimums = {
      '## 1.3 가치 가설': 3,
      '## 1.6 킬 기준': 4,
      '## 1.7 악마의 절': 8,
    }
    for (const [heading, min] of Object.entries(minimums)) {
      const got = sectionBodyLines(text, heading)
      if (got < min) fail(id, `section ${heading} below ${min}`)
    }
    grepEach(id, text, ['G1.*측정', 'G2.*측정', 'G3.*측정', 'G4.*측정', 'G5.*측정'])
    requireTokens(id, text, ['K1', 'K2', '다음 출하 1순위'])
  }

  if (id === 'ERD') {
    const text = requireFile(id, 30)
    requireTokens(id, text, ['id', 'lat', 'lng', 'name', 'open24h', 'outlets', 'seats', 'wifi', 'erDiagram'])
    if (!text.includes('50')) fail(id, 'missing seats boundary 50')
    const tableFields = new Set()
    for (const line of lines(text)) {
      const m = line.match(/^\|\s*`?([a-z][a-z0-9]*)`?\s*\|/)
      if (m && !['field', '필드'].includes(m[1])) tableFields.add(m[1])
    }
    const seedFields = new Set(Object.keys(seed[0]).sort())
    const tableSorted = [...tableFields].sort().join(',')
    const seedSorted = [...seedFields].sort().join(',')
    if (tableSorted !== seedSorted) fail(id, `field set mismatch ${tableSorted} != ${seedSorted}`)
    const extension = text.split('## 확장 후보')[1] || ''
    for (const field of ['noise', 'price', 'hours', 'region']) {
      if (!extension.includes(field) || !extension.includes('CONFIRM')) fail(id, `missing confirm extension ${field}`)
    }
  }

  if (id === 'FE-SPEC') {
    const text = requireFile(id, 40)
    requireTokens(id, text, ['F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'jsdom'])
    const rows = [...text.matchAll(/^\|\s*(F[1-8])\s*←\s*(G[1-5])\s*\|/gm)]
    const seen = new Map(rows.map(m => [m[1], m[2]]))
    for (let n = 1; n <= 8; n += 1) {
      if (!seen.has(`F${n}`)) fail(id, `missing trace F${n}`)
    }
    for (const g of ['G1', 'G2', 'G3', 'G4', 'G5']) {
      if (![...seen.values()].includes(g)) fail(id, `unused goal ${g}`)
    }
    const tests = Object.fromEntries(fs.readdirSync(testDir).filter(f => f.endsWith('.ts')).map(f => [f, fs.readFileSync(path.join(testDir, f), 'utf8')]))
    const testText = Object.values(tests).join('\n')
    const requiredEvidence = ['data-cafe-id', '공부적합', 'cafe-fav', 'localStorage']
    for (const token of requiredEvidence) {
      if (!testText.includes(token)) fail(id, `missing test evidence ${token}`)
    }
    const implementedSpecs = [
      ['F2', 'spec9.wiring.spec.ts', 'data-filter-outlets'],
      ['F3', 'spec9.wiring.spec.ts', 'data-search'],
      ['F4', 'spec9.wiring.spec.ts', 'data-sort-score'],
      ['F5', 'spec10.summary.spec.ts', 'data-filter-summary'],
      ['F8', 'spec8.breakdown.spec.ts', 'data-score-part'],
    ]
    for (const [feature, file, token] of implementedSpecs) {
      if (!text.includes(`${feature} ←`) || !text.includes('구현됨')) fail(id, `missing implemented marker ${feature}`)
      if (!tests[file] || !tests[file].includes(token)) fail(id, `missing implemented test ${file}:${token}`)
    }
    if (!tests['spec11.night.spec.ts'] || !tests['spec11.night.spec.ts'].includes('data-night-preset')) fail(id, 'missing spec11 test evidence')
    if (!tests['spec12.favview.spec.ts'] || !tests['spec12.favview.spec.ts'].includes('data-favorites-only')) fail(id, 'missing spec12 test evidence')
    if (!text.includes('사람 눈 검수')) fail(id, 'missing human eye section')
  }

  if (id === 'BE-SPEC') {
    const text = requireFile(id, 25)
    requireTokens(id, text, ['B1', 'B2', 'B3', 'cafes.json', '경계', '비범위'])
    const rows = [...text.matchAll(/^\|\s*(B[123])\s*←\s*(G[1-5])\s*\|/gm)]
    const seen = new Set(rows.map(m => m[1]))
    for (const b of ['B1', 'B2', 'B3']) {
      if (!seen.has(b)) fail(id, `missing trace ${b}`)
    }
  }

  if (id === 'BACKLOG') {
    const text = requireFile(id, 40)
    requireTokens(id, text, ['spec-8', 'spec-9', 'spec-10', 'spec-11', 'spec-12', '골든', '도출 규칙'])
    const expectJson = (label, actual, expected) => {
      if (JSON.stringify(actual) !== JSON.stringify(expected)) fail(id, `${label} golden mismatch ${JSON.stringify(actual)}`)
    }
    expectJson('many', seed.filter(c => c.outlets === 'many').map(c => c.id), ['c01', 'c03', 'c06', 'c07'])
    expectJson('name_cafe', seed.filter(c => c.name.includes('카페')).map(c => c.id), ['c01', 'c03', 'c06'])
    expectJson('open24h', seed.filter(c => c.open24h).map(c => c.id), ['c03', 'c06', 'c09'])
    expectJson('large', seed.filter(c => c.seats >= 50).map(c => c.id), ['c03', 'c06', 'c07'])
    expectJson('preset', seed.filter(c => c.open24h && c.seats >= 50 && c.outlets === 'many').map(c => c.id), ['c03', 'c06'])
    for (const specFile of ['spec8.breakdown.spec.ts', 'spec9.wiring.spec.ts', 'spec10.summary.spec.ts', 'spec11.night.spec.ts', 'spec12.favview.spec.ts']) {
      if (!fs.existsSync(path.join(testDir, specFile))) fail(id, `missing spec test ${specFile}`)
    }
    requireTokens(id, text, ['outlets === many', 'open24h', 'seats >= 50', 'open24h ∩ seats >= 50 ∩ outlets === many'])
  }

  if (!failures.some(line => line.startsWith(`RED ${id} `))) {
    console.log(`GREEN ${id}`)
  }
}

if (failures.length) {
  for (const line of failures) console.log(line)
  process.exit(1)
}
console.log('STACK GREEN')
NODE
