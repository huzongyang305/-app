/*
 * lesson_probe.js — 加厚课文时的自助检查工具
 *   node tool/content_pipeline/lesson_probe.js chars <file...>      当前字符数与目标差
 *   node tool/content_pipeline/lesson_probe.js quiz <lesson_id>     本课题库原文（题干/选项/答案/解析）
 *   node tool/content_pipeline/lesson_probe.js check <file...>      改完后的一致性自检
 * check 会确认：H1 与 manifest 标题一致、每题题干仍逐字出现在课文里、代码块都有语言标记。
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const CONTENT = path.join(ROOT, 'assets', 'content');
const man = JSON.parse(fs.readFileSync(path.join(CONTENT, 'manifest.json'), 'utf8'));
const byId = new Map();
for (const cat of man.categories || []) {
  for (const l of cat.lessons || []) {
    l.categoryId = cat.id;
    byId.set(l.id, l);
  }
}
const byFile = new Map();
for (const l of byId.values()) if (l.file) byFile.set(path.basename(l.file), l);

const flat = (s) => String(s).replace(/\s+/g, '');
const LANG = new Set(['python', 'c', 'cpp', 'java', 'javascript', 'typescript', 'csharp', 'go', 'rust', 'kotlin', 'swift', 'shell']);
const cmd = process.argv[2];
const args = process.argv.slice(3);

/// 与 tool/audit_content_quality.dart 同口径：语言分类的入门课目标 12000，其余 10000。
function targetOf(l) {
  const t = String((l && ((l.title && l.title.zh) || l.title)) || '');
  const intro = ['入门', '基础', '初识', '介绍'].some((k) => t.includes(k));
  return l && LANG.has(l.categoryId) && intro ? 12000 : 10000;
}

if (cmd === 'chars') {
  for (const f of args) {
    const p = path.isAbsolute(f) ? f : path.join(CONTENT, f);
    const len = fs.readFileSync(p, 'utf8').length;
    const l = byFile.get(path.basename(p));
    const target = targetOf(l);
    console.log(path.basename(p) + ' 现在 ' + len + ' 字，目标 ' + target + '，' + (len >= target ? '已达标' : '还差 ' + (target - len)));
  }
  process.exit(0);
}

if (cmd === 'quiz') {
  const l = byId.get(args[0]);
  if (!l) {
    console.log('找不到课时 ' + args[0]);
    process.exit(1);
  }
  console.log('# ' + args[0] + ' → ' + (l.file || '') + '  标题：' + ((l.title && l.title.zh) || l.title));
  (l.quiz || []).forEach((q, i) => {
    console.log('\n[' + i + '] 题型 ' + (q.type || 'single'));
    console.log('  题干：' + q.question);
    (q.options || []).forEach((o, j) => console.log('    ' + j + '. ' + o + (q.answer === j ? '   <= 正确项' : '')));
    if (q.answer !== undefined) console.log('  答案下标：' + q.answer);
    if (q.answers) console.log('  多选下标：' + JSON.stringify(q.answers));
    if (q.accepted_answers) console.log('  可接受答案：' + JSON.stringify(q.accepted_answers));
    if (q.correct_order) console.log('  正确顺序：' + JSON.stringify(q.correct_order));
    if (q.code) console.log('  代码：\n' + q.code);
    console.log('  解析：' + q.explanation);
  });
  process.exit(0);
}

if (cmd === 'check') {
  let bad = 0;
  for (const f of args) {
    const p = path.isAbsolute(f) ? f : path.join(CONTENT, f);
    const body = fs.readFileSync(p, 'utf8');
    const l = byFile.get(path.basename(p));
    if (!l) {
      console.log('! ' + path.basename(p) + ' 不在 manifest 里');
      bad++;
      continue;
    }
    const title = (l.title && l.title.zh) || l.title || '';
    const h1 = (body.match(/^# (.+)$/m) || [])[1] || '';
    if (flat(h1) !== flat(title)) {
      console.log('! ' + path.basename(p) + ' H1「' + h1 + '」≠ 标题「' + title + '」');
      bad++;
    }
    (l.quiz || []).forEach((q, i) => {
      if (!flat(body).includes(flat(q.question))) {
        console.log('! ' + path.basename(p) + ' 第 ' + i + ' 题题干没有逐字出现在课文里');
        bad++;
      }
    });
    let open = null;
    let noLang = 0;
    for (const line of body.split(/\r?\n/)) {
      const m = /^\s*(```|~~~)(.*)$/.exec(line);
      if (!m) continue;
      if (open === null) {
        open = m[1];
        if (!m[2].trim()) noLang++;
      } else {
        open = null;
      }
    }
    if (noLang) {
      console.log('! ' + path.basename(p) + ' 有 ' + noLang + ' 个代码块缺少语言标记');
      bad++;
    }
  }
  console.log(bad ? '自检未通过：' + bad + ' 项' : '自检通过：标题/题干/代码块标记均一致');
  process.exit(bad ? 1 : 0);
}

/// 表格行列数是否与表头一致（加厚时最常见的破坏方式是多写/少写一个单元格）。
function tableRows(body) {
  const lines = body.split(/\r?\n/);
  const issues = [];
  let inFence = false;
  const cells = (line) => {
    const out = [];
    let cur = '';
    for (let i = 0; i < line.length; i++) {
      const ch = line[i];
      if (ch === '\\' && line[i + 1] === '|') { cur += '|'; i++; continue; }
      if (ch === '|') { out.push(cur.trim()); cur = ''; continue; }
      cur += ch;
    }
    out.push(cur.trim());
    return out;
  };
  for (let i = 0; i + 1 < lines.length; i++) {
    const m = /^\s*(```|~~~)/.exec(lines[i]);
    if (m) { inFence = !inFence; continue; }
    if (inFence) continue;
    if (!/^\s*\|/.test(lines[i]) || !/^\s*\|[\s:|-]+\|\s*$/.test(lines[i + 1])) continue;
    const header = cells(lines[i].trim());
    let j = i + 2;
    for (; j < lines.length && /^\s*\|/.test(lines[j]); j++) {
      const n = cells(lines[j].trim()).length;
      if (n !== header.length) issues.push({ line: j + 1, got: n, want: header.length, text: lines[j].slice(0, 80) });
    }
    i = j - 1;
  }
  return issues;
}

if (cmd === 'table') {
  let bad = 0;
  for (const f of args) {
    const p = path.isAbsolute(f) ? f : path.join(CONTENT, f);
    const issues = tableRows(fs.readFileSync(p, 'utf8'));
    for (const it of issues) {
      console.log('! ' + path.basename(p) + ':' + it.line + ' 有 ' + it.got + ' 格，表头 ' + it.want + ' 格 → ' + it.text);
      bad++;
    }
  }
  console.log(bad ? '列数不齐：' + bad + ' 行' : '表格列数全部与表头一致');
  process.exit(bad ? 1 : 0);
}

console.log('用法：node tool/content_pipeline/lesson_probe.js chars|quiz|check|table ...');
