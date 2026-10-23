const fs = require('fs');
const file = 'F:/app/assets/content/manifest.json';
const m = JSON.parse(fs.readFileSync(file, 'utf8'));
const rank = d => ({ '入门': 0, '基础': 1, '进阶': 2, '高级': 3 })[d] ?? 0;
const log = [];

// 1. lab bindings
for (const c of Object.values(m.categories)) {
  for (const l of c.lessons) {
    if (c.id === 'java' && !l.lab) { l.lab = 'sandbox:java'; log.push('lab+ ' + l.id); }
  }
}

// 2. dangling prerequisites
const allIds = new Set();
for (const c of Object.values(m.categories)) for (const l of c.lessons) allIds.add(l.id);
const alias = { python_errors_files: 'python_errors_logging_files' };
for (const c of Object.values(m.categories)) {
  for (const l of c.lessons) {
    if (!l.prerequisites) continue;
    l.prerequisites = l.prerequisites.map(p => {
      if (allIds.has(p)) return p;
      if (alias[p] && allIds.has(alias[p])) { log.push('prereq alias ' + l.id + ': ' + p + ' -> ' + alias[p]); return alias[p]; }
      log.push('prereq DROP ' + l.id + ': ' + p);
      return null;
    }).filter(Boolean);
  }
}

// 3. sequential order per category (preserve relative order)
for (const c of Object.values(m.categories)) {
  const lessons = [...c.lessons].sort((a, b) => (a.order ?? 0) - (b.order ?? 0) || a.id.localeCompare(b.id));
  lessons.forEach((l, i) => { if (l.order !== i + 1) { log.push(`order ${c.id}/${l.id}: ${l.order} -> ${i + 1}`); l.order = i + 1; } });
}

// 4. difficulty monotonic + prereq position/difficulty: adjust difficulty or drop prereq
for (const c of Object.values(m.categories)) {
  const lessons = [...c.lessons].sort((a, b) => a.order - b.order);
  const pos = Object.fromEntries(lessons.map((l, i) => [l.id, i]));
  for (let i = 1; i < lessons.length; i++) {
    const prev = lessons[i - 1], cur = lessons[i];
    if (rank(cur.difficulty) < rank(prev.difficulty)) {
      log.push(`difficulty bump ${c.id}/${cur.id}: ${cur.difficulty} -> ${prev.difficulty}`);
      cur.difficulty = prev.difficulty;
    }
  }
  for (const l of lessons) {
    if (!l.prerequisites) continue;
    const selfRank = rank(l.difficulty);
    l.prerequisites = l.prerequisites.filter(p => {
      if (!(p in pos)) return true; // cross-category prereq: position not enforced, but difficulty check uses global lookup
      return true;
    });
  }
  // prereq harder than lesson (same category) -> drop that prereq; prereq after lesson -> drop
  const byId = Object.fromEntries(lessons.map(l => [l.id, l]));
  for (const l of lessons) {
    if (!l.prerequisites?.length) continue;
    l.prerequisites = l.prerequisites.filter(p => {
      if (!(p in byId)) return true;
      if (rank(byId[p].difficulty) > rank(l.difficulty)) { log.push(`prereq DROP(harder) ${l.id}: ${p}`); return false; }
      if (pos[p] >= pos[l.id]) { log.push(`prereq DROP(after) ${l.id}: ${p}`); return false; }
      return true;
    });
  }
}

fs.writeFileSync(file, JSON.stringify(m, null, 2));
console.log(log.length, 'changes');
log.forEach(x => console.log(' ', x));
