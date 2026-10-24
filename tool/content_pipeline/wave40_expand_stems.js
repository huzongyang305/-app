/*
 * wave40_expand_stems.js
 * 把 89 条「短题干」补全为可独立作答的完整问句：题干只写「X 的作用是？」时，
 * 学员脱离课文就看不出问的是哪门课哪个概念。题库与课文考点精讲同步改写。
 * 用法：node tool/content_pipeline/wave40_expand_stems.js [--apply] [--show]
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const CONTENT = path.join(ROOT, 'assets', 'content');
const APPLY = process.argv.includes('--apply');
const SHOW = process.argv.includes('--show');

// [课时 id, 题号, 新题干]
const STEMS = [
  ['toolchain_project', 1, '关于服务密钥与凭据的存放位置，下列哪种做法是正确的？'],
  ['flutter_basics', 1, '渲染条目很多、长度可能不定的列表时，应该选择哪种方案？'],
  ['memory_cache', 4, '在分页式虚拟内存中，TLB（转换后备缓冲器）的作用是什么？'],
  ['probability', 4, '样本量不断增大时，大数定律对样本均值作出了什么保证？'],
  ['visual_btree_index', 3, '在数据库索引优化里，「覆盖索引」指的是下面哪种情况？'],
  ['cpp_templates', 2, 'C++ 模板换来通用性的同时，主要付出的代价是什么？'],
  ['performance_metrics', 2, '容量规划时一味提升吞吐量，通常会对单次延迟造成什么影响？'],
  ['os_project', 1, '后台服务实现优雅退出时，必须做到下面哪一点？'],
  ['ai_data_engineering', 0, '关于合成数据的使用范围，下列哪种说法是恰当的？'],
  ['distributed_short_url_project', 2, '做容量估算时，应该依据什么来推算需要的服务实例数？'],
  ['se_tdd_refactor', 2, '编写不易随重构失效的测试时，断言对象应该落在哪一层？'],
  ['se_postmortem', 0, '组织一次故障复盘时，应当坚持的核心原则是什么？'],
  ['math_calculus_gradient', 2, '梯度下降训练中，学习率设置得过大通常会导致什么后果？'],
  ['css_basics', 1, '在 CSS 里用 rem 作长度单位时，它是相对什么来计算的？'],
  ['java_project_order_concurrency', 2, '调用下游失败后的重试策略里，为什么必须配合退避？'],
  ['js_types', 1, '在 JavaScript 中，表达式 1 === \'1\' 的求值结果是什么？'],
  ['rust_project_axum_api', 3, 'HTTP 服务收到退出信号后，优雅关闭应当完成哪件事？'],
  ['binary_intro', 0, '在计算机里，一个字节（byte）由多少个二进制位组成？'],
  ['compiler', 4, '关于即时编译（JIT），下列哪种说法准确描述了它的含义？'],
  ['compiler_frontend', 2, '词法分析阶段遵循的「最长匹配」原则指的是什么？'],
  ['performance_metrics', 3, '监控面板写着「P95 延迟 = 200ms」，这个数字表示什么？'],
  ['fundamentals_project', 3, '排查程序启动失败时，ldd 命令能帮我们看清什么信息？'],
  ['graphics_media', 4, '关于图像的色域与位深，下列哪种区分方式是正确的？'],
  ['discrete_math_set_theory', 2, '在集合运算的律式中，下列哪一个等式是不成立的？'],
  ['compiler_gc', 1, '分代垃圾回收里，写屏障（write barrier）主要解决什么问题？'],
  ['compiler_bytecode_vm', 1, '在字节码虚拟机中，常量池起到的主要作用是什么？'],
  ['backtracking', 3, '回溯搜索里常说的「剪枝」，起的是下面哪种作用？'],
  ['bit_manipulation', 0, '在位运算技巧中，表达式 x & (x - 1) 的作用是什么？'],
  ['graph', 0, '存储边数远少于顶点数平方的稀疏图时，通常选择哪种结构？'],
  ['string_matching', 0, 'KMP 之所以能避免文本指针回溯，靠的核心部件是什么？'],
  ['link_layer', 0, '在链路层，ARP 协议负责完成下面哪一项转换？'],
  ['nosql', 1, '分布式系统的 CAP 定理里，P 指的是哪一个性质？'],
  ['distributed_transaction', 4, '在 TCC 分布式事务里，Try 与 Confirm 两个阶段各承担什么职责？'],
  ['olap_columnar', 4, '列式分析引擎采用「向量化执行」，主要想获得什么好处？'],
  ['os_synchronization', 0, '在自旋锁与互斥锁之间取舍时，自旋锁更适合哪种场景？'],
  ['observability', 3, '可观测性体系里，指标（metrics）与日志（logs）的分工是什么？'],
  ['ml_fundamentals', 0, '在机器学习实验中，测试集的正确使用方式是哪一种？'],
  ['distributed_fundamentals', 1, '主从复制配置里的「半同步复制」具体指什么行为？'],
  ['design_patterns', 2, '下列哪种做法属于设计上的反模式，而不是推荐的实践？'],
  ['testing_strategy', 4, '编写自动化测试时，用例所需的数据应当怎样构造和管理？'],
  ['math_vectors_matrices', 2, '数据分析里说一个矩阵「低秩」，通常意味着什么？'],
  ['math_eigen_svd', 2, '对特征做 PCA（主成分分析）之前，必须先完成哪一步预处理？'],
  ['cpp_memory', 0, 'C++ 资源管理中，RAII 的核心思想是什么？'],
  ['java_control_methods', 2, '判断两个方法是否构成重载时，依据的是哪一组信息？'],
  ['go_project_worker_pool', 3, '在服务里加一个限流器，主要想解决下面哪个问题？'],
  ['rust_ownership', 2, 'Rust 里做生命周期标注，是为了向编译器说明什么？'],
  ['ts_narrowing_generics', 2, 'TypeScript 条件类型中的 infer 关键字用来做什么？'],
  ['ts_testing', 1, '为前端组件写单元测试时，断言的对象应该落在哪里？'],
  ['shell_ops_scripts', 4, '运维脚本设计要求「幂等」，这个说法的含义是什么？'],
  ['shell_project_deploy', 1, '部署脚本里加一把互斥锁，主要是为了解决什么问题？'],
  ['digital_logic', 2, '在数字逻辑电路中，D 触发器的主要作用是什么？'],
  ['probability', 3, '描述一组数据的离散程度时，标准差与方差之间是什么关系？'],
  ['computation_theory', 2, '在计算复杂性理论里，「NP 完全问题」的准确含义是什么？'],
  ['discrete_math_set_theory', 4, '设 A 与 B 为两个集合，若 A⊆B 且 B⊆A 同时成立，能推出什么？'],
  ['discrete_math_logic', 2, '在命题逻辑中，下列哪一个公式是重言式（永真式）？'],
  ['sorting', 4, '与其他主流排序算法相比，归并排序的主要缺点是什么？'],
  ['prefix_sum', 4, '在区间操作技巧里，前缀和与差分之间是什么关系？'],
  ['binary_answer', 0, '想用二分答案把最优化问题转成判定问题，前提是什么？'],
  ['cache_eviction', 1, '大量缓存同时失效会引发缓存雪崩，常见的防护手段是什么？'],
  ['string_matching', 1, '设文本长 n、模式串长 m，KMP 算法的总时间复杂度是多少？'],
  ['network_flow', 0, '最大流最小割定理所说明的结论是哪一条？'],
  ['pentest_basics', 4, '漏洞情报里常见的 CVSS 评分，起的是下面哪个作用？'],
  ['cdn_proxy', 4, '在 CDN 架构中，「回源」描述的是下面哪一种行为？'],
  ['wireless_mobile', 1, '5G 网络里提到的「网络切片」，说的是什么能力？'],
  ['chain_wallet_keys', 1, '做离线签名时，必须保证的关键前提是什么？'],
  ['chain_token_standards', 1, '在代币授权场景里授予「无限额度」，最大的风险是什么？'],
  ['chain_audit_project', 1, '审查合约代码时，重入漏洞最典型的结构特征是什么？'],
  ['transaction', 0, '数据库事务的 ACID 四个字母里，A 代表的是哪一项性质？'],
  ['db_design', 3, '在数据模型设计阶段选择反范式化，主要动机是什么？'],
  ['de_flink_windowing', 1, 'Flink 窗口计算里的「允许迟到」参数，作用是下面哪一项？'],
  ['process_thread_intro', 2, '操作系统调度里说的「上下文切换」，具体指什么过程？'],
  ['os_project', 2, '生产者快于消费者的管道里，实现背压的正确方式是什么？'],
  ['debugging', 0, '调试器里的条件断点，最典型的用途是哪一种？'],
  ['linux_performance', 2, '开始一次性能优化工作前，应当遵守的基本原则是什么？'],
  ['cloud_k8s_operations', 1, '在 Kubernetes 里为容器声明资源请求（requests），主要作用是什么？'],
  ['multimodal_rag', 2, '把表格类文档送进 RAG 知识库时，推荐的入库做法是什么？'],
  ['ai_rag_agent_project', 2, '为问答系统建评测集时，题目应该覆盖下面哪些类型？'],
  ['ai_engineering', 2, '优化大模型应用的推理成本时，合理的下手顺序是什么？'],
  ['agent_cost_performance', 1, '在多智能体系统里做成本优化，正确的优先级顺序是？'],
  ['high_availability', 1, '当服务的错误预算已经用完时，团队接下来应当怎么做？'],
  ['design_patterns', 1, '在 SOLID 原则中，依赖倒置原则的含义是哪一条？'],
  ['requirements_modeling', 3, '需求文档里写用户故事时，推荐的标准格式是哪一种？'],
  ['se_quality_metrics', 2, '团队引入质量度量指标后，正确的用途应该是什么？'],
  ['sdl_security', 4, '关于应用密钥与凭据的生命周期管理，正确的做法是哪一种？'],
  ['math_eigen_svd', 4, '一个矩阵的条件数非常大，说明问题处于什么状态？'],
  ['visual_db_isolation', 2, '在数据库隔离实现中，MVCC 带来的核心好处是什么？'],
  ['project_testing_quality', 3, '为流水线设计质量门禁时，应当遵循的原则是哪一条？'],
  ['project_retro_improve', 1, '回顾改进时收集的度量指标，最不应该被用来做什么？'],
  ['frontend_vue_composition', 0, '阅读下面的 Vue 3 组合式 API 代码，它渲染出的内容是什么？'],
];

const flat = (s) => String(s).replace(/[`「」《》“”"'’（）()\s]/g, '');

const mPath = path.join(CONTENT, 'manifest.json');
const mRaw = fs.readFileSync(mPath, 'utf8');
const man = JSON.parse(mRaw);
const lessons = new Map();
for (const cat of man.categories || []) for (const l of cat.lessons || []) lessons.set(l.id, l);

const mdEdits = new Map(); // file -> [{from, to}]
let planned = 0;
const problems = [];

for (const [id, qi, stem] of STEMS) {
  const les = lessons.get(id);
  if (!les) {
    problems.push('找不到课时 ' + id);
    continue;
  }
  const q = (les.quiz || [])[qi];
  if (!q) {
    problems.push(id + ' 没有第 ' + qi + ' 题');
    continue;
  }
  const old = q.question;
  if (flat(stem).length < 12) problems.push(id + ' q' + qi + ' 新题干仍然过短：' + stem);
  if (old === stem) {
    problems.push(id + ' q' + qi + ' 题干已是目标文本');
    continue;
  }
  const clash = (les.quiz || []).some((o, i) => i !== qi && o.question === stem);
  if (clash) problems.push(id + ' q' + qi + ' 新题干与本课其他题重复');
  if (flat(old).length >= 12) problems.push(id + ' q' + qi + ' 旧题干本就不短（请核对）：' + old);
  q.question = stem;
  planned++;
  const file = (les.file || 'assets/content/' + id + '.md').replace(/^assets\/content\//, '');
  if (!mdEdits.has(file)) mdEdits.set(file, []);
  mdEdits.get(file).push({ from: old, to: stem, id, qi });
}

let mdFiles = 0;
let mdHits = 0;
for (const [file, edits] of mdEdits) {
  const p = path.join(CONTENT, file);
  if (!fs.existsSync(p)) {
    problems.push('课文缺失 ' + file);
    continue;
  }
  const raw = fs.readFileSync(p, 'utf8');
  const nl = raw.includes('\r\n') ? '\r\n' : '\n';
  const lines = raw.split(/\r?\n/);
  let touched = false;
  for (const e of edits) {
    let n = 0;
    for (let i = 0; i < lines.length; i++) {
      if (!lines[i].includes(e.from)) continue;
      lines[i] = lines[i].split(e.from).join(e.to);
      n++;
    }
    if (!n) {
      problems.push(file + ' 未找到题干「' + e.from + '」');
      continue;
    }
    mdHits += n;
    touched = true;
    if (SHOW) console.log(file + ' ×' + n + ' ' + e.from + ' → ' + e.to);
  }
  if (touched) {
    mdFiles++;
    if (APPLY) fs.writeFileSync(p, lines.join(nl), 'utf8');
  }
}

console.log(
  (APPLY ? '应用' : '干跑') +
    '：题干 计划 ' + STEMS.length + ' 条｜改写 ' + planned + ' 条｜课文 ' + mdHits + ' 处/' + mdFiles + ' 文件｜问题 ' + problems.length
);
problems.forEach((p) => console.log('  ! ' + p));
if (APPLY && planned) {
  const eol = mRaw.includes('\r\n') ? '\r\n' : '\n';
  fs.writeFileSync(mPath, JSON.stringify(man, null, 2).split('\n').join(eol), 'utf8');
}
