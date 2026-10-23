const fs = require('fs');
const path = require('path');
const ROOT = 'F:/app';
const OFFICIAL = require('./retrofit_official.json');

const manifest = JSON.parse(fs.readFileSync(path.join(ROOT, 'assets/content/manifest.json'), 'utf8'));
const schedule = JSON.parse(fs.readFileSync(path.join(ROOT, 'docs/content_review_schedule.json'), 'utf8'));
const planned = {};
for (const b of schedule.batches) for (const id of b.lesson_ids) planned[id] = b.planned_review_at;

const byFile = new Map();
for (const cat of manifest.categories) {
  for (const l of cat.lessons) {
    if (!byFile.has(l.file)) byFile.set(l.file, []);
    byFile.get(l.file).push({ id: l.id, catId: cat.id });
  }
}

// positions of ## headings, ignoring fenced code blocks
function h2s(lines) {
  const out = [];
  let fence = false;
  for (let i = 0; i < lines.length; i++) {
    if (/^```/.test(lines[i])) { fence = !fence; continue; }
    if (!fence && /^##\s*参考资料与复核\s*$/.test(lines[i])) out.push(i);
  }
  return out;
}
function nextH2(lines, from) {
  let fence = false;
  for (let i = from; i < lines.length; i++) {
    if (/^```/.test(lines[i])) { fence = !fence; continue; }
    if (!fence && /^##\s/.test(lines[i]) && i !== from) return i;
  }
  return lines.length;
}

const report = { dup: 0, broken: 0, dates: 0 };
for (const [file, lessons] of byFile) {
  const p = path.join(ROOT, file.replace('assets/content/', ''));
  const abs = path.join(ROOT, 'assets/content', path.basename(file));
  if (!fs.existsSync(abs)) continue;
  const raw = fs.readFileSync(abs, 'utf8');
  const crlf = raw.includes('\r\n');
  let lines = raw.split(/\r?\n/);

  // 1. drop duplicate 参考资料与复核 sections (keep first)
  let heads = h2s(lines);
  while (heads.length > 1) {
    const last = heads[heads.length - 1];
    const end = nextH2(lines, last);
    let stop = end;
    while (stop > last + 1 && /^\s*$|^---\s*$/.test(lines[stop - 1])) stop--;
    if (stop <= last + 1) stop = end;
    lines.splice(last, stop - last);
    report.dup++;
    heads = h2s(lines);
  }

  // 2. repair broken official-link lines
  const url = (OFFICIAL[lessons[0].catId] || ['MIT OCW', 'https://ocw.mit.edu/'])[1];
  let touched = false;
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].includes('{off[1]}')) {
      lines[i] = lines[i].replace(/\{off\[1\]\}/g, url);
      touched = true;
      report.broken++;
    }
  }

  // 3. make sure every lesson served by this file has 最后复核 + its own 下次复核
  const body = lines.join('\n');
  const add = [];
  for (const l of lessons) {
    const want = planned[l.id];
    if (!want) continue;
    if (!/- 最后复核：2026-10-04/.test(body)) {
      if (!add.some((x) => x === '- 最后复核：2026-10-04')) add.push('- 最后复核：2026-10-04');
    }
    if (!body.includes('- 下次复核：' + want)) {
      if (!add.some((x) => x === '- 下次复核：' + want)) add.push('- 下次复核：' + want);
    }
  }
  if (add.length) {
    const heads2 = h2s(lines);
    if (heads2.length) {
      let end = nextH2(lines, heads2[0]);
      while (end > heads2[0] + 1 && /^\s*$|^---\s*$/.test(lines[end - 1])) end--;
      lines.splice(end, 0, ...add);
      report.dates += add.length;
    }
  }

  if (touched || add.length || heads.length < 1) {
    let out = lines.join('\n');
    if (crlf) out = out.replace(/\n/g, '\r\n');
    fs.writeFileSync(abs, out);
  }
}
console.log('dup sections removed', report.dup, '| broken links fixed', report.broken, '| date lines added', report.dates);
