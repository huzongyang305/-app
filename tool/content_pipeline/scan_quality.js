const fs = require('fs');
const path = require('path');
const DIR = 'F:/app/assets/content';
const manifest = JSON.parse(fs.readFileSync(path.join(DIR, 'manifest.json'), 'utf8'));
const FENCE = String.fromCharCode(96, 96, 96);

function mask(md) {
  const lines = md.split('\n');
  let f = false;
  return lines.map((l) => {
    if (l.trimLeft().startsWith(FENCE)) { f = !f; return ' '.repeat(l.length); }
    return f ? ' '.repeat(l.length) : l;
  }).join('\n');
}
function section(md, title) {
  const re = new RegExp('^##\\s+' + title.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '\\s*$', 'm');
  const m = re.exec(md);
  if (!m) return '';
  const rest = md.slice(m.index + m[0].length);
  const nx = /^##\s+/m.exec(rest);
  return nx ? rest.slice(0, nx.index) : rest;
}
const stats = { header: {}, checklist: [], links: [] };
for (const c of manifest.categories) {
  for (const l of c.lessons) {
    const f = path.join(DIR, path.basename(l.file));
    if (!fs.existsSync(f)) continue;
    const md = mask(fs.readFileSync(f, 'utf8'));
    const gloss = section(md, '术语速查').split('\n').map((x) => x.trim()).find((x) => x.startsWith('|')) || '(none)';
    stats.header[gloss] = (stats.header[gloss] || 0) + 1;
    const items = (md.match(/^- \[ \] /gm) || []).length;
    if (items < 3) stats.checklist.push(l.id + '=' + items);
    const links = (md.match(/https?:\/\//g) || []).length;
    if (links < 2) stats.links.push(l.id + '=' + links);
  }
}
console.log('glossary headers:');
Object.entries(stats.header).sort((a, b) => b[1] - a[1]).forEach(([k, v]) => console.log('  ' + v + ' | ' + k));
console.log('checklist<3:', stats.checklist.length, stats.checklist.slice(0, 20).join(','));
console.log('links<2:', stats.links.length, stats.links.slice(0, 30).join(','));
