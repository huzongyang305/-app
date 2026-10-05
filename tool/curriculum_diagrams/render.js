const {
  C,
  CONTENT_LEFT: LEFT,
  CONTENT_RIGHT: RIGHT,
  rect,
  text,
  box,
  arrow,
  leftText,
  title,
  caption,
  svg,
  fitSize,
  palette,
} = require('./framework');

function notesBlock(notes) {
  if (!notes || notes.length === 0) return '';
  return box(60, 525, 1140, 620, notes.join('    ·    '), {
    fill: C.surface,
    stroke: C.line,
    size: 19,
  });
}

function renderFlow(def) {
  const steps = def.steps || [];
  let body = title(def.title);
  if (steps.length === 0) return svg(body + caption(def.caption));

  if (def.direction === 'vertical') {
    const top = 108;
    const bottom = 618;
    const gap = 10;
    const height = (bottom - top - gap * (steps.length - 1)) / steps.length;
    steps.forEach((step, index) => {
      const y = top + index * (height + gap);
      const [fill, stroke] = palette(index);
      body += box(170, y, 1030, y + height, '', { fill, stroke });
      body += text(210, y + height / 2, step.title, {
        size: fitSize(step.title, 22, 12, 16),
        bold: true,
        anchor: 'start',
      });
      if (step.desc) {
        body += text(560, y + height / 2, step.desc, {
          size: fitSize(step.desc, 19, 28, 14),
          fill: C.muted,
          anchor: 'start',
        });
      }
      if (index < steps.length - 1) {
        body += arrow(600, y + height, 600, y + height + gap, { color: stroke, head: 9 });
      }
    });
    return svg(body + caption(def.caption));
  }

  const gap = 24;
  const width = (RIGHT - LEFT - gap * (steps.length - 1)) / steps.length;
  const top = 165;
  const bottom = 470;
  steps.forEach((step, index) => {
    const x = LEFT + index * (width + gap);
    const [fill, stroke] = palette(index);
    body += box(x, top, x + width, bottom, '', { fill, stroke });
    body += text(x + width / 2, top + 48, step.title, {
      size: fitSize(step.title, 23, Math.max(5, Math.floor(width / 15)), 16),
      bold: true,
    });
    if (step.desc) {
      body += text(x + width / 2, top + 135, step.desc, {
        size: fitSize(step.desc, 18, Math.max(8, Math.floor(width / 11)), 13),
        fill: C.muted,
      });
    }
    if (index < steps.length - 1) {
      body += arrow(x + width, (top + bottom) / 2, x + width + gap, (top + bottom) / 2, {
        color: stroke,
        head: 11,
      });
    }
  });
  return svg(body + notesBlock(def.notes) + caption(def.caption));
}

function renderLayers(def) {
  const layers = def.layers || [];
  let body = title(def.title);
  const top = 108;
  const bottom = 618;
  const gap = 10;
  const height = (bottom - top - gap * (layers.length - 1)) / layers.length;
  const widths = def.widths || [];
  layers.forEach((layer, index) => {
    const [defaultFill, defaultStroke] = palette(index);
    const maxWidth = RIGHT - LEFT - 120;
    const ratio = widths[index] || 1;
    const width = maxWidth * ratio;
    const center = (LEFT + RIGHT) / 2;
    const y = top + index * (height + gap);
    body += box(center - width / 2, y, center + width / 2, y + height, '', {
      fill: layer.fill || defaultFill,
      stroke: layer.stroke || defaultStroke,
    });
    body += text(center, y + height / 2 - (layer.desc ? 13 : 0), layer.title, {
      size: fitSize(layer.title, 22, 26, 16),
      bold: true,
    });
    if (layer.desc) {
      body += text(center, y + height / 2 + 20, layer.desc, {
        size: fitSize(layer.desc, 17, 46, 13),
        fill: C.muted,
      });
    }
    if (index < layers.length - 1) {
      body += arrow(center, y + height, center, y + height + gap, { color: C.line, head: 9 });
    }
  });
  return svg(body + caption(def.caption));
}

