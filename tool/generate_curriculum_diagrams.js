#!/usr/bin/env node
/**
 * 生成 P0/P1 课程机制配图（SVG -> WebP）。
 *
 * 一次性准备（不写入仓库）：
 *   npm install --prefix %TEMP%\code_learn_diagram_tools sharp
 *
 * 用法：
 *   node tool/generate_curriculum_diagrams.js            # 生成全部 98 张
 *   node tool/generate_curriculum_diagrams.js cpu tls    # 只生成名称包含关键字的图
 *   node tool/generate_curriculum_diagrams.js --group=p2 # 只生成 P2 分组并写出其批次文件
 *
 * 全量生成时会同时写出批次文件：
 *   tool/image_batches/p0_p1_diagrams.json
 * 再用 Dart 工具把图片引用插入教程：
 *   dart tool/insert_lesson_image.dart tool/image_batches/p0_p1_diagrams.json
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
const { render } = require('./curriculum_diagrams/render');

// 分组：p0p1 是第一批机制图，p2 是工程实践类补充；默认合并生成。
const GROUPS = {
  p0p1: [
    './curriculum_diagrams/p0_systems',
    './curriculum_diagrams/p0_network',
    './curriculum_diagrams/p0_data',
    './curriculum_diagrams/p1_algorithms',
    './curriculum_diagrams/p1_ai',
    './curriculum_diagrams/p1_languages',
  ],
  p2: [
    './curriculum_diagrams/p2_toolchain',
    './curriculum_diagrams/p2_shell',
    './curriculum_diagrams/p2_se',
    './curriculum_diagrams/p2_project',
    './curriculum_diagrams/p2_cross',
  ],
  p3: [
    './curriculum_diagrams/p3_python',
    './curriculum_diagrams/p3_java',
    './curriculum_diagrams/p3_js',
  ],
  p4: [
    './curriculum_diagrams/p4_fundamentals',
    './curriculum_diagrams/p4_algorithms',
    './curriculum_diagrams/p4_database',
    './curriculum_diagrams/p4_ai',
  ],
};

// 分组到批次文件名的映射；p0p1 沿用历史文件名，避免流程中断。
const BATCH_NAMES = {
  p0p1: 'p0_p1_diagrams.json',
  p2: 'p2_diagrams.json',
  p3: 'p3_diagrams.json',
  p4: 'p4_diagrams.json',
};

function loadGroup(name) {
  return Object.assign({}, ...GROUPS[name].map((file) => require(file)));
}

const DIAGRAMS = Object.assign(
  {},
  loadGroup('p0p1'),
  loadGroup('p2'),
  loadGroup('p3'),
  loadGroup('p4'),
);

const OUT_DIR = path.join(__dirname, '..', 'assets', 'content', 'images');

async function main() {
  const rawArgs = process.argv.slice(2);
  const groupArg = rawArgs.find((arg) => arg.startsWith('--group='));
  const groupName = groupArg ? groupArg.slice('--group='.length) : null;
  if (groupName && !GROUPS[groupName]) {
    console.error(`未知分组 ${groupName}；可用：${Object.keys(GROUPS).join(', ')}`);
    process.exitCode = 1;
    return;
  }
  const diagrams = groupName ? loadGroup(groupName) : DIAGRAMS;
  const filters = rawArgs.filter((arg) => !arg.startsWith('--'));
  // 未指定分组时保持原来的批次文件名，避免影响既有流程。
  const batchPath = path.join(
    __dirname,
    'image_batches',
    groupName
      ? BATCH_NAMES[groupName] || `${groupName}_diagrams.json`
      : 'p0_p1_diagrams.json',
  );
  const ids = Object.keys(diagrams).filter(
    (id) => filters.length === 0 || filters.some((filter) => id.includes(filter)),
  );
  if (ids.length === 0) {
    console.error(`没有匹配的图；可用：${Object.keys(diagrams).join(', ')}`);
    process.exitCode = 1;
    return;
  }

  fs.mkdirSync(OUT_DIR, { recursive: true });
  const batch = {};
  const failures = [];
  console.log(`生成 ${ids.length} 张图：`);
  for (const id of ids) {
    const def = diagrams[id];
    try {
      const output = path.join(OUT_DIR, def.image);
      const info = await sharp(Buffer.from(render(def)))
        .webp({ quality: 92, effort: 5 })
        .toFile(output);
      batch[id] = { image: `images/${def.image}`, alt: def.alt };
      console.log(`  ${id} -> ${path.basename(output)} (${Math.round(info.size / 1024)} KB)`);
    } catch (error) {
      failures.push({ id, message: error.message });
      console.error(`  失败 ${id}：${error.message}`);
    }
  }

  if (filters.length === 0 && failures.length === 0) {
    fs.mkdirSync(path.dirname(batchPath), { recursive: true });
    fs.writeFileSync(batchPath, `${JSON.stringify(batch, null, 2)}\n`);
    console.log(`批次文件：${batchPath}`);
  }
  console.log(`完成：成功 ${ids.length - failures.length}，失败 ${failures.length}`);
  if (failures.length > 0) process.exitCode = 1;
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
