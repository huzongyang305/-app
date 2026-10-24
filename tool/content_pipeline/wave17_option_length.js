// 第 17 波：把「正确项明显最长」的单选题里过短的干扰项补成完整、可信的错误说法。
// rebalance_single_option_length.dart 只能自动处理有括号/子句可截的题目，剩下 16 题的
// 干扰项是十来个字的名词短语，一眼就能挑出最长项。这里按题干逐条补写：
// 只增加细节，不改变它「错误」的事实；正确项与解析一律不动，所以解析复述正确项的规则不受影响。
// 用法：node tool/content_pipeline/wave17_option_length.js [--apply]
import fs from 'node:fs';

const APPLY = process.argv.includes('--apply');
const P = 'assets/content/manifest.json';
const raw = fs.readFileSync(P, 'utf8');
const eol = raw.includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(raw);

// lessonId -> [题干关键词, 旧干扰项, 新干扰项]
const FIXES = [
  ['java_deployment', '直接运行应用程序的代码',
    '直接运行应用程序的业务代码，负责容器内进程的启动与重启，并按配置执行存活探针检查'],
  ['java_deployment', '管理 Docker 镜像的构建和推送',
    '承担镜像仓库的职责，把 Dockerfile 构建成镜像、按标签管理版本并推送到远端供节点拉取'],
  ['java_deployment', '存储应用的配置文件和环境变量',
    '集中保存应用的配置文件与环境变量，以键值对形式挂载给 Pod，改动后需重新挂载才生效'],
  ['java_project_ecommerce', '为了让订单号按顺序递增',
    '为了让订单号按顺序递增，方便客服凭编号回溯历史订单并打印当月对账单'],
  ['java_project_ecommerce', '为了加快数据库写入速度',
    '为了加快数据库写入速度，把库存校验和订单落库合并成一条语句一次提交'],
  ['java_project_ecommerce', '为了减少订单表的数据量',
    '为了减少订单表的数据量，让库存记录顺带承担订单明细的角色供直接查询'],
  ['java_servlet_jsp', '转发会改变浏览器地址栏中的 URL',
    '转发会把目标资源的地址回写到浏览器，地址栏中的 URL 随之改变'],
  ['java_servlet_jsp', '重定向是在服务器内部将请求传递给另一个资源',
    '重定向由服务器在内部把请求直接交给另一个资源处理，客户端并不感知这次跳转'],
  ['java_servlet_jsp', '重定向只能跳转到同一应用内的页面',
    '重定向只能跳转到同一应用内的页面，跨站点的 Location 会被容器直接拒绝'],
  ['java_restful_api', 'API 响应中应该包含大量详细的错误堆栈信息',
    'API 响应中应尽可能带上详细的错误堆栈信息，方便前端直接定位服务端出错位置'],
  ['java_restful_api', '所有 API 都必须使用 XML 格式返回数据',
    '所有 API 都必须统一使用 XML 格式返回数据，禁止返回 JSON 以免客户端解析出错'],
  ['java_restful_api', '客户端必须预先硬编码所有可用的 API 地址',
    '客户端必须预先硬编码所有可用的 API 地址，在本地维护一份接口清单再逐个调用'],
  ['devops_docker_registry', '无限制，但推送次数有限',
    '拉取完全无限制，只有推送次数受限，反复拉取镜像不会被限流'],
  ['devops_docker_registry', '只有中国地区的用户有限制',
    '限制只作用于中国地区的用户，其他地区用同一账号拉取不受任何影响'],
  ['devops_docker_registry', '每天只能拉取 10 次',
    '每天累计只能拉取 10 次，超出后要等到次日零点才恢复额度'],
  ['devops_terraform', '提供代码编辑器功能',
    '提供代码编辑器功能，内置 HCL 语法高亮与自动补全来编写配置文件'],
  ['devops_terraform', '提供 Web 界面管理基础设施',
    '提供 Web 界面来管理基础设施，日常操作可以完全脱离命令行执行计划'],
  ['devops_terraform', '自动测试应用程序代码',
    '自动测试应用程序的业务代码，在资源创建之前先跑一遍单元测试'],
  ['devops_terraform', '一个代码编辑器',
    '一个专门编辑 HCL 配置文件的代码编辑器，带语法高亮和片段模板'],
  ['devops_terraform', '一种代码格式化工具',
    '一种对配置做格式化的工具，用来统一字段顺序、缩进与注释风格'],
  ['devops_terraform', '一个团队协作工具',
    '一个团队协作工具，负责把多名工程师的改动合并后再统一提交评审'],
  ['devops_logging_tracing', '提供统一的日志存储方案',
    '提供统一的日志存储方案，把所有服务的日志都写进同一个数据库里查询'],
  ['devops_logging_tracing', '替代了所有现有的监控工具',
    '替代了所有现有监控工具，接入之后可以卸载 Prometheus 与 Grafana'],
  ['devops_logging_tracing', '只负责前端性能监控',
    '只负责前端页面的性能监控，采集首屏时间与接口耗时这类指标'],
  ['backend_nodejs_express', '忽略它们，让进程自然退出',
    '忽略它们，让进程按默认策略直接退出，善后交给容器编排平台的重启机制'],
  ['backend_nodejs_express', '使用try-catch包裹所有代码',
    '在每个控制器方法外层用 try-catch 包裹全部代码，把异常吞掉后返回错误码'],
  ['backend_nodejs_express', '只在开发环境中处理',
    '只在开发环境注册这两个监听器并打印日志，生产环境保持 Node 的默认行为'],
  // 第二轮：注解名/接口名本身的长短差无法抹平，这里只把明显过短的两题干扰项补到可读的长度。
  ['java_servlet_jsp', '重定向由服务器在内部把请求直接交给另一个资源处理，客户端并不感知这次跳转',
    '重定向是由服务器在内部把请求直接交给另一个资源处理，浏览器只看到一次请求与一次响应'],
  ['java_servlet_jsp', '转发会把目标资源的地址回写到浏览器，地址栏中的 URL 随之改变',
    '转发会在响应里回写一个新的 Location，浏览器地址栏随之换成目标资源的完整地址'],
  ['java_spring_mvc', '“@RestController” 只能返回 JSON 格式的数据',
    '“@RestController” 只能返回 JSON 格式的数据，无法为浏览器渲染 HTML 页面或输出表单视图'],
  ['java_spring_mvc', '“@Controller” 返回的字符串会被直接写入 HTTP 响应体',
    '“@Controller” 返回的字符串会被直接写入 HTTP 响应体，不再经过视图解析器去定位模板页面'],
];

