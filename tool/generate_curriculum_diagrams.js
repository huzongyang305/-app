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

const DIAGRAMS = Object.assign(
  {},
  require('./curriculum_diagrams/p0_systems'),
  require('./curriculum_diagrams/p0_network'),
  require('./curriculum_diagrams/p0_data'),
  require('./curriculum_diagrams/p1_algorithms'),
  require('./curriculum_diagrams/p1_ai'),
  require('./curriculum_diagrams/p1_languages'),
);

const OUT_DIR = path.join(__dirname, '..', 'assets', 'content', 'images');
const BATCH_PATH = path.join(__dirname, 'image_batches', 'p0_p1_diagrams.json');

async function main() {
  const filters = process.argv.slice(2);
  const ids = Object.keys(DIAGRAMS).filter(
    (id) => filters.length === 0 || filters.some((filter) => id.includes(filter)),
  );
  if (ids.length === 0) {
    console.error(`没有匹配的图；可用：${Object.keys(DIAGRAMS).join(', ')}`);
    process.exitCode = 1;
    return;
  }

  fs.mkdirSync(OUT_DIR, { recursive: true });
  const batch = {};
  const failures = [];
  console.log(`生成 ${ids.length} 张图：`);
  for (const id of ids) {
    const def = DIAGRAMS[id];
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
    fs.mkdirSync(path.dirname(BATCH_PATH), { recursive: true });
    fs.writeFileSync(BATCH_PATH, `${JSON.stringify(batch, null, 2)}\n`);
    console.log(`批次文件：${BATCH_PATH}`);
  }
  console.log(`完成：成功 ${ids.length - failures.length}，失败 ${failures.length}`);
  if (failures.length > 0) process.exitCode = 1;
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
