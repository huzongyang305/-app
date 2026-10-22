/**
 * P0/P1 课程配图渲染框架。
 *
 * 所有图都用数据描述、由固定布局渲染，保证：
 *   · 风格统一、可复现，不依赖 AI 生成；
 *   · 中文字体由系统字体渲染；
 *   · 需要改内容时只改数据，不改绘图代码。
 *
 * 支持布局：flow / layers / compare / sequence / grid / cycle / tree / timeline。
 */
const C = {
  ink: '#1f2937',
  muted: '#6b7280',
  primary: '#6c8ff8',
  primarySoft: '#e7eeff',
  accent: '#0ea5e9',
  accentSoft: '#e0f2fe',
  warn: '#f59e0b',
  warnSoft: '#fef3c7',
  green: '#16a34a',
  greenSoft: '#dcfce7',
  red: '#dc2626',
  redSoft: '#fee2e2',
  violet: '#7c3aed',
  violetSoft: '#ede9fe',
  line: '#9ca3af',
  surface: '#f9fafb',
  white: '#ffffff',
};

const FONT = 'Microsoft YaHei, Noto Sans SC, PingFang SC, sans-serif';
const WIDTH = 1200;
const HEIGHT = 720;
const CONTENT_LEFT = 60;
const CONTENT_RIGHT = 1140;
const CONTENT_TOP = 100;
const CONTENT_BOTTOM = 645;

function escapeXml(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function rect(x, y, w, h, options = {}) {
  const fill = options.fill || C.surface;
  const stroke = options.stroke || C.line;
  const radius = options.radius === undefined ? 12 : options.radius;
  const strokeWidth = options.strokeWidth === undefined ? 2 : options.strokeWidth;
  return `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${radius}" ry="${radius}" fill="${fill}" stroke="${stroke}" stroke-width="${strokeWidth}"/>`;
}

function text(x, y, value, options = {}) {
  const size = options.size || 22;
  const fill = options.fill || C.ink;
  const weight = options.weight || 400;
  const anchor = options.anchor || 'middle';
  const lineHeight = options.lineHeight || Math.round(size * 1.45);
  const lines = Array.isArray(value) ? value : String(value).split('\n');
  const firstY = lines.length === 1 ? y : y - ((lines.length - 1) * lineHeight) / 2;
  const spans = lines
    .map((line, index) => {
      const dy = index === 0 ? 0 : lineHeight;
      return `<tspan x="${x}" dy="${dy}">${escapeXml(line)}</tspan>`;
    })
    .join('');
  return `<text x="${x}" y="${firstY}" font-family="${FONT}" font-size="${size}" font-weight="${weight}" fill="${fill}" text-anchor="${anchor}" dominant-baseline="middle">${spans}</text>`;
}

function box(x1, y1, x2, y2, value, options = {}) {
  const shape = rect(x1, y1, x2 - x1, y2 - y1, options);
  const label = text((x1 + x2) / 2, (y1 + y2) / 2, value, {
    size: options.size || 22,
    fill: options.textColor || C.ink,
    weight: options.bold ? 700 : 400,
  });
  return shape + label;
}

function arrow(x1, y1, x2, y2, options = {}) {
  const color = options.color || C.line;
  const strokeWidth = options.width || 3;
  const head = options.head || 13;
  const line = `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${color}" stroke-width="${strokeWidth}" stroke-linecap="round"/>`;
  let tip;
  if (x1 === x2) {
    const direction = y2 > y1 ? 1 : -1;
    tip = `<polygon points="${x2},${y2} ${x2 - head * 0.6},${y2 - direction * head} ${x2 + head * 0.6},${y2 - direction * head}" fill="${color}"/>`;
  } else {
    const direction = x2 > x1 ? 1 : -1;
    tip = `<polygon points="${x2},${y2} ${x2 - direction * head},${y2 - head * 0.6} ${x2 - direction * head},${y2 + head * 0.6}" fill="${color}"/>`;
  }
  if (!options.label) return line + tip;
  const midX = (x1 + x2) / 2;
  const midY = (y1 + y2) / 2;
  const labelWidth = Math.max(44, [...String(options.label)].length * 14 + 14);
  const span = Math.hypot(x2 - x1, y2 - y1);
  // 标签比箭头还宽时，白底会把整条线盖住；这种情况把标签挪到线上方。
  if (labelWidth > span * 0.62) {
    return line + tip + text(midX, midY - 22, options.label, {
      size: options.labelSize || 17,
      fill: C.muted,
    });
  }
  const badge = `<rect x="${midX - labelWidth / 2}" y="${midY - 15}" width="${labelWidth}" height="30" rx="6" fill="${C.white}"/>`;
  return line + tip + badge + text(midX, midY, options.label, { size: options.labelSize || 17, fill: C.muted });
}

function leftText(x, y, value, options = {}) {
  return text(x, y, value, { ...options, anchor: 'start' });
}

function title(value) {
  const size = [...String(value)].length > 26 ? 30 : 34;
  return (
    `<text x="40" y="52" font-family="${FONT}" font-size="${size}" font-weight="700" fill="${C.ink}" dominant-baseline="middle">${escapeXml(value)}</text>` +
    `<line x1="40" y1="78" x2="1160" y2="78" stroke="#e5e7eb" stroke-width="2"/>`
  );
}

function caption(value) {
  return value ? text(WIDTH / 2, 678, value, { size: 19, fill: C.muted }) : '';
}

function svg(body) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${WIDTH}" height="${HEIGHT}" viewBox="0 0 ${WIDTH} ${HEIGHT}"><rect width="${WIDTH}" height="${HEIGHT}" fill="${C.white}"/>${body}</svg>`;
}

function longestLine(value) {
  return Math.max(...String(value).split('\n').map((line) => [...line].length));
}

/**
 * 估算一行文本的像素宽度：中日韩字符按 1 个字宽计算，其余按 0.55 估算。
 * 中英混排时按字符数估算会明显偏小，导致文字溢出卡片。
 */
function textWidth(value, size) {
  let width = 0;
  for (const char of String(value)) {
    width += char.codePointAt(0) > 0x2e80 ? size : size * 0.55;
  }
  return width;
}

function fitSize(value, baseSize, maxChars, minSize) {
  const longest = longestLine(value);
  if (longest <= maxChars) return baseSize;
  return Math.max(minSize, Math.floor((baseSize * maxChars) / longest));
}

/** 按可用像素宽度收缩字号，避免中英混排文本溢出容器。 */
function fitWidth(value, baseSize, maxWidth, minSize) {
  const lines = String(value).split('\n');
  const widest = Math.max(...lines.map((line) => textWidth(line, baseSize)));
  if (widest <= maxWidth) return baseSize;
  return Math.max(minSize, Math.floor((baseSize * maxWidth) / widest));
}

function palette(index) {
  const options = [
    [C.primarySoft, C.primary],
    [C.accentSoft, C.accent],
    [C.greenSoft, C.green],
    [C.warnSoft, C.warn],
    [C.violetSoft, C.violet],
    [C.redSoft, C.red],
  ];
  return options[index % options.length];
}

module.exports = {
  C,
  FONT,
  WIDTH,
  HEIGHT,
  CONTENT_LEFT,
  CONTENT_RIGHT,
  CONTENT_TOP,
  CONTENT_BOTTOM,
  escapeXml,
  rect,
  text,
  box,
  arrow,
  leftText,
  title,
  caption,
  svg,
  longestLine,
  textWidth,
  fitSize,
  fitWidth,
  palette,
};
