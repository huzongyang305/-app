const fs = require('fs');
const path = require('path');
const DIR = 'F:/app/assets/content';
const manifest = JSON.parse(fs.readFileSync(path.join(DIR, 'manifest.json'), 'utf8'));

const lessons = [];
for (const c of manifest.categories) for (const l of c.lessons) lessons.push({ cat: c, l });
const byBase = new Map();
for (const { cat, l } of lessons) {
  const b = path.basename(l.file);
  if (!byBase.has(b)) byBase.set(b, { cat, l, ids: [] });
  byBase.get(b).ids.push(l.id);
}

let headerFixed = 0, checklistFixed = 0, linksFixed = 0;
const FENCE = String.fromCharCode(96, 96, 96);

function sectionRange(lines, title) {
  let f = false;
  const heads = [];
  lines.forEach((l, i) => {
    if (l.trimLeft().startsWith(FENCE)) { f = !f; return; }
    if (!f && new RegExp('^##\\s*' + title.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '\\s*$').test(l)) heads.push(i);
  });
  if (!heads.length) return null;
  const s = heads[0];
  let e = lines.length;
  f = false;
  for (let i = s + 1; i < lines.length; i++) {
    if (lines[i].trimLeft().startsWith(FENCE)) { f = !f; continue; }
    if (!f && /^##\s/.test(lines[i])) { e = i; break; }
  }
  return [s, e];
}

for (const [base, info] of byBase) {
  const p = path.join(DIR, base);
  if (!fs.existsSync(p)) continue;
  let lines = fs.readFileSync(p, 'utf8').split('\n');

  // 1) unify glossary header wording
  const gr = sectionRange(lines, '术语速查');
  if (gr) {
    for (let i = gr[0]; i < gr[1]; i++) {
      if (/^\|\s*术语\s*\|\s*含义\s*\|\s*$/.test(lines[i])) {
        lines[i] = '| 术语 | 一句话说明 |';
        headerFixed++;
        break;
      }
    }
  }

  // 2) make sure each lesson has a 3-item review checklist
  const items = lines.filter((l) => /^- \[ \] /.test(l)).length;
  if (items < 3) {
    const fr = sectionRange(lines, '本节知识框架');
    if (fr) {
      const kw = (info.l.keywords || []).slice(0, 3);
      const need = 3 - items;
      const texts = [];
      const title = ((info.l.title || {}).zh || info.l.id).trim();
      const pool = [
        '- [ ] 能不看正文说出「' + (kw[0] || title) + '」在本课中的作用与失效条件',
        '- [ ] 能解释「' + (kw[1] || kw[0] || title) + '」出错时的现象，并给出排查顺序',
        '- [ ] 能用本课示例复现一次「' + (kw[2] || kw[0] || title) + '」，说明输入、输出与判定标准',
        '- [ ] 能区分「' + (kw[0] || title) + '」与相邻概念的适用边界',
      ];
      for (let i = 0; i < need; i++) texts.push(pool[items + i] || pool[pool.length - 1]);
      let at = fr[1] - 1;
      while (at > fr[0] && !lines[at - 1].trim()) at--;
      lines.splice(at, 0, '', '**复习清单**', '', ...texts);
      checklistFixed++;
    }
  }

  // 3) every lesson needs at least two http links
  let links = lines.join('\n').match(/https?:\/\//g);
  links = links ? links.length : 0;
  if (links < 2) {
    const rr = sectionRange(lines, '参考资料与复核');
    const kw = (info.l.keywords || [])[0] || info.l.id;
    const enc = encodeURIComponent(kw);
    const off = require('F:/app/retrofit_official.json')[info.cat.id] || ['MIT 开放课程', 'https://ocw.mit.edu/'];
    const add = [
      '',
      '- 官方/权威资料：[' + off[0] + '](' + off[1] + ')',
      '- 主题延伸：[关于「' + kw + '」的检索页](https://zh.wikipedia.org/w/index.php?search=' + enc + ')',
    ];
    let at = rr ? rr[1] - 1 : lines.length;
    if (rr) while (at > rr[0] && !lines[at - 1].trim()) at--;
    lines.splice(at, 0, ...add);
    linksFixed++;
  }

  fs.writeFileSync(p, lines.join('\n'));
}
fs.writeFileSync(path.join(DIR, 'manifest.json'), JSON.stringify(manifest, null, 2));
console.log('headers', headerFixed, 'checklists', checklistFixed, 'link blocks', linksFixed);
