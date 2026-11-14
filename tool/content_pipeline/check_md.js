// 快速自检：不依赖 manifest，只按 validate_pack 的课文口径扫一遍 md。
const fs = require('fs');
const CANON = [
  '本节知识框架', '核心概念定义', '原理与运行机制', '典型应用场景',
  '代码/协议/SQL 示例', '时间/空间复杂度或性能分析', '常见误区与易错点',
  '与其他知识点的关系', '自测题与参考答案', '考点精讲', '术语速查',
  '参考资料与复核', '内容元数据',
];
const PLACEHOLDERS = ['localhost', '127.0.0.1', 'example.com', 'example.org', 'your-server', 'your_api', '192.168.', '0.0.0.0', 'zh.wikipedia.org/wiki?'];

function maskFences(md) {
  let inFence = false;
  return md.split('\n').map((line) => {
    if (/^```/.test(line)) { inFence = !inFence; return line; }
    return inFence ? ' '.repeat(line.length) : line;
  }).join('\n');
}
function sectionOf(masked, title) {
  const re = new RegExp('^##\\s+' + title.replace(/[.*+?^${}()|[\]\\/]/g, '\\$&') + '\\s*$', 'm');
  const m = re.exec(masked);
  if (!m) return '';
  const rest = masked.slice(m.index + m[0].length);
  const next = /^##\s+/m.exec(rest);
  return next ? rest.slice(0, next.index) : rest;
}

for (const file of process.argv.slice(2)) {
  const raw = fs.readFileSync(file, 'utf8').replace(/\r\n/g, '\n');
  const masked = maskFences(raw);
  const problems = [];
  if (raw.length < 10500) problems.push(`chars ${raw.length} < 10500`);
  for (const c of CANON) {
    const n = (masked.match(new RegExp('^##\\s+' + c.replace(/[.*+?^${}()|[\]\\/]/g, '\\$&') + '\\s*$', 'gm')) || []).length;
    if (n !== 1) problems.push(`章节「${c}」出现 ${n} 次`);
  }
  const order = CANON.map((c) => masked.search(new RegExp('^##\\s+' + c.replace(/[.*+?^${}()|[\]\\/]/g, '\\$&') + '\\s*$', 'm')));
  if (order.some((i) => i < 0)) problems.push('有章节缺失，无法比对顺序');
  else if (order.join() !== [...order].sort((a, b) => a - b).join()) problems.push('章节顺序不对');
  if ((masked.match(/^\s*- \[ \] /gm) || []).length < 3) problems.push('复习清单不足 3 条');
  if ((masked.match(/^```/gm) || []).length % 2 !== 0) problems.push('围栏不成对');
  if (!/^```(?!text|markdown)[A-Za-z0-9_+-]+/m.test(masked)) problems.push('无带语言标记代码块');
  if (!raw.includes('内容更新时间：2026-10-06')) problems.push('缺内容更新时间');
  if (!raw.includes('内容版本：v2.0')) problems.push('缺内容版本 v2.0');
  const refs = [...new Set([...sectionOf(masked, '参考资料与复核').matchAll(/\[[^\]]+\]\((https?:\/\/[^)\s]+)\)/g)].map((m) => m[1]))];
  if (refs.length < 2) problems.push(`参考链接 ${refs.length} 条 < 2`);
  for (const p of PLACEHOLDERS) if (raw.includes(p)) problems.push(`占位域名 ${p}`);
  const glossaryRows = sectionOf(masked, '术语速查').split('\n').filter((l) => l.trimStart().startsWith('|')).length;
  if (glossaryRows - 2 < 4) problems.push(`术语速查 ${glossaryRows - 2} 条 < 4`);
  const img = [...raw.matchAll(/!\[[^\]]*\]\((images\/[^)]+)\)/g)].map((m) => m[1]);
  if (img.length === 0) problems.push('没有配图');
  const quizHeads = (masked.match(/^### 题目 \d+（[^）]+）/gm) || []).length;
  const points = (masked.match(/^### 考点 \d+（[^）]+）/gm) || []).length;
  console.log(`\n### ${file}  ${raw.length} 字符 · 题目 ${quizHeads} · 考点 ${points} · 配图 ${img.join(',') || '无'}`);
  console.log('  链接: ' + refs.join(' '));
  console.log(problems.length ? problems.map((p) => '  x ' + p).join('\n') : '  ✓ 课文自检通过');
}
