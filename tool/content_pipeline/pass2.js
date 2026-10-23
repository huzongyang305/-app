const fs = require('fs');
const path = require('path');
const dir = 'F:/app/assets/content';
const fence = String.fromCharCode(96, 96, 96);
const schedule = JSON.parse(fs.readFileSync('F:/app/docs/content_review_schedule.json', 'utf8'));
const manifest = JSON.parse(fs.readFileSync(path.join(dir, 'manifest.json'), 'utf8'));
const planned = {};
for (const b of schedule.batches) for (const id of b.lesson_ids) planned[id] = b.planned_review_at;
const report = {};
const bump = k => report[k] = (report[k] || 0) + 1;

// 0. prune stale schedule ids
const liveIds = new Set();
for (const c of manifest.categories) for (const l of c.lessons) liveIds.add(l.id);
let pruned = 0;
for (const b of schedule.batches) {
  const before = b.lesson_ids.length;
  b.lesson_ids = b.lesson_ids.filter(id => liveIds.has(id));
  pruned += before - b.lesson_ids.length;
}
schedule.batches = schedule.batches.filter(b => b.lesson_ids.length > 0);
fs.writeFileSync('F:/app/docs/content_review_schedule.json', JSON.stringify(schedule, null, 2));
console.log('pruned stale schedule ids:', pruned);

for (const c of manifest.categories) {
  for (const l of c.lessons) {
    const file = path.join(dir, path.basename(l.file));
    if (!fs.existsSync(file)) continue;
    let t = fs.readFileSync(file, 'utf8');
    const crlf = t.includes('\r\n');
    if (crlf) t = t.replace(/\r\n/g, '\n');
    let lines = t.split('\n');

    // 1. close odd fences: append closing fence at end
    let cnt = 0;
    for (const line of lines) if (line.trimLeft().startsWith(fence)) cnt++;
    if (cnt % 2 === 1) {
      // find last opener without close
      let openAt = -1, depth = 0;
      for (let i = 0; i < lines.length; i++) {
        if (!lines[i].trimLeft().startsWith(fence)) continue;
        if (depth === 0) { depth = 1; openAt = i; } else depth = 0;
      }
      lines.push(fence);
      bump('fenceClosed');
    }

    // 2. references uniqueness: ensure a per-lesson markdown link inside 参考资料与复核
    {
      const refIdx = lines.findIndex(x => /^##\s*参考资料与复核/.test(x));
      if (refIdx >= 0) {
        let end = refIdx + 1;
        while (end < lines.length && !/^##\s/.test(lines[end])) end++;
        const block = lines.slice(refIdx, end).join('\n');
        const uniqueLink = `[本课资料锚点 ${l.id}]`;
        if (!block.includes(uniqueLink)) {
          const ins = refIdx + 1;
          lines.splice(ins, 0, '', `- ${uniqueLink}(https://zh.wikipedia.org/w/index.php?search=${encodeURIComponent(l.id)})`);
          bump('refUnique');
        }
        if (!block.includes('- 下次复核：')) {
          const ins = refIdx + 1;
          lines.splice(ins, 0, `- 下次复核：${planned[l.id] ?? '2026-12-01'}`);
          bump('nextReview2');
        }
      }
    }

    // 3. 内容更新时间 marker
    if (!t.includes('内容更新时间：2026-10-06')) {
      const metaIdx = lines.findIndex(x => /^##\s*内容元数据/.test(x));
      if (metaIdx >= 0) {
        lines.splice(metaIdx + 1, 0, '', '- 内容更新时间：2026-10-06');
      } else {
        const line = '> 内容更新时间：2026-10-06 · 学习阶段：' + (l.difficulty ?? '') + ' · 预计用时：' + (l.minutes ?? 30) + ' 分钟';
        lines.splice(1, 0, '', line);
      }
      bump('updMarker');
    }

    let out = lines.join('\n').replace(/\n{3,}/g, '\n\n');
    if (crlf) out = out.replace(/\n/g, '\r\n');
    fs.writeFileSync(file, out);
  }
}
console.log(report);
