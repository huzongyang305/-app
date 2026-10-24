// 第 22 波：手工重写模板串位写坏的解析。
//
// ai_rag_agent_project 有 3 道题的解析里，模板把「本题取X这条，易错点」整段塞进了
// 术语「」槽位，读起来是一句没有主语的话，而且顺序题只复述了一个正确项。
// 这 3 条按题干与正确选项重写，其余解析保持原样。
// 用法：node tool/content_pipeline/wave22_fix_garbled_explanations.js [--apply]
import fs from 'node:fs';

const APPLY = process.argv.includes('--apply');
const P = 'assets/content/manifest.json';
const raw = fs.readFileSync(P, 'utf8');
const eol = raw.includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(raw);

// lessonId -> { 题号: 新解析 }
const MAP = {
  ai_rag_agent_project: {
    0:
      '按《实战：文档问答助手（RAG + Agent）》正文的先后，本题顺序是「先明确 实战 的输入、输出与约束」 → ' +
      '「写出最小示例并核对 RAG 的基线结果」 → 「只改一个变量，记录边界与失败路径的变化」 → ' +
      '「固定版本与证据，把“实战：文档问答助手（RAG + Agent）”的结论写成可复现记录」。' +
      '这四步就是正文里项目推进的主线：先定范围与约束，再跑通最小示例拿到基线，然后逐项改变量观察边界与失败路径，最后把结论固化成可复现记录。' +
      '常见错法是把固定版本与证据放在第一步，还没跑通示例就固化，记录下来的只是没验证过的假设；' +
      '也有人先只改一个变量再补最小示例，没有基线就没有可对比的变化，等于白跑一轮。',
    4:
      '让回答可溯源靠的不是把语气说得更肯定，而是给每个结论标出出处：检索片段携带文档 ID 与位置，' +
      '前端才能点开原文对应段落复核，这也是本课引用生成环节的核心做法。' +
      '易错点是把整篇文档塞进提示，模型给出的引用无法定位到具体片段，看着有来源其实不可核对；' +
      '让模型复述原文、只输出答案不带引用，同样拿不到可回溯的位置。' +
      '正确做法是在检索阶段就保留文档 ID 与片段偏移，生成时按片段编号回填引用。',
    5:
      '本课的主线是数据准备、混合检索、引用生成、工具调用与评测集，四段真正决定回答质量的是检索回来的片段能不能支撑结论；' +
      '一旦片段不支撑，模型缺少依据而编造答案就是最直接的表现，所以这一项与主线描述一致。' +
      '响应更快、引用更准、成本降低都是期望的收益，正文并没有把它们写成这条主线的必然结果，' +
      '脱离评测数据无法判断，因此不能作为与主线一致的说法。',
  },
};

let fixed = 0, missing = 0;
for (const c of manifest.categories) {
  for (const l of c.lessons || []) {
    const spec = MAP[l.id];
    if (!spec) continue;
    for (const key of Object.keys(spec)) {
      const q = (l.quiz || [])[Number(key)];
      if (!q) { missing++; continue; }
      q.explanation = spec[key];
      fixed++;
    }
  }
}
console.log(`重写串位解析 ${fixed} 条，未命中 ${missing} 条`);
if (APPLY) {
  fs.writeFileSync(P, JSON.stringify(manifest, null, 2).split('\n').join(eol));
  console.log('已写盘');
} else console.log('（dry-run，加 --apply 才写盘）');
