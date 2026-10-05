#!/usr/bin/env node
/**
 * 生成 P2 机制配图（SVG -> WebP）。
 *
 * 为什么不复用 generate_diagrams.py：
 *   Python/Pillow 不在所有开发机上可用；本脚本只依赖 Node 与 sharp，
 *   风格、画布尺寸和配色与 Python 生成器保持一致。
 *
 * 一次性准备（不写入仓库）：
 *   npm install --prefix %TEMP%\code_learn_diagram_tools sharp
 *
 * 用法：
 *   node tool/generate_diagrams_webp.js                # 生成全部机制图
 *   node tool/generate_diagrams_webp.js dns tcp        # 只生成名称包含关键字的图
 *
 * 输出目录：assets/content/images/*.webp
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
const OUT_DIR = path.join(__dirname, '..', 'assets', 'content', 'images');

// 与 assets/content/images 中已有配图完全一致的配色。
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
  line: '#9ca3af',
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

function rect(x, y, w, h, options = {}) {
  const fill = options.fill || C.surface;
  const stroke = options.stroke || C.line;
  const radius = options.radius === undefined ? 14 : options.radius;
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
  const head = options.head || 14;
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
  const labelWidth = String(options.label).length * (options.labelSize || 18) * 0.62 + 12;
  const labelHeight = (options.labelSize || 18) + 10;
  const badge = `<rect x="${midX - labelWidth / 2}" y="${midY - labelHeight / 2}" width="${labelWidth}" height="${labelHeight}" rx="6" fill="${C.white}"/>`;
  const label = text(midX, midY, options.label, {
    size: options.labelSize || 18,
    fill: C.muted,
  });
  return line + tip + badge + label;
}

function leftText(x, y, value, options = {}) {
  return text(x, y, value, { ...options, anchor: 'start' });
}

function title(value) {
  return (
    `<text x="40" y="52" font-family="${FONT}" font-size="34" font-weight="700" fill="${C.ink}" dominant-baseline="middle">${escapeXml(value)}</text>` +
    `<line x1="40" y1="78" x2="1160" y2="78" stroke="#e5e7eb" stroke-width="2"/>`
  );
}

function caption(value) {
  return text(WIDTH / 2, 680, value, { size: 20, fill: C.muted });
}

function svg(body) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${WIDTH}" height="${HEIGHT}" viewBox="0 0 ${WIDTH} ${HEIGHT}"><rect width="${WIDTH}" height="${HEIGHT}" fill="${C.white}"/>${body}</svg>`;
}

// ---------------------------------------------------------------- 机制配图

function dns_resolution() {
  const stages = [
    ['浏览器缓存\n命中即返回', C.primarySoft, C.primary],
    ['系统 DNS 缓存\n与 hosts 文件', C.accentSoft, C.accent],
    ['递归解析器\n代表客户端查询', C.greenSoft, C.green],
    ['根 → 顶级域\n→ 权威服务器', C.warnSoft, C.warn],
  ];
  let body = title('DNS 解析：从域名到 IP 的查询链');
  stages.forEach(([label, fill, stroke], index) => {
    const x = 55 + index * 285;
    body += box(x, 135, x + 235, 235, label, { fill, stroke, size: 21 });
    if (index < stages.length - 1) {
      body += arrow(x + 235, 185, x + 285, 185);
    }
  });
  body += leftText(60, 300, '递归解析器的查询过程', { size: 24, weight: 700 });
  ['根服务器\n返回 .com 的地址', 'TLD 服务器\n返回权威服务器', '权威服务器\n返回 A/AAAA 记录'].forEach(
    (label, index) => {
      const x = 70 + index * 370;
      body += box(x, 355, x + 330, 465, label, { fill: C.surface, stroke: C.line, size: 21 });
      if (index < 2) body += arrow(x + 330, 410, x + 370, 410);
    },
  );
  body += leftText(60, 520, '缓存决定了真实延迟：TTL 越长越省查询，变更生效越慢。', { size: 22, fill: C.muted });
  body += leftText(60, 565, '排查顺序：浏览器缓存 → 系统缓存 → 递归解析器 → 权威记录。', { size: 22, fill: C.muted });
  return svg(body + caption('用 dig +trace 观察每一跳，不要只看最终返回值'));
}

function tcp_handshake() {
  let body = title('TCP 三次握手与连接状态');
  body += box(90, 125, 360, 205, '客户端\nCLOSED → SYN_SENT', { fill: C.primarySoft, stroke: C.primary, size: 21 });
  body += box(840, 125, 1110, 205, '服务端\nLISTEN → SYN_RCVD', { fill: C.greenSoft, stroke: C.green, size: 21 });
  body += `<line x1="225" y1="205" x2="225" y2="610" stroke="${C.line}" stroke-width="2"/>`;
  body += `<line x1="975" y1="205" x2="975" y2="610" stroke="${C.line}" stroke-width="2"/>`;
  body += arrow(225, 265, 975, 265, { color: C.primary, label: 'SYN seq=x' });
  body += arrow(975, 355, 225, 355, { color: C.green, label: 'SYN+ACK seq=y ack=x+1' });
  body += arrow(225, 445, 975, 445, { color: C.accent, label: 'ACK ack=y+1' });
  body += box(420, 500, 780, 600, '双方确认：\n发送与接收能力都可用，连接建立', { fill: C.warnSoft, stroke: C.warn, size: 21 });
  return svg(body + caption('为什么不是两次：第三次 ACK 才能确认服务端的 SYN 被收到'));
}

function virtual_memory_paging() {
  let body = title('虚拟内存分页：页表负责地址翻译');
  body += box(60, 135, 300, 555, '虚拟地址空间\n\n页 0\n页 1\n页 2\n页 3\n…', { fill: C.primarySoft, stroke: C.primary, size: 22 });
  body += box(420, 180, 740, 510, '页表 Page Table\n\nVPN → PFN\n权限位 R/W/X\n有效位 valid\n脏位 dirty', { fill: C.accentSoft, stroke: C.accent, size: 21 });
  body += box(870, 135, 1130, 555, '物理内存\n\n帧 7\n帧 2\n未分配\n帧 9\n…', { fill: C.greenSoft, stroke: C.green, size: 22 });
  body += arrow(300, 290, 420, 290, { label: '查表' });
  body += arrow(740, 340, 870, 340, { label: '映射' });
  body += box(240, 580, 960, 660, 'TLB 命中直接得到物理地址；缺页时触发 page fault\n由内核换入页面，局部性好才能控制缺页成本', { fill: C.warnSoft, stroke: C.warn, size: 20 });
  return svg(body + caption('局部性好 → 命中率高 → 真实程序不必把整个地址空间放进内存'));
}

function cache_hierarchy() {
  const levels = [
    ['寄存器', '~1 周期 · 几十个', C.primarySoft, C.primary],
    ['L1 / L2 缓存', '~4~15 周期 · KB~MB', C.accentSoft, C.accent],
    ['L3 缓存', '~30~50 周期 · 几 MB~几十 MB', C.greenSoft, C.green],
    ['主存 DRAM', '~100~300 周期 · GB 级', C.warnSoft, C.warn],
    ['SSD / 磁盘', '微秒~毫秒 · TB 级', C.surface, C.line],
  ];
  let body = title('存储层次：速度、容量与成本的权衡');
  levels.forEach(([label, desc, fill, stroke], index) => {
    const left = 80 + index * 40;
    const right = 1120 - index * 40;
    const top = 125 + index * 100;
    body += box(left, top, right, top + 76, `${label}\n${desc}`, { fill, stroke, size: 21 });
  });
  return svg(body + caption('越往上越快越小越贵；缓存命中率决定程序是否被内存延迟拖住'));
}

function process_thread() {
  let body = title('进程与线程：资源所有权和执行流');
  body += box(70, 125, 560, 590, '进程 Process\n\n独立虚拟地址空间\n代码 / 数据 / 堆\n打开的文件与信号\n至少一个主线程', { fill: C.primarySoft, stroke: C.primary, size: 23 });
  ['线程 1\n程序计数器\n栈 / 寄存器', '线程 2\n程序计数器\n栈 / 寄存器', '线程 3\n程序计数器\n栈 / 寄存器'].forEach(
    (label, index) => {
      const y = 180 + index * 125;
      body += box(650, y, 1120, y + 95, label, {
        fill: index === 0 ? C.greenSoft : C.accentSoft,
        stroke: index === 0 ? C.green : C.accent,
        size: 20,
      });
    },
  );
  body += leftText(70, 620, '线程共享代码、堆和文件；线程私有 PC、寄存器与栈。', { size: 22, fill: C.muted });
  return svg(body + caption('切换线程比切换进程轻，但共享数据必须同步'));
}

function deadlock() {
  let body = title('死锁四条件：循环等待一旦形成就无法推进');
  const positions = [
    [210, 135],
    [790, 135],
    [790, 485],
    [210, 485],
  ];
  const labels = ['互斥\n资源不可共享', '占有并等待\n拿着 A 等 B', '不可抢占\n不能强行夺走', '循环等待\n互相等对方释放'];
  positions.forEach(([x, y], index) => {
    body += box(x, y, x + 200, y + 120, labels[index], { fill: C.warnSoft, stroke: C.warn, size: 21 });
  });
  body += arrow(410, 195, 790, 195, { color: C.warn, head: 12 });
  body += arrow(890, 255, 890, 485, { color: C.warn, head: 12 });
  body += arrow(790, 545, 410, 545, { color: C.warn, head: 12 });
  body += arrow(310, 485, 310, 255, { color: C.warn, head: 12 });
  body += leftText(60, 640, '破解任一条件即可预防：统一加锁顺序、超时回退、资源预分配。', { size: 22, fill: C.muted });
  return svg(body + caption('发现死锁后看重启成本：先止血，再补可观测性和锁顺序约束'));
}

function big_o() {
  let body = title('复杂度增长：输入变大后谁先失控');
  const originX = 130;
  const originY = 590;
  body += `<line x1="${originX}" y1="110" x2="${originX}" y2="${originY}" stroke="${C.ink}" stroke-width="3"/>`;
  body += `<line x1="${originX}" y1="${originY}" x2="1120" y2="${originY}" stroke="${C.ink}" stroke-width="3"/>`;
  const curves = [
    ['O(1)', 505, C.green],
    ['O(log n)', 430, C.accent],
    ['O(n)', 340, C.primary],
    ['O(n log n)', 240, C.warn],
    ['O(n²)', 130, '#dc2626'],
  ];
  curves.forEach(([label, endY, color]) => {
    body += `<line x1="${originX + 20}" y1="510" x2="880" y2="${endY}" stroke="${color}" stroke-width="5" stroke-linecap="round"/>`;
    body += text(900, endY, label, { size: 20, weight: 700, fill: color, anchor: 'start' });
  });
  body += leftText(145, 620, '输入规模 n →', { size: 20, fill: C.muted });
  body += leftText(45, 95, '运行时间', { size: 20, fill: C.muted });
  return svg(body + caption('复杂度只描述增长趋势；常数、缓存和实现细节决定同阶算法的实际差距'));
}

function hash_table() {
  let body = title('哈希表：哈希函数把键映射到桶');
  body += box(60, 180, 310, 320, '键 key\nalice\nbob\ncarol', { fill: C.primarySoft, stroke: C.primary, size: 23 });
  body += box(410, 200, 650, 300, '哈希函数\nh(key) % N', { fill: C.accentSoft, stroke: C.accent, size: 23 });
  body += arrow(310, 250, 410, 250);
  for (let index = 0; index < 5; index += 1) {
    const y = 130 + index * 100;
    const highlight = index === 1 || index === 3;
    const suffix = index === 3 ? '\n→ alice → carol' : index === 1 ? '\n→ bob' : '';
    body += box(760, y, 1120, y + 70, `桶 ${index}${suffix}`, {
      fill: highlight ? C.greenSoft : C.surface,
      stroke: highlight ? C.green : C.line,
      size: 20,
    });
  }
  body += arrow(650, 250, 760, 250, { label: '定位' });
  body += leftText(60, 400, '冲突处理：链地址法把同桶元素串成链表；开放寻址法按探测序列找下一个空位。', { size: 21 });
  body += leftText(60, 470, '负载因子升高会拉长查找链，通常需要在扩容和内存之间做取舍。', { size: 21, fill: C.muted });
  return svg(body + caption('平均 O(1) 的前提是哈希均匀、负载因子受控、键不可变'));
}

function acid_transaction() {
  let body = title('数据库事务：ACID 与提交边界');
  const stages = [
    ['BEGIN', '开启事务\n记录起始点', C.primary],
    ['UPDATE', '写日志 WAL\n修改页缓存', C.accent],
    ['CHECK', '约束与锁检查\n冲突等待/回滚', C.warn],
    ['COMMIT', '日志落盘\n标记提交', C.green],
  ];
  stages.forEach(([stageTitle, desc, color], index) => {
    const x = 60 + index * 290;
    body += box(x, 150, x + 240, 300, `${stageTitle}\n\n${desc}`, { fill: C.surface, stroke: color, size: 22, bold: true });
    if (index < stages.length - 1) body += arrow(x + 240, 225, x + 290, 225, { color, head: 12 });
  });
  body += box(60, 360, 1120, 465, 'A 原子性：全做或全不做    C 一致性：约束始终成立\nI 隔离性：并发事务互不看到中间态    D 持久性：提交后故障不丢', { fill: C.primarySoft, stroke: C.primary, size: 23 });
  body += leftText(60, 520, '隔离级别的本质：在并发异常和数据一致性之间选择代价。', { size: 22, fill: C.muted });
  body += leftText(60, 570, '读未提交、读已提交、可重复读、串行化，越往后隔离越强、并发越低。', { size: 22, fill: C.muted });
  return svg(body + caption('先写日志再改数据：崩溃恢复靠 redo/undo 日志重放'));
}

function cap_theorem() {
  let body = title('CAP 与分布式取舍：网络分区时只能保两边');
  const points = [
    [600, 130],
    [250, 560],
    [950, 560],
  ];
  const labels = ['C 一致性\n所有节点看到同一份数据', 'A 可用性\n每个请求都能得到响应', 'P 分区容忍\n网络断开仍能继续运行'];
  const colors = [C.primary, C.green, C.warn];
  body += `<line x1="${points[0][0]}" y1="${points[0][1]}" x2="${points[1][0]}" y2="${points[1][1]}" stroke="${C.line}" stroke-width="3"/>`;
  body += `<line x1="${points[1][0]}" y1="${points[1][1]}" x2="${points[2][0]}" y2="${points[2][1]}" stroke="${C.line}" stroke-width="3"/>`;
  body += `<line x1="${points[2][0]}" y1="${points[2][1]}" x2="${points[0][0]}" y2="${points[0][1]}" stroke="${C.line}" stroke-width="3"/>`;
  points.forEach(([x, y], index) => {
    body += box(x - 180, y - 60, x + 180, y + 60, labels[index], { fill: C.surface, stroke: colors[index], size: 21 });
  });
  body += box(420, 300, 780, 400, '真实系统：\n分区期间在 C 与 A 之间取舍，恢复后再收敛', { fill: C.warnSoft, stroke: C.warn, size: 21 });
  body += leftText(60, 640, '不要问“选哪两个”，先问：分区概率、业务能否降级、数据能否合并。', { size: 22, fill: C.muted });
  return svg(body + caption('大多数业务需要的是分区期间的可控降级，而不是口号式 CAP'));
}

function transformer_attention() {
  let body = title('Transformer 注意力：每个 token 重新分配关注');
  ['我', '喜欢', '学习', '编程'].forEach((token, index) => {
    const x = 60 + index * 135;
    body += box(x, 130, x + 115, 200, token, { fill: C.primarySoft, stroke: C.primary, size: 23 });
  });
  body += leftText(60, 245, '输入 token → 生成 Q / K / V 三组向量', { size: 22 });
  ['Q\n查询', 'K\n键', 'V\n值'].forEach((label, index) => {
    const x = 90 + index * 340;
    body += box(x, 300, x + 270, 405, label, { fill: C.accentSoft, stroke: C.accent, size: 24 });
  });
  body += box(100, 470, 1100, 570, 'Attention(Q,K,V) = softmax(QKᵀ / √d) · V\n每个 token 根据相关性对其他 token 的 V 做加权求和', { fill: C.greenSoft, stroke: C.green, size: 22 });
  body += leftText(60, 610, '多头注意力让模型同时学习语法、指代、位置和语义等多组关系。', { size: 21, fill: C.muted });
  return svg(body + caption('上下文越长，注意力的计算与 KV 缓存成本越高'));
}

function agent_loop() {
  let body = title('AI Agent 循环：观察、计划、行动、反思');
  const stages = [
    ['观察\n读取任务与工具结果', C.primarySoft, C.primary],
    ['计划\n拆解目标与下一步', C.accentSoft, C.accent],
    ['行动\n调用工具/执行代码', C.greenSoft, C.green],
    ['反思\n校验结果与修正', C.warnSoft, C.warn],
  ];
  stages.forEach(([label, fill, stroke], index) => {
    const x = 80 + index * 285;
    body += box(x, 160, x + 235, 300, label, { fill, stroke, size: 22 });
    if (index < stages.length - 1) body += arrow(x + 235, 230, x + 285, 230, { head: 12 });
  });
  body += arrow(1015, 300, 1015, 500, { head: 12 });
  body += arrow(1015, 500, 195, 500, { head: 12 });
  body += arrow(195, 500, 195, 300, { head: 12, label: '未完成则继续' });
  body += box(320, 390, 900, 465, '停止条件：任务完成 / 预算耗尽 / 需要人工确认', { fill: C.surface, stroke: C.line, size: 20 });
  body += leftText(60, 560, '记忆提供上下文，工具提供行动能力，护栏限制危险操作和无限循环。', { size: 22, fill: C.muted });
  return svg(body + caption('工程重点不是“会聊天”，而是可观测、可评测、可回滚的闭环'));
}

const DIAGRAMS = {
  dns_resolution,
  tcp_handshake,
  virtual_memory_paging,
  cache_hierarchy,
  process_thread,
  deadlock,
  big_o,
  hash_table,
  acid_transaction,
  cap_theorem,
  transformer_attention,
  agent_loop,
};

async function main() {
  const filters = process.argv.slice(2);
  const names = Object.keys(DIAGRAMS).filter(
    (name) => filters.length === 0 || filters.some((filter) => name.includes(filter)),
  );
  if (names.length === 0) {
    console.error(`没有匹配的图；可用：${Object.keys(DIAGRAMS).join(', ')}`);
    process.exitCode = 1;
    return;
  }

  fs.mkdirSync(OUT_DIR, { recursive: true });
  console.log(`生成 ${names.length} 张图：`);
  for (const name of names) {
    const output = path.join(OUT_DIR, `${name}.webp`);
    const info = await sharp(Buffer.from(DIAGRAMS[name]()))
      .webp({ quality: 92, effort: 5 })
      .toFile(output);
    console.log(`  生成 ${output}  (${Math.round(info.size / 1024)} KB)`);
  }
  console.log('完成');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