function renderCompare(def) {
  const columns = def.columns || [];
  let body = title(def.title);
  const gap = 22;
  const width = (RIGHT - LEFT - gap * (columns.length - 1)) / columns.length;
  const top = 125;
  const bottom = 620;
  columns.forEach((column, index) => {
    const [fill, stroke] = palette(index);
    const x = LEFT + index * (width + gap);
    body += rect(x, top, width, bottom - top, { fill, stroke });
    body += text(x + width / 2, top + 45, column.title, {
      size: fitSize(column.title, 23, Math.max(6, Math.floor(width / 16)), 16),
      bold: true,
    });
    body += `<line x1="${x + 20}" y1="${top + 78}" x2="${x + width - 20}" y2="${top + 78}" stroke="${stroke}" stroke-width="1.5"/>`;
    (column.items || []).slice(0, 6).forEach((item, itemIndex) => {
      const itemY = top + 118 + itemIndex * 72;
      body += text(x + 22, itemY, '●', { size: 14, fill: stroke, anchor: 'start' });
      body += text(x + 46, itemY, item, {
        size: fitSize(item, 19, Math.max(8, Math.floor(width / 11)), 13),
        anchor: 'start',
      });
    });
  });
  return svg(body + notesBlock(def.notes) + caption(def.caption));
}

function renderSequence(def) {
  const actors = def.actors || [];
  const messages = def.messages || [];
  let body = title(def.title);
  const gap = 34;
  const actorWidth = Math.min(250, (RIGHT - LEFT - gap * (actors.length - 1)) / actors.length);
  const totalWidth = actorWidth * actors.length + gap * (actors.length - 1);
  const startX = (LEFT + RIGHT - totalWidth) / 2;
  const actorX = actors.map((_, index) => startX + actorWidth / 2 + index * (actorWidth + gap));

  actors.forEach((actor, index) => {
    const [fill, stroke] = palette(index);
    body += box(actorX[index] - actorWidth / 2, 110, actorX[index] + actorWidth / 2, 180, actor, {
      fill,
      stroke,
      size: 20,
      bold: true,
    });
    body += `<line x1="${actorX[index]}" y1="180" x2="${actorX[index]}" y2="610" stroke="${C.line}" stroke-width="2" stroke-dasharray="7 7"/>`;
  });

  const step = messages.length > 1 ? 340 / (messages.length - 1) : 0;
  messages.forEach((message, index) => {
    const y = 235 + index * step;
    const color = message.color || C.primary;
    if (message.from === message.to) {
      const x = actorX[message.from];
      const loopWidth = 62;
      const loopHeight = 16;
      // 自消息：画一个回到自身生命线的回环，箭头指向自己，标签放在回环右侧。
      body += `<path d="M ${x} ${y - loopHeight} L ${x + loopWidth - 26} ${y - loopHeight} Q ${x + loopWidth} ${y - loopHeight}, ${x + loopWidth} ${y} Q ${x + loopWidth} ${y + loopHeight}, ${x + loopWidth - 26} ${y + loopHeight} L ${x + 10} ${y + loopHeight}" fill="none" stroke="${color}" stroke-width="3"/>`;
      body += arrow(x + 28, y + loopHeight, x + 8, y + loopHeight, { color, head: 10 });
      const rightLimit =
        message.from + 1 < actorX.length ? actorX[message.from + 1] - 40 : RIGHT - 10;
      const available = Math.max(110, rightLimit - (x + loopWidth + 16));
      body += leftText(x + loopWidth + 16, y, message.label, {
        size: fitSize(message.label, 17, Math.max(6, Math.floor(available / 16)), 13),
        fill: C.muted,
      });
    } else {
      body += arrow(actorX[message.from], y, actorX[message.to], y, {
        color,
        head: 11,
        label: message.label,
      });
    }
  });
  return svg(body + caption(def.caption));
}

