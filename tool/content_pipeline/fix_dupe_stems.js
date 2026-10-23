const fs = require('fs');
const path = require('path');
const DIR = 'F:/app/assets/content';
const MP = path.join(DIR, 'manifest.json');
const manifest = JSON.parse(fs.readFileSync(MP, 'utf8'));
const OLD = '以下代码有什么问题？';
const NEW = {
  frontend_react_hooks: '阅读下面的 React 组件代码，它违反了哪条 Hooks 规则？',
  frontend_vue_composition: '在 Vue 3 组合式 API 中，下面这段解构 reactive 对象的代码有什么问题？',
  frontend_angular_basics: '这段 Angular 组件在模板里直接调用 getData()，会带来什么问题？',
  frontend_nextjs_ssr: 'Next.js 的 getServerSideProps 里读取 window.innerWidth，运行时会发生什么？',
};
const all = new Set();
for (const c of manifest.categories) for (const l of c.lessons) for (const q of l.quiz || []) all.add(String(q.question).replace(/\s+/g, ''));
for (const v of Object.values(NEW)) {
  if (all.has(v.replace(/\s+/g, ''))) { console.log('COLLISION', v); process.exit(1); }
}
let files = 0;
for (const c of manifest.categories) {
  for (const l of c.lessons) {
    if (!NEW[l.id]) continue;
    let changed = false;
    for (const q of l.quiz || []) {
      if (String(q.question).includes(OLD)) { q.question = NEW[l.id]; changed = true; }
    }
    if (!changed) { console.log('no manifest hit', l.id); continue; }
    const p = path.join(DIR, path.basename(l.file));
    let md = fs.readFileSync(p, 'utf8');
    const n = md.split(OLD).length - 1;
    md = md.split(OLD).join(NEW[l.id]);
    fs.writeFileSync(p, md);
    files++;
    console.log(l.id, 'replaced', n, 'occurrences');
  }
}
fs.writeFileSync(MP, JSON.stringify(manifest, null, 2));
console.log('files', files);
