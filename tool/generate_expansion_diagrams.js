#!/usr/bin/env node
/**
 * P1 扩展课程配图生成：把工具/expansion_specs/*.json 里的课程画成统一风格示意图。
 *
 * 依赖 sharp（与 tool/generate_diagrams_webp.js 相同）：
 *   npm install --prefix %TEMP%\code_learn_diagram_tools sharp
 *
 * 用法：
 *   node tool/generate_expansion_diagrams.js            # 生成全部缺失配图
 *   node tool/generate_expansion_diagrams.js --force    # 覆盖已有配图
 *   node tool/generate_expansion_diagrams.js blockchain # 只生成文件名包含关键字的图
 *
 * 输出：assets/content/images/lesson_<id>.webp
 */
const fs = require('fs');
const path = require('path');

function loadSharp() {
  try {
    return require('sharp');
  } catch (error) {
    const fallback = path.join(
      process.env.TEMP || '',
      'code_learn_diagram_tools',
      'node_modules',
      'sharp',
    );
    return require(fallback);
  }
}

const sharp = loadSharp();
const ROOT = path.join(__dirname, '..');
const SPEC_DIR = path.join(__dirname, 'expansion_specs');
const OUT_DIR = path.join(ROOT, 'assets', 'content', 'images');

const C = {
  ink: '#1f2937',
  muted: '#6b7280',
  primary: '#2563eb',
  primarySoft: '#e7eeff',
  accent: '#0891b2',
  accentSoft: '#e0f2fe',
  green: '#16a34a',
  greenSoft: '#dcfce7',
  warn: '#f59e0b',
  warnSoft: '#fef3c7',
  line: '#d1d5db',
  surface: '#f9fafb',
  white: '#ffffff',
};

const FONT = 'Microsoft YaHei, Noto Sans SC, PingFang SC, sans-serif';
const WIDTH = 1200;
const HEIGHT = 720;

function escapeXml(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function text(x, y, value, options = {}) {
  const size = options.size || 22;
  const weight = options.bold ? 700 : 400;
  const fill = options.fill || C.ink;
  const anchor = options.anchor || 'start';
  return `<text x="${x}" y="${y}" font-family="${FONT}" font-size="${size}" font-weight="${weight}" fill="${fill}" text-anchor="${anchor}">${escapeXml(value)}</text>`;
}

function wrap(value, width) {
  const source = String(value).trim();
  const lines = [];
  for (let i = 0; i < source.length; i += width) {
    lines.push(source.slice(i, i + width));
  }
  return lines.length ? lines : [''];
}

function roundedBox(x, y, w, h, options = {}) {
  const fill = options.fill || C.white;
  const stroke = options.stroke || C.line;
  return `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${options.radius || 14}" fill="${fill}" stroke="${stroke}" stroke-width="${options.width || 2}"/>`;
}

function arrow(x1, y1, x2, y2, color = C.line) {
  return `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${color}" stroke-width="3" marker-end="url(#arrowhead)"/>`;
}

function svg(body) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${WIDTH}" height="${HEIGHT}" viewBox="0 0 ${WIDTH} ${HEIGHT}">
  <defs>
    <marker id="arrowhead" markerWidth="10" markerHeight="8" refX="8" refY="4" orient="auto">
      <path d="M0,0 L10,4 L0,8 z" fill="${C.line}"/>
    </marker>
  </defs>
  <rect width="${WIDTH}" height="${HEIGHT}" fill="${C.white}"/>
  ${body}
</svg>`;
}

function renderLesson(spec) {
  const title = spec.title.zh;
  const category = spec.category;
  const concepts = (spec.concepts || []).slice(0, 4);
  const steps = (spec.steps || []).slice(0, 4);
  const parts = [];

  parts.push(text(48, 58, title.length > 24 ? title.slice(0, 24) : title, { size: 32, bold: true }));
  parts.push(text(48, 92, `${category} · ${spec.difficulty || '基础'} · 预计 ${spec.minutes || 30} 分钟`, { size: 17, fill: C.muted }));
  parts.push(`<line x1="48" y1="112" x2="1152" y2="112" stroke="${C.line}" stroke-width="2"/>`);

  const palette = [
    [C.primarySoft, C.primary],
    [C.accentSoft, C.accent],
    [C.greenSoft, C.green],
    [C.warnSoft, C.warn],
  ];
  concepts.forEach((concept, index) => {
    const y = 134 + index * 92;
    const [fill, stroke] = palette[index % palette.length];
    parts.push(roundedBox(48, y, 1104, 74, { fill, stroke, width: 2 }));
    parts.push(`<circle cx="86" cy="${y + 37}" r="20" fill="${stroke}"/>`);
    parts.push(text(86, y + 45, String(index + 1), { size: 20, bold: true, fill: C.white, anchor: 'middle' }));
    const lines = wrap(concept.name, 26).slice(0, 2);
    lines.forEach((line, lineIndex) => {
      parts.push(text(122, y + (lines.length === 1 ? 47 : 30 + lineIndex * 26), line, { size: 21, bold: true }));
    });
    const detail = wrap(concept.plain || '', 44)[0] || '';
    parts.push(text(470, y + 45, detail, { size: 17, fill: C.muted }));
  });

  const flowY = 522;
  steps.forEach((step, index) => {
    const x = 48 + index * 276;
    parts.push(roundedBox(x, flowY, 240, 76, { fill: C.surface, stroke: C.line, radius: 12 }));
    const lines = wrap(step, 15).slice(0, 2);
    lines.forEach((line, lineIndex) => {
      parts.push(text(x + 120, flowY + (lines.length === 1 ? 46 : 32 + lineIndex * 24), line, { size: 16, fill: C.ink, anchor: 'middle' }));
    });
    if (index < steps.length - 1) {
      parts.push(arrow(x + 240, flowY + 38, x + 274, flowY + 38));
    }
  });

  parts.push(text(600, 654, (spec.summary && spec.summary.zh) || '', { size: 18, fill: C.muted, anchor: 'middle' }));
  parts.push(text(600, 688, '先跑通最小示例，再做单变量实验，最后补齐失败与恢复路径', { size: 16, fill: C.muted, anchor: 'middle' }));
  return svg(parts.join('\n'));
}

async function main() {
  const force = process.argv.includes('--force');
  const filters = process.argv.slice(2).filter((arg) => !arg.startsWith('--'));
  fs.mkdirSync(OUT_DIR, { recursive: true });
  const specs = [];
  for (const file of fs.readdirSync(SPEC_DIR)) {
    if (!file.endsWith('.json')) continue;
    const json = JSON.parse(fs.readFileSync(path.join(SPEC_DIR, file), 'utf8'));
    for (const lesson of json.lessons || []) specs.push(lesson);
  }

  let generated = 0;
  let skipped = 0;
  for (const spec of specs) {
    if (filters.length && !filters.some((filter) => spec.id.includes(filter))) continue;
    const out = path.join(OUT_DIR, `lesson_${spec.id}.webp`);
    if (fs.existsSync(out) && !force) {
      skipped++;
      continue;
    }
    const image = await sharp(Buffer.from(renderLesson(spec))).webp({ quality: 82 }).toBuffer();
    fs.writeFileSync(out, image);
    generated++;
  }
  console.log(`配图生成 ${generated} 张，跳过已有 ${skipped} 张`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
