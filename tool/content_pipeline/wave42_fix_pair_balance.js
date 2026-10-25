/*
 * wave42_fix_pair_balance.js — 修复课文与题库解析里的成对符号/截短注入缺陷
 *   node tool/content_pipeline/wave42_fix_pair_balance.js          # 干跑，只体检
 *   node tool/content_pipeline/wave42_fix_pair_balance.js --apply  # 真正写盘
 *
 * 清单来自 tool/content_pipeline/wave42_fixes.json（由 5 份分批体检报告合成），
 * 每条给出 file / old / new / expectMd / expectManifest。
 * 按原文纯子串替换，不重新序列化，因此每个文件各自的 CRLF/LF 与缩进都保持原样，
 * 重复执行也不会二次改动（替换后的 new 不再匹配 old）。
 *
 * 三道护栏，任一不过就不写盘：
 *   1) 次数不符（old 在课文或 manifest 里出现的次数与体检报告不一致）→ 说明课文已漂移，先查再改；
 *   2) 表格列数变化（old 与 new 的非转义 | 数不等）→ 会拆坏 Markdown 表格；
 *   3) 题干覆盖（改完后再按 test/content_test.dart 的空白归一化口径，
 *      核对每条 quiz 题干仍能在校验到的课文里找到）→ 题干与考点精讲是绑死的。
 */
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..', '..');
const apply = process.argv.includes('--apply');
const fixFile = path.join(__dirname, 'wave42_fixes.json');
const fixes = JSON.parse(fs.readFileSync(fixFile, 'utf8'));
const manifestRel = 'assets/content/manifest.json';

const count = (hay, needle) => (needle ? hay.split(needle).length - 1 : 0);
// Markdown 里单元格内的竖线要转义成 \|，数「真正的列分隔符」时得把 \| 先抹掉。
const columns = (s) => s.replace(/\\\|/g, '').split('|').length;
const norm = (s) => s.replace(/\s+/g, '');

const readCache = new Map();
const read = (rel) => {
  if (!readCache.has(rel)) readCache.set(rel, fs.readFileSync(path.join(root, rel), 'utf8'));
  return readCache.get(rel);
};

const blockers = [];
const stats = { lessons: new Set(), mdHits: 0, manifestHits: 0, skipped: 0 };

// 先复核每条替换的落点与列数，收集真正要动的文本。
const planMd = new Map();
const planManifest = [];
for (const fx of fixes) {
  const isManifestTarget = fx.file === manifestRel;
  // 纯 manifest 条目没有课文落点，次数只按 manifest 复核。
  const gotMd = isManifestTarget ? 0 : count(read(fx.file), fx.old);
  const expectMd = isManifestTarget ? 0 : fx.expectMd || 1;
  if (gotMd !== expectMd) {
    blockers.push(`COUNT ${fx.file}:${fx.line} [${fx.cls}/${fx.conf}] old 期望 ${expectMd} 次，实得 ${gotMd} 次`);
    continue;
  }
  const gotMf = count(read(manifestRel), fx.old);
  const expectMf = isManifestTarget ? fx.expectManifest || 1 : fx.expectManifest || 0;
  if (gotMf !== expectMf) {
    blockers.push(`COUNT-manifest ${fx.file}:${fx.line} [${fx.cls}/${fx.conf}] manifest 期望 ${expectMf} 次，实得 ${gotMf} 次`);
    continue;
  }
  if (columns(fx.old) !== columns(fx.new)) {
    blockers.push(`COLUMNS ${fx.file}:${fx.line} [${fx.cls}] 竖线数 ${columns(fx.old)} → ${columns(fx.new)}，会改变表格列数`);
    continue;
  }
  if (!isManifestTarget && expectMd > 0) {
    if (!planMd.has(fx.file)) planMd.set(fx.file, []);
    planMd.get(fx.file).push(fx);
    stats.mdHits += gotMd;
    stats.lessons.add(fx.file);
  }
  if (expectMf > 0) {
    planManifest.push(fx);
    stats.manifestHits += gotMf;
  }
  for (const bad of ['题干「', '本题顺序是「核心知识」。', '把「2. ', '把「3. ']) {
    if (fx.new.includes(bad)) blockers.push(`RESIDUE ${fx.file}:${fx.line} new 里仍带缺陷标记「${bad}」`);
  }
}

// 干跑也要证明安全：在内存里把改动做完，再按测试口径核对题干覆盖。
const patched = new Map();
for (const [file, list] of planMd) {
  let text = read(file);
  for (const fx of list) text = text.split(fx.old).join(fx.new);
  patched.set(file, text);
}
let manifestText = read(manifestRel);
for (const fx of planManifest) manifestText = manifestText.split(fx.old).join(fx.new);

const manifest = JSON.parse(manifestText);
const bodyFor = new Map();
for (const cat of manifest.categories) {
  for (const lesson of cat.lessons || []) {
    if (!lesson || !lesson.file) continue;
    bodyFor.set(lesson.file, patched.get(lesson.file) || (fs.existsSync(path.join(root, lesson.file)) ? fs.readFileSync(path.join(root, lesson.file), 'utf8') : ''));
  }
}
let stemMiss = 0;
for (const cat of manifest.categories) {
  for (const lesson of cat.lessons || []) {
    const body = norm(bodyFor.get(lesson.file) || '');
    const items = [...(lesson.quiz || []), ...(Array.isArray(lesson.code_quiz) ? lesson.code_quiz : [])];
    for (const q of items) {
      const stem = norm(q.question || '');
      if (stem && !body.includes(stem)) {
        stemMiss += 1;
        if (stemMiss <= 5) blockers.push(`STEM-LOSS ${lesson.id} 题干在改后找不到：${(q.question || '').slice(0, 40)}`);
      }
    }
  }
}

const byClass = {};
for (const fx of fixes) byClass[fx.cls] = (byClass[fx.cls] || 0) + 1;
console.log(`清单 ${fixes.length} 条 / 覆盖 ${stats.lessons.size} 篇课文；按类别 ${JSON.stringify(byClass)}`);
console.log(`可应用：课文 ${stats.mdHits} 处（${planMd.size} 文件），manifest ${stats.manifestHits} 处，拦截 ${blockers.length} 条`);
for (const b of blockers) console.log('  ! ' + b);

if (blockers.length) {
  console.log(apply ? '有拦截项，未写盘。' : '干跑发现拦截项，请先复核。');
  process.exitCode = 1;
} else if (apply) {
  for (const [file, list] of planMd) {
    let text = read(file);
    for (const fx of list) text = text.split(fx.old).join(fx.new);
    fs.writeFileSync(path.join(root, file), text);
    console.log(`  写入 ${file}（${list.length} 条）`);
  }
  fs.writeFileSync(path.join(root, manifestRel), manifestText);
  console.log(`  写入 ${manifestRel}（${planManifest.length} 条，${stats.manifestHits} 处）`);
  console.log(`已应用 ${fixes.length} 条修复。`);
} else {
  console.log('干跑通过，题干覆盖不受影响。加 --apply 写盘。');
}
