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
  ruankao_net_security: {
    image: 'diagram_ruankao_net_security.webp',
    alt: 'OSI 与 TCP/IP 分层、加密体系与安全设备位置的总体框架',
    title: '分层定位置，密钥定能力，设备定可见性',
    type: 'grid',
    rows: 3,
    cols: 4,
    rowLabels: ['分层与端口', '密码体制', '边界与检测'],
    colLabels: ['要点', '典型对象', '易错点', '考场问法'],
    cells: [
      { r: 0, c: 0, text: 'OSI 七层对 TCP/IP 四层' },
      { r: 0, c: 1, text: '443 HTTPS、22 SSH、53 DNS' },
      { r: 0, c: 2, text: '会话层与表示层不单设', bold: true },
      { r: 0, c: 3, text: '协议—端口—传输层三项配对' },
      { r: 1, c: 0, text: '对称快、非对称慢、哈希给指纹' },
      { r: 1, c: 1, text: 'AES/SM4、RSA/SM2、SHA-256' },
      { r: 1, c: 2, text: 'MAC 无法对外作证', bold: true },
      { r: 1, c: 3, text: '谁加密谁解密、签名不管机密性' },
      { r: 2, c: 0, text: '防火墙守边界、IDS 旁路、IPS 串联' },
      { r: 2, c: 1, text: 'DMZ、镜像口、安全关联 SA' },
      { r: 2, c: 2, text: 'GRE 与 L2TP 本身不加密', bold: true },
      { r: 2, c: 3, text: '设备在哪一段决定能看见什么' },
    ],
    notes: [
      '三区模型：外网 / DMZ / 内网，DMZ 到内网只开必需端口且禁止主动外联',
      '混合体制：非对称保护会话密钥，对称加密数据本体',
      '第三级及以上系统每年测评一次，网络日志留存不少于六个月',
    ],
    caption: '先站好位置（分层与设备），再发对钥匙（密钥归属），最后留够证据（日志、备份与法定义务）。',
  },
  ruankao_ood_uml: {
    image: 'diagram_ruankao_ood_uml.webp',
    alt: '面向对象三大特征、UML 两类十四图与设计模式三族的总体框架',
    title: '三特征、两类图、三族模式',
    type: 'grid',
    rows: 3,
    cols: 4,
    rowLabels: ['三大特征', 'UML 十四图', '模式与原则'],
    colLabels: ['回答的问题', '要点清单', '易错判分点', '下午题落点'],
    cells: [
      { r: 0, c: 0, text: '改动怎么被限制住' },
      { r: 0, c: 1, text: '封装定契约、继承复用、多态扩展' },
      { r: 0, c: 2, text: '引用类型决定可调方法集合', bold: true },
      { r: 0, c: 3, text: '补类图关系与多重性' },
      { r: 1, c: 0, text: '从哪个角度看系统' },
      { r: 1, c: 1, text: '结构图 6 种、行为图 8 种' },
      { r: 1, c: 2, text: '用例图归行为图', bold: true },
      { r: 1, c: 3, text: '画用例图并标 include 与 extend' },
      { r: 2, c: 0, text: '谁依赖谁、改动落在哪' },
      { r: 2, c: 1, text: '创建 5、结构 7、行为 11' },
      { r: 2, c: 2, text: '判分看意图不看形状', bold: true },
      { r: 2, c: 3, text: '按模式说明设计理由' },
    ],
    notes: [
      '耦合强度链：依赖 < 关联 < 聚合 < 组合 < 泛化 ≈ 实现',
      'SOLID：单一职责、开闭、里氏替换、接口隔离、依赖倒置',
      '重构信号：重复代码、过长函数、发散式变化、霰弹式修改、循环依赖',
    ],
    caption: '三大特征说明代码为什么这样组织，十四张图规定从哪个角度看系统，模式与原则给解耦手法起名字。',
  },
};

module.exports = Object.fromEntries(
  Object.entries(diagrams).map(([id, def]) => [
    id,
    { width: 900, quality: 60, ...def },
  ]),
);
