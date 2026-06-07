#!/usr/bin/env node
// vitest JSON 리포트 → 통과 테스트의 SPEC ID 집합. 사용: node green_set.js <vitest.json>
const fs = require('fs')
let ids = new Set()
try {
  const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'))
  for (const f of r.testResults || [])
    for (const t of f.assertionResults || [])
      if (t.status === 'passed')
        for (const m of (t.fullName || t.title || '').matchAll(/\[S(\d+)\]/g)) ids.add('S' + m[1])
} catch (e) { /* 리포트 없음/깨짐 → 빈 집합 */ }
process.stdout.write(JSON.stringify({ green_ids: [...ids].sort() }))