const lessons = [];
for (const c of manifest.categories) for (const l of c.lessons || []) lessons.push(l);
const byId = new Map(lessons.map((l) => [l.id, l]));

let hit = 0;
const miss = [];
for (const [id, oldOpt, newOpt] of FIXES) {
  const lesson = byId.get(id);
  if (!lesson) { miss.push(`${id} 课程不存在`); continue; }
  let found = 0;
  for (const q of lesson.quiz || []) {
    for (let i = 0; i < (q.options || []).length; i++) {
      if (String(q.options[i]) === oldOpt) { q.options[i] = newOpt; found++; hit++; }
    }
  }
  if (!found) miss.push(`${id}｜${oldOpt}`);
}
console.log(`补写干扰项：${hit} 处；未命中 ${miss.length} 条`);
if (miss.length) console.log(miss.join('\n'));

// 报告这些课程里仍然「正确项显著最长」的单选题，供判断是否需要继续人工处理。
const visible = (s) => String(s).replace(/[\s`"“”『』「」']/g, '').length;
const still = [];
for (const c of manifest.categories) {
  for (const l of c.lessons || []) {
    for (const q of l.quiz || []) {
      if (q.type && q.type !== 'single') continue;
      if (typeof q.answer !== 'number' || !Array.isArray(q.options)) continue;
      const o = q.options.map(String);
      const cor = visible(o[q.answer]);
      const others = o.filter((_, i) => i !== q.answer).map(visible);
      const gap = cor - Math.max(...others);
      if (gap >= 12) still.push(`${l.id}｜${q.question.slice(0, 26)}｜差值=${gap}`);
    }
  }
}
console.log(`补写后仍差 12 字符以上：${still.length} 题`);
console.log(still.join('\n'));
if (APPLY) {
  fs.writeFileSync(P, JSON.stringify(manifest, null, 2).split('\n').join(eol));
  console.log('已写盘');
} else console.log('（dry-run，加 --apply 才写盘）');
