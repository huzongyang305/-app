// wave30：修 code/debug 题的「选项断言与展示代码不一致」。
//
// 三种断言模板的判定口径：
//   出现字面量 `X` → 代码文本里包含 X（子串）；干扰项要求完全不含 X
//   调用了 `X()`   → 代码里有 X( 形式；干扰项要求没有 X(
//   代码里出现了 `X` 这个名字 → 代码里有独立词 X；干扰项要求没有独立词 X
// 修复路线：优先把 code 重指到课文里同语言、全部正确项成立且干扰项不泄露的代码块；
// 找不到就把正确项改写为当前展示代码里真实成立的断言；泄露的干扰项换成同语言同形态且不泄露的 token。
// 解析与课文 考点精讲 同步改写。
//
// 用法：node tool/content_pipeline/wave30_assertion_truth.js [--apply]
import fs from 'node:fs';
import path from 'node:path';

const ROOT = 'F:/app';
const MANIFEST = path.join(ROOT, 'assets/content/manifest.json');
const APPLY = process.argv.includes('--apply');

const norm = (s) => String(s || '').replace(/\s+/g, '');
const ASSERT = /^(?:调用了|出现字面量|代码里出现了)\s*`([^`]+)`/;
const KIND = (text) => (/^调用了/.test(text) ? 'call' : /^出现字面量/.test(text) ? 'literal' : 'name');
const MIN_BLOCK = 40;
const MAX_BLOCK = 1600;

const KEYWORDS = new Set(['public', 'private', 'protected', 'class', 'static', 'void', 'return', 'const', 'let', 'var', 'true', 'false', 'null', 'none', 'int', 'long', 'double', 'float', 'bool', 'char', 'string', 'import', 'from', 'def', 'if', 'else', 'elif', 'for', 'while', 'func', 'fn', 'pub', 'use', 'new', 'this', 'self', 'main', 'include', 'std', 'async', 'await', 'package', 'struct', 'enum', 'try', 'catch', 'throw', 'print', 'println', 'printf', 'system', 'console', 'end', 'then', 'do', 'in', 'is', 'as', 'not', 'and', 'or', 'select', 'case', 'switch', 'defer', 'range', 'type', 'interface', 'default', 'extends', 'implements', 'namespace', 'template', 'sizeof', 'mut', 'val', 'len', 'insert', 'update', 'delete', 'where', 'values', 'into', 'table', 'show', 'begin', 'set', 'commit', 'rollback', 'session', 'transaction', 'isolation', 'level', 'read', 'write', 'grant', 'explain', 'with', 'group', 'order', 'count', 'create', 'drop', 'alter', 'index', 'join', 'left', 'inner', 'null!']);

const escape = (ch) => ch.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const boundaryRe = (token) => new RegExp(`(?<![A-Za-z0-9_])${Array.from(String(token)).map(escape).join('\\s*')}(?![A-Za-z0-9_])`);
const callRe = (token) => new RegExp(`(?<![A-Za-z0-9_])${Array.from(String(token)).map(escape).join('\\s*')}\\s*\\(`);
// 字面量允许原文里的空白；token 两端若是 ASCII 单词字符才要求词边界，标点端不参与判定
const isWordChar = (ch) => /[A-Za-z0-9_]/.test(String(ch || ''));
function literalRe(token) {
  const s = String(token);
  const body = Array.from(s).map(escape).join('\\s*');
  const head = isWordChar(s[0]) ? '(?<![A-Za-z0-9_])' : '';
  const tail = isWordChar(s[s.length - 1]) ? '(?![A-Za-z0-9_])' : '';
  return new RegExp(`${head}${body}${tail}`);
}

/** 断言在代码里是否成立 */
function present(body, kind, token) {
  const text = String(body || '');
  if (!token) return false;
  if (kind === 'literal') return literalRe(token).test(text);
  if (kind === 'call') return callRe(token).test(text);
  return boundaryRe(token).test(text);
}

/** 干扰项是否仍可保留（不泄露） */
function absent(body, kind, token) {
  return !present(body, kind, token);
}

function assertions(options) {
  const out = [];
  (options || []).forEach((raw, index) => {
    const text = String(raw || '');
    const hit = ASSERT.exec(text.replace(/^\s*\*\*/, ''));
    if (!hit) return;
    const token = norm(hit[1]).replace(/\(\)$/, '');
    if (token.length >= 2) out.push({ index, token, raw: text, kind: KIND(text) });
  });
  return out;
}

function codeBlocks(markdown) {
  const list = [];
  const re = /^([ \t]*)(```|~~~)([a-zA-Z0-9+#]*)[^\n]*\n([\s\S]*?)^[ \t]*\2[ \t]*$/gm;
  let mm;
  while ((mm = re.exec(markdown))) {
    const body = mm[4].replace(/\s+$/, '');
    if (body.length < MIN_BLOCK || body.length > MAX_BLOCK) continue;
    list.push({ lang: mm[3].toLowerCase(), body });
  }
  return list;
}

const DECL = /(?:^|[\s;}、])(?:def|fun|func|fn|declare|public|private|protected|internal|static|void|inline|template|virtual|override|sub|function|proc)\b[^(){};]*$/;
// 脚本与配置类代码里「名字 + 左括号」多半不是函数调用，不生成「调用了」候选
const NO_CALL_LANGS = new Set(['sql', 'bash', 'sh', 'shell', 'zsh', 'json', 'yaml', 'yml', 'toml', 'ini', 'conf', 'text', 'txt', 'dockerfile', 'makefile', 'csv', 'markdown', 'md', 'xml', 'html']);