function renderGrid(def) {
  const rows = def.rows || 0;
  const cols = def.cols || 0;
  const cells = def.cells || [];
  const colLabels = def.colLabels || [];
  const rowLabels = def.rowLabels || [];
  let body = title(def.title);
  const left = rowLabels.length > 0 ? LEFT + 150 : LEFT + 20;
  const top = colLabels.length > 0 ? 175 : 115;
  const right = RIGHT;
  const bottom = 615;
  const cellWidth = (right - left) / cols;
  const cellHeight = (bottom - top) / rows;

  for (let row = 0; row < rows; row += 1) {
    for (let col = 0; col < cols; col += 1) {
      body += rect(left + col * cellWidth, top + row * cellHeight, cellWidth, cellHeight, {
        fill: C.surface,
        stroke: '#e5e7eb',
        radius: 2,
        strokeWidth: 1.5,
      });
    }
  }
  colLabels.forEach((label, col) => {
    body += text(left + col * cellWidth + cellWidth / 2, top - 28, label, {
      size: fitSize(label, 20, 10, 14),
      bold: true,
      fill: C.muted,
    });
  });
  rowLabels.forEach((label, row) => {
    body += text(left - 18, top + row * cellHeight + cellHeight / 2, label, {
      size: fitSize(label, 20, 10, 14),
      bold: true,
      fill: C.muted,
      anchor: 'end',
    });
  });
  cells.forEach((cell) => {
    const x = left + cell.c * cellWidth;
    const y = top + cell.r * cellHeight;
    const width = cellWidth * (cell.colspan || 1);
    const height = cellHeight * (cell.rowspan || 1);
    if (cell.fill || cell.stroke) {
      body += rect(x + 2, y + 2, width - 4, height - 4, {
        fill: cell.fill || C.surface,
        stroke: cell.stroke || C.line,
        radius: 8,
      });
    }
    if (cell.text) {
      body += text(x + width / 2, y + height / 2, cell.text, {
        size: fitSize(cell.text, cell.size || 19, Math.max(5, Math.floor(width / 11)), 12),
        fill: cell.color || C.ink,
        bold: cell.bold,
      });
    }
  });
  return svg(body + notesBlock(def.notes) + caption(def.caption));
}

function renderCycle(def) {
  const nodes = def.nodes || [];
  let body = title(def.title);
  const centerX = 600;
  const centerY = 385;
  const radiusX = 385;
  const radiusY = 205;
  const halfW = 112;
  const halfH = 58;
  // 求节点中心连线与矩形卡片边框的交点，保证箭头停在卡片外侧而不是压住卡片。
  function borderPoint(from, to) {
    const dx = to.x - from.x;
    const dy = to.y - from.y;
    const scale = Math.min(
      halfW / Math.max(1, Math.abs(dx)),
      halfH / Math.max(1, Math.abs(dy)),
    );
    const gap = 12;
    const length = Math.hypot(dx, dy) || 1;
    return {
      x: from.x + dx * scale + (dx / length) * gap,
      y: from.y + dy * scale + (dy / length) * gap,
    };
  }
  const positions = nodes.map((_, index) => {
    const angle = -Math.PI / 2 + (index * Math.PI * 2) / nodes.length;
    return {
      x: centerX + radiusX * Math.cos(angle),
      y: centerY + radiusY * Math.sin(angle),
    };
  });
  positions.forEach((position, index) => {
    const next = positions[(index + 1) % positions.length];
    const start = borderPoint(position, next);
    const end = borderPoint(next, position);
    body += arrow(start.x, start.y, end.x, end.y, { color: C.line, head: 11 });
  });
  positions.forEach((position, index) => {
    const [fill, stroke] = palette(index);
    const label = nodes[index].desc
      ? `${nodes[index].title}\n${nodes[index].desc}`
      : nodes[index].title;
    body += box(position.x - halfW, position.y - halfH, position.x + halfW, position.y + halfH, label, {
      fill,
      stroke,
      size: fitSize(label, 19, 12, 14),
      bold: true,
    });
  });
  if (def.center) {
    body += box(centerX - 170, centerY - 58, centerX + 170, centerY + 58, def.center, {
      fill: C.surface,
      stroke: C.line,
      size: 21,
      bold: true,
    });
  }
  if (def.backLabel) {
    body += text(centerX, centerY + 96, def.backLabel, { size: 18, fill: C.muted });
  }
  return svg(body + caption(def.caption));
}

function countLeaves(node) {
  if (!node.children || node.children.length === 0) return 1;
  return node.children.reduce((sum, child) => sum + countLeaves(child), 0);
}

function treeDepth(node) {
  if (!node.children || node.children.length === 0) return 0;
  return 1 + Math.max(...node.children.map((child) => treeDepth(child)));
}

