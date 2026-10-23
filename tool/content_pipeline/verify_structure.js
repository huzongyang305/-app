const fs = require('fs');
const cur = 'F:/app/assets/content';
const bak = 'F:/app/assets/content_backup_20261023';
const req = ['本节知识框架','核心概念定义','原理与运行机制','典型应用场景','代码/协议/SQL 示例','时间/空间复杂度或性能分析','常见误区与易错点','与其他知识点的关系','自测题与参考答案','考点精讲','术语速查','参考资料与复核','内容元数据'];
const fence = String.fromCharCode(96, 96, 96);
function mask(t) {
  const lines = t.split(/\r?\n/);
  let inF = false; const out = [];
  for (const l of lines) {
    if (l.startsWith(fence)) { inF = !inF; out.push(''); continue; }
    out.push(inF ? '' : l);
  }
  return out.join('\n');
}
function countHeading(m, s) {
  const re = new RegExp('^## \\s*' + s.replace(/[\/]/g, '\\$&'), 'm');
  const all = s.replace(/[\/]/g, '\\$&');
  return (m.match(new RegExp('^##(?!#)\\s*' + all, 'gm')) || []).length;
}
let problems = [];
const files = fs.readdirSync(cur).filter(f => f.endsWith('.md'));
for (const f of files) {
  const b = fs.readFileSync(bak + '/' + f, 'utf8');
  const c = fs.readFileSync(cur + '/' + f, 'utf8');
  const mb = mask(b), mc = mask(c);
  for (const s of req) {
    const nb = countHeading(mb, s), nc = countHeading(mc, s);
    if (nb >= 1 && nc < 1) problems.push(f + ': lost section ' + s);
    if (nb === 1 && nc > 1) problems.push(f + ': duplicated section ' + s + ' (' + nc + ')');
  }
  if (b.includes('内容更新时间：2026-10-06') && !c.includes('内容更新时间：2026-10-06'))
    problems.push(f + ': lost update-time marker');
}
console.log('problems:', problems.length);
problems.slice(0, 30).forEach(p => console.log(' ', p));
// leftover template check
let leftover = 0;
for (const f of files) {
  const c = mask(fs.readFileSync(cur + '/' + f, 'utf8'));
  if (/### (从概念到验证的学习链条|完成判据|机制拆解|复现实验记录)/.test(c)) leftover++;
}
console.log('files still containing template H3s:', leftover);
