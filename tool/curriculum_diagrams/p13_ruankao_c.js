// P13 软考批次 C（数据库系统、网络安全、面向对象与 UML）课程配图数据。
// 键为 lesson_id，供 tool/generate_curriculum_diagrams.js --group=p13_ruankao_c 使用。
// 与 p12_ruankao_b.js 同一口径：统一 900px、WebP 质量 60，控制 APK 体积。
const diagrams = {
  ruankao_db_and_sql: {
    image: 'diagram_ruankao_db_and_sql.webp',
    alt: '数据库三级模式两级映像与规范化判定的主线',
    title: '三级模式与两级映像：谁挡在谁前面',
    type: 'layers',
    layers: [
      { title: '外模式（子模式 / 视图）', desc: '某个应用能看到的那部分逻辑结构，一个模式可以有多个' },
      { title: '模式（逻辑模式）', desc: '全部数据的逻辑结构与约束，一个数据库只有唯一一个' },
      { title: '内模式（存储模式）', desc: '存几份、放哪里、用什么索引与压缩方式，与模式一一对应' },
    ],
    widths: [0.86, 1, 0.86],
    notes: [
      '外模式与模式映像 → 逻辑独立性：属性增减、关系拆分时程序可不动',
      '模式与内模式映像 → 物理独立性：换索引、换存储结构时程序不用改',
      '规范化判定链：求候选键 → 查非主属性部分依赖 → 查传递依赖 → 查决定因素是否含键',
      'SELECT 逻辑次序：FROM → JOIN/ON → WHERE → GROUP BY → HAVING → SELECT/DISTINCT → ORDER BY',
    ],
    caption: '「改动波及谁」两句话说完：内模式变了靠模式与内模式映像兜住，模式变了靠外模式与模式映像兜住。',
  },
};

module.exports = Object.fromEntries(
  Object.entries(diagrams).map(([id, def]) => [
    id,
    { width: 900, quality: 60, ...def },
  ]),
);