function renderTree(def) {
  let body = title(def.title);
  const root = def.root;
  if (!root) return svg(body + caption(def.caption));
  const leafCount = countLeaves(root);
  const positions = new Map();
  let leafIndex = 0;
  const top = 150;
  // 有说明框时，深层树的叶子必须收在说明框上方，避免节点与说明文字重叠。
  const bottom = def.notes && def.notes.length > 0 ? 468 : 560;
  const depth = treeDepth(root);
  const levelGap = depth > 0 ? (bottom - top) / depth : 0;
  const slotWidth = (RIGHT - LEFT - 100) / leafCount;

  function layout(node, level) {
    if (!node.children || node.children.length === 0) {
      const x = LEFT + 50 + (leafIndex + 0.5) * slotWidth;
      leafIndex += 1;
      positions.set(node, { x, y: top + level * levelGap });
      return;
    }
    node.children.forEach((child) => layout(child, level + 1));
    const children = node.children.map((child) => positions.get(child));
    const x = children.reduce((sum, item) => sum + item.x, 0) / children.length;
    positions.set(node, { x, y: top + level * levelGap });
  }
  layout(root, 0);

  function drawEdges(node) {
    const position = positions.get(node);
    (node.children || []).forEach((child) => {
      const childPosition = positions.get(child);
      body += `<line x1="${position.x}" y1="${position.y + 30}" x2="${childPosition.x}" y2="${childPosition.y - 30}" stroke="${C.line}" stroke-width="2.5"/>`;
      drawEdges(child);
    });
  }
  drawEdges(root);

  function drawNodes(node) {
    const position = positions.get(node);
    const [fill, stroke] = palette(position.y < 250 ? 0 : position.y < 420 ? 1 : 2);
    body += box(position.x - 92, position.y - 30, position.x + 92, position.y + 30, node.text, {
      fill: node.fill || fill,
      stroke: node.stroke || stroke,
      size: fitSize(node.text, 19, 10, 13),
      bold: true,
    });
    (node.children || []).forEach(drawNodes);
  }
  drawNodes(root);
  return svg(body + notesBlock(def.notes) + caption(def.caption));
}

function renderTimeline(def) {
  const tasks = def.tasks || [];
  const total = def.total || 10;
  let body = title(def.title);
  const labelWidth = 230;
  const left = LEFT + labelWidth + 24;
  const right = RIGHT;
  const top = 155;
  const bottom = 600;
  const rowHeight = Math.min(72, (bottom - top) / Math.max(1, tasks.length));

  for (let tick = 0; tick <= total; tick += 1) {
    const x = left + ((right - left) * tick) / total;
    body += `<line x1="${x}" y1="${top - 18}" x2="${x}" y2="${bottom}" stroke="#e5e7eb" stroke-width="1.5"/>`;
    body += text(x, top - 40, String(tick), { size: 16, fill: C.muted });
  }

  tasks.forEach((task, index) => {
    const y = top + index * rowHeight + rowHeight / 2;
    const [fill, stroke] = palette(index);
    body += text(LEFT + labelWidth, y, task.label, {
      size: fitSize(task.label, 20, 12, 14),
      bold: true,
      anchor: 'end',
    });
    const x1 = left + ((right - left) * task.start) / total;
    const x2 = left + ((right - left) * (task.start + task.duration)) / total;
    body += rect(x1, y - rowHeight * 0.3, Math.max(8, x2 - x1), rowHeight * 0.6, {
      fill,
      stroke,
      radius: 8,
    });
    if (task.desc) {
      body += text((x1 + x2) / 2, y, task.desc, {
        size: fitSize(task.desc, 16, 10, 12),
      });
    }
  });
  return svg(body + notesBlock(def.notes) + caption(def.caption));
}

function render(def) {
  switch (def.type) {
    case 'flow':
      return renderFlow(def);
    case 'layers':
      return renderLayers(def);
    case 'compare':
      return renderCompare(def);
    case 'sequence':
      return renderSequence(def);
    case 'grid':
      return renderGrid(def);
    case 'cycle':
      return renderCycle(def);
    case 'tree':
      return renderTree(def);
    case 'timeline':
      return renderTimeline(def);
    default:
      throw new Error(`未知布局类型：${def.type}`);
  }
}

module.exports = {
  render,
  renderFlow,
  renderLayers,
  renderCompare,
  renderSequence,
  renderGrid,
  renderCycle,
  renderTree,
  renderTimeline,
};
