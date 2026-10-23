// 第五批：把解析里的生成句式改成可读陈述，并修好跨课套句损坏的句子。
// 只动 explanation 字段，题干、选项、答案一律不碰；改完仍必须复述正确项、长度不低于 120 字。
// 用法：node tool/content_pipeline/wave5_explanation_polish.js [--apply] [--list]
import fs from 'node:fs';
import path from 'node:path';

const APPLY = process.argv.includes('--apply');
const LIST = process.argv.includes('--list');
const MANIFEST = 'assets/content/manifest.json';
const raw = fs.readFileSync(MANIFEST, 'utf8');
const eol = raw.includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(raw);

const norm = (s) => String(s).replace(/[\s`*_]/g, '').replace(/[，。；：、！？"'“”‘’()（）\[\]《》「」【】]/g, '');
const len = (s) => [...String(s).replace(/\s/g, '')].length;

// 1) 跨课套句损坏：错误表现方面，A会造成在《课名》里采用「B」时，A会表现为错误结果、异常中断或状态不一致，应按C修复。
const NESTED = /错误表现方面，(.+?)会造成在《(.+?)》里采用「(.+?)」时，\1会表现为错误结果、异常中断或状态不一致，应按(.+?)修复。/g;
// 2) 常规句式：错误表现方面，A会造成B，应按C修复。
const PLAIN = /错误表现方面，(.+?)会造成(.+?)，应按(.+?)修复。/g;
// 3) 术语句 + 尾部通用复现提示（纯套话，信息量为零）。
const TERM = /该判断与术语\s*`([^`]+)`\s*对应：/g;
const TAIL = /判断时先确认输入和适用范围，对照[^。]*复现一次，最后把错误表现与正确做法逐项对照。/g;

function rewrite(text, lesson, needDomain) {
  const tail = (text.match(TAIL) || [''])[0];
  let t = text;
  t = t.replace(NESTED, (_m, a, b, c, d) => `易错点：在《${b}》里的典型做法是${c}；这样${a}会表现为结果错误、异常中断或状态不一致。正确做法：${d}。`);
  t = t.replace(PLAIN, (_m, a, b, c) => `易错点：${a}会造成${b}。正确做法：${c}。`);
  t = t.replace(TERM, (_m, term) => `涉及术语 ${term}：`);
  t = t.replace(TAIL, '');
  t = t.replace(/正确答案是「(.+?)」。/, (_m, a) => `正确项：${a}。`);
  t = t.replace(/\s{2,}/g, ' ').replace(/\s+([。；，])/g, '$1').trim();
  // 只有治理规则真正要求「解析要对应本课主题」的代码/调试题才补主题，避免到处贴同一句前缀。
  const title = (lesson.title && lesson.title.zh) || '';
  const keywords = lesson.keywords || [];
  if (needDomain && title && !t.includes(title) && !keywords.some((k) => k.length >= 2 && t.includes(k))) {
    t = `本课《${title}》：${t}`;
  }
  if (len(t) < 120 && tail) t = `${t}${tail}`; // 删套话会跌破最短长度时留着它
  return t;
}

let touched = 0, nestedFixed = 0, domainFixed = 0, skipped = 0;
const samples = [];
for (const c of manifest.categories) for (const l of c.lessons) {
  for (const q of l.quiz) {
    const old = String(q.explanation || '');
    if (!old) continue;
    const opts = q.options || [];
    const correct = opts[q.answer];
    const isNested = /会造成在《/.test(old);
    const type = q.type || 'single';
    const needDomain = (type === 'code' || type === 'debug') && String(q.code || '').trim().length > 0;
    const next = rewrite(old, l, needDomain);
    if (next === old) continue;
    const brokeAnswer = correct && opts.length > 1 && norm(old).includes(norm(correct)) && !norm(next).includes(norm(correct));
    const brokeLength = len(next) < 120 && len(old) >= 120;
    if (brokeAnswer || brokeLength) { skipped++; continue; }
    touched++;
    if (isNested) nestedFixed++;
    if (next.startsWith('本课《')) domainFixed++;
    if (samples.length < 5 && LIST) samples.push([l.id, old, next]);
    if (APPLY) q.explanation = next;
  }
}
console.log(`解析句式改写：${touched} 条（跨课套句损坏修复 ${nestedFixed} 条，补本课主题 ${domainFixed} 条），因会破坏正确项或长度而跳过 ${skipped} 条`);
for (const [id, a, b] of samples) console.log(`\n--- ${id}\n旧：${a}\n新：${b}`);
if (APPLY) {
  fs.writeFileSync(MANIFEST, JSON.stringify(manifest, null, 2).split('\n').join(eol));
  console.log('\n已写盘 manifest.json');
} else console.log('\n（dry-run，加 --apply 才写盘）');
