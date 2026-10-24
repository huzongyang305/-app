// wave31：题库解析里引用的「出现字面量 `X`」等断言，必须是该题真实选项的原文。
// 前面几波把干扰项补长或改写过文案，解析尾部却还是旧形式（大多末尾标点被写成了逗号），
// 于是学员在解析里看到的断言在选项里根本不存在。这里按「去尾部标点相同」把解析改回选项原文。
// 用法：node tool/content_pipeline/wave31_explanation_mentions.js [--apply]
import fs from 'node:fs';
import path from 'node:path';

const ROOT = 'F:/app';
const MANIFEST = path.join(ROOT, 'assets/content/manifest.json');
const APPLY = process.argv.includes('--apply');

const norm = (s) => String(s || '').replace(/[\s`]/g, '');
const stem = (s) => norm(s).replace(/[，。、；：！？,.;:!?）)】」』\]]+$/, '');
const MENTION = /(调用了|出现字面量|代码里出现了)\s*`([^`]+)`/g;

const raw = fs.readFileSync(MANIFEST, 'utf8');
const eol = raw.includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(raw);

const fixes = [];
const unresolved = [];
for (const category of manifest.categories) {
  for (const lesson of category.lessons) {
    let markdown = '';
    const mdPath = path.join(ROOT, lesson.file);
    if (fs.existsSync(mdPath)) markdown = fs.readFileSync(mdPath, 'utf8').replace(/\r\n/g, '\n');
    (lesson.quiz || []).forEach((q, qi) => {
      if (q.type !== 'code' && q.type !== 'debug') return;
      const options = (q.options || []).map(String);
      const explanation = String(q.explanation || '');
      if (!explanation) return;
      const mentions = [...explanation.matchAll(MENTION)];
      let next = explanation;
      let changed = false;
      for (const mention of mentions) {
        const want = norm(`${mention[1]}${mention[2]}`);
        if (options.some((o) => norm(o).includes(want))) continue;
        const best = options.find((o) => stem(o) === stem(`${mention[1]} ${mention[2]}`));
        if (!best) { unresolved.push(`${lesson.id}#${qi}｜${mention[0]}`); continue; }
        next = next.split(mention[0]).join(best);
        changed = true;
        fixes.push(`${lesson.id}#${qi}｜「${mention[0]}」→「${best}」`);
      }
      if (!changed) return;
      if (!APPLY) return;
      q.explanation = next;
      let patched = markdown;
      for (const m of mentions) {
        const best = options.find((o) => stem(o) === stem(`${m[1]} ${m[2]}`));
        if (best && patched.includes(m[0])) patched = patched.split(m[0]).join(best);
      }
      if (patched !== markdown && patched.replace(/\s/g, '').length >= markdown.replace(/\s/g, '').length - 60) {
        markdown = patched;
        fs.writeFileSync(mdPath, patched.split('\n').join(eol));
      }
    });
  }
}

if (APPLY) fs.writeFileSync(MANIFEST, JSON.stringify(manifest, null, 2).split('\n').join(eol));
console.log(fixes.join('\n') || '（无）');
if (unresolved.length) console.log('无法对应到选项：\n' + unresolved.join('\n'));
console.log(`解析断言引用改写 ${fixes.length}｜无法对应 ${unresolved.length}`);
if (!APPLY) console.log('（dry-run，加 --apply 才写盘）');