/** 代码里能站住的断言候选（调用了 只认真实调用，不认声明行） */
function candidates(code, lang) {
  const out = [];
  const push = (kind, token) => {
    const t = String(token || '').trim();
    if (!t || t.length < 3 || KEYWORDS.has(t.toLowerCase())) return;
    if ((t.match(/[\p{L}\p{N}]/gu) || []).length < 3) return;
    if (kind !== 'literal' && /[<>{}[\]()=,;:!?|&%$^*+\-/\\'"“”、，。：；]/.test(t)) return;
    if (!present(code, kind, t)) return;
    out.push({ kind, token: t, text: kind === 'call' ? `调用了 \`${t}()\`` : kind === 'literal' ? `出现字面量 \`${t}\`` : `代码里出现了 \`${t}\` 这个名字` });
  };
  if (!NO_CALL_LANGS.has(String(lang || '').toLowerCase())) {
    for (const m of code.matchAll(/([A-Za-z_][A-Za-z0-9_$.]{2,})\s*\(/g)) {
      if (DECL.test(code.slice(Math.max(0, m.index - 60), m.index))) continue;
      push('call', m[1]);
    }
  }
  for (const m of code.matchAll(/(["'`])((?:(?!\1)[^\n]){3,40})\1/g)) push('literal', m[2]);
  for (const m of code.matchAll(/\b([A-Za-z_][A-Za-z0-9_$.]{3,})\b/g)) push('name', m[1]);
  const seen = new Set();
  return out.filter((c) => {
    const key = `${c.kind}|${norm(c.token)}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

const rawToken = (text) => String(text).replace(/^[^`]*`([^`]+)`.*/, '$1');

/** 解析里的写法变体：原样、空白折叠、干扰项尾部的「X，」形式 */
function explanationForms(oldText) {
  const out = [String(oldText), String(oldText).replace(/\s+/g, ' ').trim()];
  const inner = String(oldText).match(/`([^`]+)`/);
  if (inner) {
    const prefix = String(oldText).slice(0, String(oldText).indexOf('`') + 1);
    out.push(`${prefix}${inner[1]}，\``);
    out.push(norm(`${prefix}${inner[1]}，\``));
  }
  return [...new Set(out.filter(Boolean))];
}

const manifestRaw = fs.readFileSync(MANIFEST, 'utf8');
const eol = manifestRaw.includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(manifestRaw);

// 全库断言 token 池：替换泄露干扰项时挑同语言同形态、代码里确实没有的 token
const pool = new Map();
for (const cat of manifest.categories) {
  for (const les of cat.lessons) {
    (les.quiz || []).forEach((item) => {
      if (item.type !== 'code' && item.type !== 'debug') return;
      const lang = String(item.language || '').toLowerCase();
      assertions(item.options).forEach((m) => {
        const key = `${lang}|${m.kind}`;
        if (!pool.has(key)) pool.set(key, new Set());
        pool.get(key).add(m.token);
      });
    });
  }
}

function pickAbsentToken(lang, kind, body, used, nearLength) {
  const flat = [...(pool.get(`${lang}|${kind}`) || new Set())].filter((token) => (
    token && norm(token).length >= 3 && (String(token).match(/[\p{L}\p{N}]/gu) || []).length >= 3
    && !used.has(norm(token)) && !KEYWORDS.has(String(token).toLowerCase()) && absent(body, kind, token)
  ));
  if (!flat.length) return null;
  flat.sort((a, b) => Math.abs(a.length - nearLength) - Math.abs(b.length - nearLength) || a.length - b.length);
  return { kind, token: flat[0], text: kind === 'call' ? `调用了 \`${flat[0]}()\`` : kind === 'literal' ? `出现字面量 \`${flat[0]}\`` : `代码里出现了 \`${flat[0]}\` 这个名字` };
}

const stats = { items: 0, badCorrect: 0, badDistractor: 0 };
const residual = [];
for (const category of manifest.categories) {
  for (const lesson of category.lessons) {
    const file = path.join(ROOT, lesson.file);
    if (!fs.existsSync(file)) continue;
    const blocks = codeBlocks(fs.readFileSync(file, 'utf8').replace(/\r\n/g, '\n'));
    (lesson.quiz || []).forEach((q, qi) => {
      if (q.type !== 'code' && q.type !== 'debug') return;
      const marks = assertions(q.options);
      if (!marks.length) return;
      const truth = Array.isArray(q.answers) && q.answers.length ? q.answers : [q.answer];
      const correct = marks.filter((m) => truth.includes(m.index));
      if (!correct.length) return;
      const distractors = marks.filter((m) => !truth.includes(m.index));
      stats.items++;
      const code = String(q.code || '');
      const missing = correct.filter((m) => !present(code, m.kind, m.token));
      const leaked = distractors.filter((m) => !absent(code, m.kind, m.token));
      if (!missing.length && !leaked.length) return;
      stats.badCorrect += missing.length ? 1 : 0;
      stats.badDistractor += leaked.length ? 1 : 0;
      residual.push({ lesson, q, qi, correct, distractors, missing, leaked, blocks, code });
    });
  }
}

const plans = [];
const skipped = [];
for (const row of residual) {
  const { lesson, q, qi, correct, distractors, missing, blocks, code } = row;
  const want = String(q.language || '').toLowerCase();
  const term = (String(q.explanation || '').match(/术语\s*([^（(]+)[（(]/) || [])[1] || '';
  const otherTokens = (except) => new Set((q.options || [])
    .map((o, j) => (j === except ? '' : norm(rawToken(String(o)))))
    .filter(Boolean));

  // 路线一：code 重指到同语言、正确项全部成立且干扰项不泄露的块
  const usable = blocks
    .filter((b) => b.lang === want
      && correct.every((m) => present(b.body, m.kind, m.token))
      && distractors.every((m) => absent(b.body, m.kind, m.token)));
  const plan = { lesson, q, qi, code: null, pairs: [], notes: [] };

  if (missing.length && usable.length) {
    plan.code = usable.sort((a, b) => a.body.length - b.body.length)[0].body;
    plan.notes.push('code 重指满足块');
  } else if (missing.length) {
    // 路线二：正确项改写为当前展示代码里真实成立的断言
    if (correct.length !== 1) { skipped.push(`${lesson.id}#${qi}｜多个正确断言且无满足块`); continue; }
    const mark = correct[0];
    const used = new Set(distractors.map((m) => norm(m.token)));
    const scored = candidates(plan.code || code, want)
      .filter((c) => !used.has(norm(c.token)) && norm(c.token) !== norm(mark.token))
      .filter((c) => (q.options || []).every((o, j) => j === mark.index || norm(o) !== norm(c.text)))
      .map((c) => ({
        c,
        score: (term && (norm(term).includes(norm(c.token)) || norm(c.token).includes(norm(term))) ? 3 : 0)
          + (c.kind === 'call' ? 2 : c.kind === 'literal' ? 1 : 0)
          - Math.abs(c.token.length - mark.token.length) / 8,
      }))
      .sort((a, b) => b.score - a.score);
    if (!scored.length) { skipped.push(`${lesson.id}#${qi}｜展示代码里没有可用断言候选`); continue; }
    const pick = scored[0].c;
    plan.pairs.push({ index: mark.index, oldText: mark.raw, newText: pick.text });
    plan.notes.push(`正确项 ${mark.token}→${pick.token}`);
  }

  // 展示代码里泄露的干扰项一律替换
  const shown = plan.code || code;
  let broken = false;
  for (const m of distractors) {
    if (plan.pairs.some((p) => p.index === m.index) || absent(shown, m.kind, m.token)) continue;
    const rep = pickAbsentToken(want, m.kind, shown, otherTokens(m.index), m.token.length);
    if (!rep) { skipped.push(`${lesson.id}#${qi}｜干扰项 ${m.token} 泄露且池中无替代`); broken = true; break; }
    plan.pairs.push({ index: m.index, oldText: m.raw, newText: rep.text });
    plan.notes.push(`干扰项 ${m.token}→${rep.token}`);
  }
  if (broken) continue;
  if (plan.code && plan.code === code) plan.code = null;
  if (!plan.pairs.length && !plan.code) continue;
  plans.push(plan);
}

const mdEdits = new Map();
for (const plan of plans) {
  const { lesson, q, qi } = plan;
  console.log(`${lesson.id}#${qi}｜${plan.notes.join('；') || 'code 重指'}`);
  if (plan.code) console.log(`   code → ${plan.code.replace(/\r?\n/g, ' ⏎ ').slice(0, 90)}…`);
  for (const p of plan.pairs) {
    console.log(`   ${String(p.index)}「${p.oldText}」→「${p.newText}」`);
    if (!APPLY) continue;
    q.options[p.index] = p.newText;
    const explanation = String(q.explanation || '');
    const hit = explanationForms(p.oldText).find((form) => form && explanation.includes(form));
    if (hit) q.explanation = explanation.split(hit).join(p.newText);
    const list = mdEdits.get(lesson.file) || [];
    list.push({ oldText: p.oldText, newText: p.newText, hit: hit || '' });
    mdEdits.set(lesson.file, list);
  }
  if (APPLY && plan.code) q.code = plan.code;
}

if (APPLY) {
  for (const [file, list] of mdEdits) {
    const mdPath = path.join(ROOT, file);
    if (!fs.existsSync(mdPath)) continue;
    const srcRaw = fs.readFileSync(mdPath, 'utf8');
    const mdEol = srcRaw.includes('\r\n') ? '\r\n' : '\n';
    const md0 = srcRaw.replace(/\r\n/g, '\n');
    let md = md0;
    let done = 0;
    for (const edit of list) {
      for (const target of [edit.oldText, edit.hit].filter(Boolean)) {
        if (!md.includes(target)) continue;
        md = md.split(target).join(edit.newText);
        done++;
      }
    }
    if (!done) continue;
    if (md.replace(/\s/g, '').length >= md0.replace(/\s/g, '').length - 60) {
      fs.writeFileSync(mdPath, md.split('\n').join(mdEol));
      console.log(`课文 ${file}：同步 ${done} 处`);
    } else {
      console.log(`课文 ${file}：改写使正文变短，跳过（交给 wave28）`);
    }
  }
  fs.writeFileSync(MANIFEST, JSON.stringify(manifest, null, 2).split('\n').join(eol));
}

if (skipped.length) console.log('跳过：\n' + skipped.join('\n'));
console.log(`断言型 code 题 ${stats.items}｜正确项不成立 ${stats.badCorrect}｜干扰项泄露 ${stats.badDistractor}｜修复计划 ${plans.length}｜跳过 ${skipped.length}`);
if (!APPLY) console.log('（dry-run，加 --apply 才写盘）');
