const fs = require('fs');
const path = require('path');
const dir = 'F:/app/assets/content';
const fence = String.fromCharCode(96, 96, 96);

const list = ['devops_cicd_pipeline.md','devops_deployment_strategies.md','discrete_math_logic.md','frontend_framework_comparison.md','frontend_state_management.md','frontend_svelte_reactive.md','ml_computer_vision.md','ml_data_preprocessing_feature_engineering.md','ml_model_deployment_mlops.md','ml_model_evaluation_hyperparameter_tuning.md','ml_natural_language_processing.md','ml_recommendation_systems.md','ml_tensorflow_pytorch_intro.md','ml_time_series_prediction.md','mobile_flutter_advanced.md','mobile_offline_first_architecture.md','mobile_performance_optimization.md','mobile_react_native_deep.md','mobile_security_best_practices.md'];

let fixed = 0;
for (const f of list) {
  const p = path.join(dir, f);
  let t = fs.readFileSync(p, 'utf8');
  const crlf = t.includes('\r\n');
  if (crlf) t = t.replace(/\r\n/g, '\n');

  // 1. rebuild the retrofitted 代码/协议/SQL 示例 section when it contains a truncated snippet
  const lines = t.split('\n');
  const secIdx = lines.findIndex(x => /^##\s*代码\/协议\/SQL 示例\s*$/.test(x));
  if (secIdx >= 0) {
    let end = secIdx + 1;
    while (end < lines.length && !/^##\s/.test(lines[end])) end++;
    const body = lines.slice(secIdx + 1, end);
    // count fences inside the section
    const fc = body.filter(x => x.trimLeft().startsWith(fence)).length;
    if (fc % 2 === 1) {
      // find complete first fence block in whole doc (before this section)
      const pre = lines.slice(0, secIdx);
      let openAt = -1, closeAt = -1;
      for (let i = 0; i < pre.length; i++) {
        if (!pre[i].trimLeft().startsWith(fence)) continue;
        if (openAt === -1) openAt = i; else { closeAt = i; break; }
      }
      const replacement = [];
      if (openAt !== -1 && closeAt !== -1) {
        replacement.push(
          '',
          '正文首个完整示例如下，先运行确认环境，再按正文步骤改一个输入观察输出变化。',
          '',
          ...pre.slice(openAt, closeAt + 1),
          '',
        );
      } else {
        replacement.push('', '本课示例集中在上文各章节，按章节顺序逐个运行即可。', '');
      }
      lines.splice(secIdx + 1, end - secIdx - 1, ...replacement);
      fixed++;
    }
  }

  let out = lines.join('\n');
  // 2. drop a trailing EOF closing fence if fences are now balanced without it
  {
    const ls = out.split('\n');
    const cnt = ls.filter(x => x.trimLeft().startsWith(fence)).length;
    let last = ls.length - 1;
    while (last >= 0 && ls[last].trim() === '') last--;
    if (cnt % 2 === 0 && ls[last]?.trim() === fence) {
      // verify remaining balance stays ok only if this fence closed the last opener; if total even it's a stray closer
      ls.splice(last, 1);
      out = ls.join('\n');
    }
  }
  // 3. final parity: if odd, close before next heading after stray opener
  {
    let ls = out.split('\n');
    const cnt = ls.filter(x => x.trimLeft().startsWith(fence)).length;
    if (cnt % 2 === 1) {
      let depth = 0, stray = -1;
      for (let i = 0; i < ls.length; i++) {
        if (!ls[i].trimLeft().startsWith(fence)) continue;
        if (depth === 0) { depth = 1; stray = i; } else { depth = 0; stray = -1; }
      }
      if (stray >= 0) {
        let ins = ls.length;
        for (let i = stray + 1; i < ls.length; i++) {
          if (ls[i].trimLeft().startsWith(fence)) break;
          if (/^##\s/.test(ls[i])) { ins = i; break; }
        }
        ls.splice(ins, 0, fence, '');
        out = ls.join('\n');
      }
    }
  }
  out = out.replace(/\n{3,}/g, '\n\n');
  if (crlf) out = out.replace(/\n/g, '\r\n');
  fs.writeFileSync(p, out);
}
console.log('rebuilt sections in', fixed, 'of', list.length, 'files');
for (const f of list) {
  const t = fs.readFileSync(path.join(dir, f), 'utf8');
  const c = t.split(/\r?\n/).filter(x => x.trimLeft().startsWith(fence)).length;
  if (c % 2 !== 0) console.log('STILL ODD:', f, c);
}
