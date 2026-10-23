const fs = require('fs');
const path = require('path');
const CONTENT = path.join(__dirname, 'assets', 'content');
const manifest = JSON.parse(fs.readFileSync(path.join(CONTENT, 'manifest.json'), 'utf8'));

// --- collect lesson -> file mapping and quiz questions ---
const fileToQuiz = new Map();
for (const cat of Object.values(manifest.categories ?? manifest)) {
  const lessons = cat.lessons ?? cat.courses ?? [];
  for (const l of lessons) {
    if (!l.file) continue;
    const p = path.join(CONTENT, path.basename(l.file));
    if (!fs.existsSync(p)) continue;
    if (!fileToQuiz.has(p)) fileToQuiz.set(p, []);
    for (const q of l.quiz ?? []) fileToQuiz.get(p).push(q.question);
  }
}

const REMOVE_PREFIXES = [
  '### 从概念到验证的学习链条',
  '### 完成判据',
  '### 机制拆解',
  '### 示例中的可观察事实',
  '### 复现实验记录',
  '### 概念复述',
  '### 正文逐节复核',
  '### 迁移练习',
  '### 先修与后续术语接口',
  '### 容易混淆的相邻概念',
  '### 升级检查清单',
  '### 示例精读',
  '### 需要控制的变量与记录项',
];

const norm = s => s.replace(/\s+/g, '');

function stripSection(lines, startIdx) {
  // remove from startIdx up to (not incl.) next ## or ### line
  let end = startIdx + 1;
  while (end < lines.length && !/^(##|###)(\s|$)/.test(lines[end])) end++;
  // trim trailing blanks
  while (end > startIdx + 1 && lines[end - 1].trim() === '') end--;
  // also swallow blanks right before start
  let s = startIdx;
  while (s > startIdx && lines[s - 1].trim() === '') s--;
  lines.splice(startIdx, end - startIdx);
}

function processFile(file) {
  const orig = fs.readFileSync(file, 'utf8');
  const crlf = orig.includes('\r\n');
  const text = crlf ? orig.replace(/\r\n/g, '\n') : orig;
  const lines = text.split('\n');

  // mask fenced blocks
  const fenced = new Array(lines.length).fill(false);
  let inFence = false;
  for (let i = 0; i < lines.length; i++) {
    if (/^```/.test(lines[i])) { fenced[i] = true; inFence = !inFence; continue; }
    fenced[i] = inFence;
  }

  // 1. delete template H3 sections (self-test items only under 自测题与参考答案)
  let inSelfTest = false;
  for (let i = lines.length - 1; i >= 0; i--) {
    if (fenced[i]) continue;
    if (/^##(\s|$)/.test(lines[i])) inSelfTest = /^##\s+自测题与参考答案/.test(lines[i]);
    if (!/^###(\s|$)/.test(lines[i])) continue;
    const h = lines[i];
    const remove = REMOVE_PREFIXES.some(p => h.startsWith(p)) ||
      (inSelfTest && h.startsWith('### 自测 '));
    if (remove) stripSection(lines, i);
  }

  // 2. core-concept table: drop tautological 3rd column
  const out = [];
  let ti = 0;
  const n = lines.length;
  const taut = c => /^只在「.+」这一前提下成立/.test(c) || /^结论随输入规模变化/.test(c);
  while (ti < n) {
    if (!fenced[ti] && /^\|\s*术语\s*\|\s*操作性定义/.test(lines[ti].trim())) {
      // gather table block
      let j = ti;
      const rows = [];
      while (j < n && lines[j].trim().startsWith('|')) { rows.push(lines[j].trim()); j++; }
      const cells = r => r.replace(/^\|/, '').replace(/\|$/, '').split('|').map(c => c.trim());
      const allTaut = rows.length >= 3 && rows.slice(2).every(r => {
        const c = cells(r); return c.length >= 3 && taut(c[2]);
      });
      if (allTaut) {
        out.push('| 术语 | 操作性定义 |', '| --- | --- |');
        for (const r of rows.slice(2)) out.push('| ' + cells(r).slice(0, 2).join(' | ') + ' |');
      } else {
        for (const r of rows) out.push(r);
      }
      ti = j;
      continue;
    }
    out.push(lines[ti]);
    ti++;
  }

  let result = out.join('\n');
  // collapse 3+ blank lines
  result = result.replace(/\n{3,}/g, '\n\n');
  if (crlf) result = result.replace(/\n/g, '\r\n');

  // verification: quiz coverage + length
  const problems = [];
  for (const q of fileToQuiz.get(file) ?? []) {
    if (!norm(result).includes(norm(q))) problems.push('missing quiz: ' + q.slice(0, 40));
  }
  if (result.length < 3100) problems.push('too short: ' + result.length);
  if (problems.length) return { file, skipped: true, problems };

  if (result !== orig) {
    fs.writeFileSync(file, result);
    return { file, skipped: false, delta: orig.length - result.length };
  }
  return { file, skipped: false, delta: 0 };
}

const files = fs.readdirSync(CONTENT).filter(f => f.endsWith('.md')).map(f => path.join(CONTENT, f));
let changed = 0, skippedList = [], totalDelta = 0;
for (const f of files) {
  const r = processFile(f);
  if (r.skipped) skippedList.push(r);
  else { if (r.delta > 0) { changed++; totalDelta += r.delta; } }
}
console.log('changed files:', changed, 'total chars removed:', totalDelta);
console.log('skipped:', skippedList.length);
for (const s of skippedList.slice(0, 20)) console.log(' ', path.basename(s.file), s.problems.join(' ; '));
