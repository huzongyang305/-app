# DOM 与事件

![DOM 选择、事件监听与委托](images/diagram_js_dom.webp)

![DOM 与事件](images/remaining_js_dom_events.webp)

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：55 分钟

## 本节知识框架

**课程定位**：所属分类为「JavaScript」，课程主题为「DOM 与事件」，学习阶段为「进阶」，建议用时 55 分钟。

**本课要解决的主问题**：元素选择与修改、事件监听、冒泡与事件委托、表单与本地存储。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「DOM 与事件」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「DOM 与事件」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「DOM」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《异步编程》

**学习位置**：本课位于《异步编程》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《错误处理与调试》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释DOM 与事件解决了什么问题，而不是只背术语。
- 能说清 「DOM」、「事件」、「冒泡」、「事件委托」 之间的关系，并分别举出一个例子。
- 能把 DOM 放回「DOM 与事件」的知识体系，说明它和 事件 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：元素选择与修改、事件监听、冒泡与事件委托、表单与本地存储。

**教材衔接：前置知识**

- 先完成上一课《异步编程》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先完成「异步编程」，或确认自己能独立跑通正文里的 querySelectorAll 示例。
- 开始前先复习：DOM、事件、冒泡。
- 如果 选择与修改元素 这一步看不懂，先记录具体卡点，再用 querySelectorAll 复现一遍。

**教材衔接：本课小结**

DOM 操作记住三件事：**用 querySelector 选择、用 addEventListener 绑定、用事件委托处理动态列表**，并把用户内容当作不可信数据。

## 核心概念定义

> 阅读约定：本课先给「DOM 与事件」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| DOM | DOM 操作记住三件事：用 querySelector 选择、用 addEventListener 绑定、用事件委托处理动态列表，并把用户内容当作不可信数据。 | 仅在「DOM 与事件」明确给出的输入、版本与资源条件下成立。 |
| 事件 | 事件是「用户做了什么」的通知，你注册回调函数来决定怎么响应。 | 仅在「DOM 与事件」明确给出的输入、版本与资源条件下成立。 |
| 冒泡 | 事件从触发元素向上传播到祖先节点的过程。 | 仅在「DOM 与事件」明确给出的输入、版本与资源条件下成立。 |
| 事件委托 | 把监听器挂在父元素上，靠事件冒泡统一处理子元素事件，避免为每个子节点绑定监听。 | 仅在「DOM 与事件」明确给出的输入、版本与资源条件下成立。 |
| localStorage | 浏览器提供的同源持久化键值存储，容量有限且只能存字符串。 | 仅在「DOM 与事件」明确给出的输入、版本与资源条件下成立。 |
| XSS | 插入用户输入时优先 textContent，使用 innerHTML 前必须转义，否则存在 XSS 风险。 | 仅在「DOM 与事件」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「DOM 与事件」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「DOM」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「事件」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「冒泡」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「DOM 与事件」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | DOM | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | 事件 | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | 冒泡 | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「DOM 与事件」自己的示例验证。「DOM 与事件」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：开发者工具**

Elements 看结构、Console 试代码、Network 看请求、Sources 打断点、Application 看存储与缓存。

**教材衔接：表单速查**

| 目的 | 写法 |
| --- | --- |
| 阻止提交刷新页面 | `form.addEventListener("submit", (e) => { e.preventDefault(); ... })` |
| 读取输入 | `input.value.trim()` |
| 复选框状态 | `checkbox.checked` |
| 单选组取值 | `form.elements["gender"].value` |
| 表单整体取值 | `new FormData(form)` 或 `Object.fromEntries(new FormData(form))` |
| 自定义校验 | `input.setCustomValidity("提示")` |
| 触发原生校验 | `form.reportValidity()` |

**教材衔接：版本与时效**

- querySelectorAll 依赖的新 API 必须有降级路径，否则老环境直接报错。
- 升级前确认 DOM 的兼容范围，把不可回退的改动单独拆成一次提交。

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 一次只改一个版本条件，把 DOM 相关的差异单独记成一条结论。
- 回归范围锁定 querySelectorAll 的默认行为，并确认弃用警告是否出现在构建输出里。
- 升级完成后记录 DOM 的新旧版本差异，并据此调整下次复核时间。

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 DOM、事件 | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「DOM 与事件」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「DOM 与事件」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**课程内置实验入口**：`sandbox:javascript`，用于动手验证《DOM 与事件》的机制；实验结论不替代概念定义与复杂度分析。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《DOM 与事件》原文中的最小示例。先预测《DOM 与事件》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```javascript
const title = document.querySelector('#title');        // 第一个匹配
const items = document.querySelectorAll('.item');      // NodeList

title.textContent = '新标题';                          // 纯文本，安全
title.innerHTML = '<b>加粗</b>';                       // 解析 HTML，注意 XSS
title.classList.add('active');
title.classList.toggle('hidden');
title.style.color = 'red';

const div = document.createElement('div');
div.textContent = '动态创建';
document.body.append(div);
items.forEach(item => item.remove());                  // NodeList 支持 forEach
```

**教材衔接：选择与修改元素**

```javascript
const title = document.querySelector('#title');        // 第一个匹配
const items = document.querySelectorAll('.item');      // NodeList

title.textContent = '新标题';                          // 纯文本，安全
title.innerHTML = '<b>加粗</b>';                       // 解析 HTML，注意 XSS
title.classList.add('active');
title.classList.toggle('hidden');
title.style.color = 'red';

const div = document.createElement('div');
div.textContent = '动态创建';
document.body.append(div);
items.forEach(item => item.remove());                  // NodeList 支持 forEach
```

插入用户输入时优先 `textContent`，使用 `innerHTML` 前必须转义，否则存在 XSS 风险。

**教材衔接：事件监听**

```javascript
const button = document.querySelector('#save');

function handleClick(event) {
  console.log('点击了', event.target);
}
button.addEventListener('click', handleClick);
button.removeEventListener('click', handleClick);   // 移除需传同一函数引用
```

**教材衔接：冒泡与事件委托**

事件默认从目标向外冒泡（target → 祖先），因此可以在父元素上统一处理子元素事件：

```javascript
document.querySelector('#list').addEventListener('click', event => {
  const item = event.target.closest('li[data-id]');
  if (!item) return;
  console.log('点击了', item.dataset.id);   // data-id → dataset.id
});

event.stopPropagation();   // 阻止继续冒泡（慎用）
event.preventDefault();    // 阻止默认行为，如提交表单
```

委托的好处：动态新增的元素无需重新绑定监听器。

**教材衔接：表单与本地存储**

```javascript
form.addEventListener('submit', event => {
  event.preventDefault();                  // 阻止页面刷新
  const data = new FormData(form);
  console.log(Object.fromEntries(data));
});

localStorage.setItem('token', 'abc');      // 持久保存（同源、仅字符串）
sessionStorage.setItem('step', '1');       // 关闭标签页即清除
const token = localStorage.getItem('token');
```

**教材衔接：DOM 查询与修改速查**

| 目的 | 写法 | 说明 |
| --- | --- | --- |
| 查单个元素 | `document.querySelector(".card")` | 返回第一个匹配或 `null` |
| 查全部元素 | `document.querySelectorAll(".card")` | 返回静态 NodeList，可 `forEach` |
| 按 id 查 | `document.getElementById("app")` | 最快，但只按 id |
| 改文本 | `el.textContent = "内容"` | 安全，不解析 HTML |
| 改 HTML | `el.innerHTML = html` | 有 XSS 风险，只用可信内容 |
| 改样式 | `el.classList.add("active")` | 优于直接拼 `style` |
| 改属性 | `el.setAttribute("aria-label", "关闭")` | 表单值优先用 `el.value` |
| 创建节点 | `document.createElement("li")` | 配合 `append` 插入 |
| 插入节点 | `parent.append(child)` | `prepend` / `before` / `after` 同理 |
| 删除节点 | `el.remove()` | 直接把自己从文档中移除 |
| 事件委托 | `list.addEventListener("click", fn)` | 在父元素上监听，减少监听器数量 |
| 阻止默认行为 | `event.preventDefault()` | 如阻止表单提交跳转 |
| 阻止冒泡 | `event.stopPropagation()` | 慎用，会破坏事件委托 |
| 一次性监听 | `addEventListener("click", fn, { once: true })` | 自动移除，避免泄漏 |

```js
// 事件委托：动态新增的条目也能响应
const list = document.querySelector("#todo-list");
list.addEventListener("click", (event) => {
  const target = event.target.closest("li[data-id]");
  if (!target) return;
  target.classList.toggle("done");
});
```

**教材衔接：零基础详解：DOM 操作与事件处理**

### 一句话说清它是什么

DOM 是浏览器把 HTML 变成的一棵「节点树」，JS 通过它读写页面；
事件是「用户做了什么」的通知，你注册回调函数来决定怎么响应。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| DOM 树 | 家谱 | 每个标签是一个节点，有父子兄弟关系 |
| 选择器 | 点名 | 按 id、class、标签找到元素 |
| 事件监听 | 装门铃 | 有人按铃就执行你的回调 |
| 事件冒泡 | 水泡上浮 | 子元素的事件会往父元素传 |
| 事件委托 | 前台统一收件 | 只在一个父节点上监听所有子节点 |

### 选取元素的四种方式

```javascript
const one = document.querySelector("#app");          // 第一个匹配
const all = document.querySelectorAll(".item");       // 全部匹配，返回 NodeList
const byId = document.getElementById("app");          // 最快
const byClass = document.getElementsByClassName("item");   // 实时集合

for (const el of all) {                               // NodeList 可迭代
  el.classList.add("active");
}
```

### 读写内容与属性

```javascript
const box = document.querySelector("#box");

box.textContent = "纯文本";                  // 安全，不会解析标签
box.innerHTML = "<b>富文本</b>";             // 会解析 HTML，注意 XSS

box.classList.add("active");
box.classList.toggle("dark");
box.classList.remove("active");

box.setAttribute("data-id", "7");
box.dataset.userId;                          // 读取 data-user-id

box.style.color = "red";                     // 行内样式，少量使用
box.hidden = true;                           // 推荐：用类或 hidden 控制显隐
```

**安全提醒**：只有内容可信时才用 `innerHTML`；用户输入一律用 `textContent`。

### 创建、插入与移除

```javascript
const list = document.querySelector("#list");

const li = document.createElement("li");
li.textContent = "新条目";
list.append(li);                 // 追加到末尾

li.remove();                     // 删除自己
list.replaceChildren();          // 一次清空（比循环删更快）
```

### 事件处理与冒泡控制

```javascript
const button = document.querySelector("#save");

function onSave(event) {
  event.preventDefault();        // 阻止默认行为（表单提交、链接跳转）
  console.log("点击了", event.target);
}

button.addEventListener("click", onSave);
// 需要移除时必须传同一个函数引用
// button.removeEventListener("click", onSave);
```

| 方法 | 作用 |
| --- | --- |
| `preventDefault()` | 阻止默认行为 |
| `stopPropagation()` | 阻止继续冒泡（谨慎使用） |
| `event.target` | 实际触发事件的元素 |
| `event.currentTarget` | 绑定监听的那个元素 |
| `{ once: true }` | 只触发一次后自动移除 |

### 事件委托：列表点击的标准写法

```javascript
const list = document.querySelector("#list");

list.addEventListener("click", (event) => {
  const item = event.target.closest("li[data-id]");
  if (!item) return;                       // 点在空白处，忽略
  console.log("选中", item.dataset.id);
});
```

好处：**新加的子元素自动生效，不用重复绑定**。

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 脚本在元素之前执行 | `Cannot read properties of null` | 用 `defer` 或放到 `</body>` 前 |
| 用 `innerHTML` 拼接用户输入 | XSS 漏洞 | 用 `textContent` |
| 循环里绑定监听 | 元素多时性能差 | 用事件委托 |
| `removeEventListener` 无效 | 回调传的是新函数 | 保存同一个函数引用 |
| 忘记 `preventDefault` | 表单刷新页面 | 在提交处理里加上 |
| 用 `style` 到处改样式 | 难以维护 | 用 class 切换 |
| 频繁读写 `offsetHeight` | 强制同步布局，卡顿 | 批量读取后统一写 |
| 以为 NodeList 是数组 | `map` 报错 | 用 `Array.from` 或 `[...]` |

### 手把手练习：可增删的待办列表

```javascript
const form = document.querySelector("#todo-form");
const input = document.querySelector("#todo-input");
const list = document.querySelector("#todo-list");

form.addEventListener("submit", (event) => {
  event.preventDefault();
  const text = input.value.trim();
  if (!text) return;

  const li = document.createElement("li");
  li.textContent = text;
  li.dataset.id = String(Date.now());
  list.append(li);
  input.value = "";
  input.focus();
});

// 事件委托：删除按钮未来新增的也能生效
list.addEventListener("click", (event) => {
  const li = event.target.closest("li");
  if (li) li.remove();
});
```

### 学完自测

- [ ] 能说出 `querySelector` 与 `querySelectorAll` 的区别。
- [ ] 知道为什么不能直接用 `innerHTML` 渲染用户输入。
- [ ] 能解释事件冒泡与事件委托。
- [ ] 知道 `event.target` 与 `currentTarget` 的差别。
- [ ] 能说出脚本放在 `<head>` 里要注意什么。

## 时间/空间复杂度或性能分析

**复杂度证据**：「DOM 与事件」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「DOM 与事件」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「DOM 与事件」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

**教材衔接：事件与 DOM 的性能注意点**

| 场景 | 问题 | 做法 |
| --- | --- | --- |
| 列表渲染上千项 | 逐个 append 触发多次重排 | 用 DocumentFragment 批量插入，或虚拟滚动 |
| 高频事件（scroll/resize/input） | 每秒触发几十次 | 用防抖（debounce）或节流（throttle） |
| 大量子元素事件 | 绑定上千个监听器 | 事件委托到父容器 |
| 读写布局属性交替 | 强制同步布局（layout thrashing） | 先批量读，再批量写 |
| 频繁改样式 | 逐条改 style 触发多次重绘 | 改 class 或使用 CSS 变量 |

清理与正确性：组件卸载时移除监听器（`removeEventListener` 需同一函数引用）与取消定时器；`requestAnimationFrame` 适合逐帧更新；表单提交用 `preventDefault` 后自行校验，避免页面刷新丢失状态。

## 常见误区与易错点

> 复核《DOM 与事件》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「DOM 与事件」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `<script>` 放在 `<head>` 里直接查 DOM | `Cannot read properties of null` | 用 `defer`、放到 `</body>` 前，或监听 `DOMContentLoaded` |
| 用 `innerHTML` 插入用户输入 | XSS 漏洞 | 用 `textContent`，必要时先转义 |
| 循环里给每个元素 `addEventListener` | 列表大时性能差、内存占用高 | 用事件委托在父元素监听 |
| `querySelectorAll` 结果直接 `.map` | `TypeError: map is not a function` | NodeList 不是数组，先 `Array.from(...)` |
| 用 `event.target` 当委托目标 | 点到子元素时拿到子元素 | 用 `event.target.closest(选择器)` |
| 忘了 `preventDefault` | 表单提交导致页面刷新 | 在 `submit` 里阻止默认行为 |
| 用 `stopPropagation` 处理所有问题 | 其他监听器失效 | 明确事件流，只在必要时阻止 |
| 动态元素直接绑定事件 | 新增元素不响应 | 事件委托或插入后再绑定 |
| 在循环里拼接 `innerHTML +=` | 反复重排，性能差、监听器丢失 | 先拼字符串或 DocumentFragment，最后一次性插入 |
| 直接读 `element.style.width` | 拿到的是内联样式，可能是空字符串 | 用 `getComputedStyle(el).width` |

**教材衔接：故障现场**

### 现场 1：<script> 放在 <head> 里直接查 DOM

**症状**：在《DOM 与事件》的复现场景中，Cannot read properties of null。

**根因**：触发点是把“<script> 放在 <head> 里直接查 DOM”当成安全做法。它没有满足《DOM 与事件》要求的前提，因此先表现为“Cannot read properties of null”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《DOM 与事件》的问题，用 defer、放到 </body> 前，或监听 DOMContentLoaded。

**验证**：在《DOM 与事件》中按“用 defer、放到 </body> 前，或监听 DOMContentLoaded”调整后，从“<script> 放在 <head> 里直接查 DOM”的触发条件重放同一条路径，确认“Cannot read properties of null”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 2：用 innerHTML 插入用户输入

**症状**：在《DOM 与事件》的复现场景中，XSS 漏洞。

**根因**：“XSS 漏洞”只是表层结果。向上追溯会落到“用 innerHTML 插入用户输入”这一步，因为它省略了《DOM 与事件》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《DOM 与事件》的问题，用 textContent，必要时先转义。

**验证**：保留《DOM 与事件》里触发“XSS 漏洞”的输入、版本和日志，按“用 textContent，必要时先转义”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 3：循环里给每个元素 addEventListener

**症状**：在《DOM 与事件》的复现场景中，列表大时性能差、内存占用高。

**根因**：“列表大时性能差、内存占用高”只是表层结果。向上追溯会落到“循环里给每个元素 addEventListener”这一步，因为它省略了《DOM 与事件》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《DOM 与事件》的问题，用事件委托在父元素监听。

**验证**：先在《DOM 与事件》中记录“循环里给每个元素 addEventListener”留下的失败证据，再执行“用事件委托在父元素监听”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《异步编程》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《错误处理与调试》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《异步编程》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《错误处理与调试》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「DOM 与事件」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《DOM 与事件》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

这段 JavaScript 代码是「DOM 与事件」的示例片段，下面哪一项描述与它一致？

```javascript
const form = document.querySelector("#todo-form");
const input = document.querySelector("#todo-input");
const list = document.querySelector("#todo-list");

form.addEventListener("submit", (event) => {
  event.preventDefault();
  const text = input.value.trim();
  if (!text) return;

  const li = document.createElement("li");
  li.textContent = text;
  li.dataset.id = String(Date.now());
  list.append(li);
  input.value = "";
  input.focus();
});

// 事件委托：删除按钮未来新增的也能生效
list.addEventListener("click", (event) => {
  const li = event.target.closest("li");
  if (li) li.remove();
});
```

A. 这段代码会读取外部输入，结果依赖传入的数据。
B. 这段代码会产生可观察的输出，运行后能看到结果。
C. 这段代码只做静态声明，没有循环、分支或可观察输出。
D. 这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。

**参考答案**：这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。

**解析**：题干的正确项是这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行，在「DOM 与事件」里封装边界决定DOM从哪一步开始生效。这段代码出自「DOM 与事件」的正文示例，围绕DOM、事件、冒泡展开；把输入或边界换成空值、极值或失败情况后，结论要以「DOM 与事件」的实际运行结果为准。“JavaScript”与「DOM 与事件」的术语表相呼应，只有符合DOM、事件、冒泡约束的“这段代码把主要逻辑封装在函数或方法里”才是正文支持的结论。

### 自测 2

把用户输入插入页面，安全的做法是？

A. eval
B. innerHTML
C. textContent
D. document.write

**参考答案**：textContent

**解析**：在「DOM 与事件」里，textContent 把内容当纯文本，不会执行脚本。在「DOM 与事件」里，innerHTML 需先转义以防 XSS。「DOM 与事件」要求先交代DOM、事件、冒泡的前提再下结论，所以“textContent”只在题干“把用户输入插入页面”给定的条件下成立。

### 自测 3

围绕“DOM 与事件”中的 DOM、事件、冒泡，下列哪两项是本课强调的实践判断？

A. 验证 事件 时要固定版本并覆盖边界输入，结论才可复现
B. 把 事件 的单次运行结果当成所有版本和规模都成立
C. 学习 DOM 时要同时说明输入、输出和失败路径，不能只看正常流程
D. 只要 DOM 的常规示例通过，就可以跳过边界与异常路径

**参考答案**：验证 事件 时要固定版本并覆盖边界输入，结论才可复现；学习 DOM 时要同时说明输入、输出和失败路径，不能只看正常流程

**解析**：结论应落在验证 事件 时要固定版本并覆盖边界输入。本课把DOM 与事件拆成概念、示例与故障现场三部分，因此判断 DOM 时必须同时交代输入、输出和失败路径，这使“学习 DOM 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在DOM 与事件里，判断 事件 时要固定版本与边界输入，所以“验证 事件 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

**教材衔接：复习与自测**

- [ ] 会用 `querySelector` 与 `querySelectorAll` 查询元素。
- [ ] 插入不可信文本时使用 `textContent`。
- [ ] 会用事件委托处理动态列表。
- [ ] 表单提交先 `preventDefault`，再用 `FormData` 取值。
- [ ] 知道脚本要等 DOM 就绪，或用 `defer`。

**教材衔接：动手练习**

> 本课练习重点：围绕「DOM、事件、冒泡」完成复述、实验和交付，每个结果都要能被别人检查。

先在 Node 或浏览器复现 DOM 的行为，再改写异步与错误路径，最后补测试。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. DOM 与事件解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「事件」是什么关系？

验收标准：说明 DOM 与 事件 的分工，并写出一个失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：先在「选择与修改元素」里找一个可运行的最小输入，再按五步法记录DOM的影响；预测与结果不一致时补写被忽略的前提。

### 练习 3：交付一个小结果（30 分钟）

用 querySelectorAll 写一个可直接运行的片段，覆盖正常、边界与失败输入。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「DOM」和「事件」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

### 任务 1：先跑通，再解释

```javascript
const button = document.querySelector('#save');

function handleClick(event) {
  console.log('点击了', event.target);
}
button.addEventListener('click', handleClick);
button.removeEventListener('click', handleClick);   // 移除需传同一函数引用
```

### 任务 2：只改一个条件

把「DOM 与事件」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：把 事件 换成边界值，其他输入保持原样。
- 预测：先写下「DOM 与事件」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响DOM。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的 DOM 数据，保持输出格式与任务 1 一致。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「事件委托能生效的前提是？」的判断依据。
- [ ] 不看解析，能说出「把用户输入插入页面，安全的做法是？」的判断依据。
- [ ] 不看解析，能说出「event.preventDefault() 的作用是？」的判断依据。
- [ ] 不看解析，能说出「DOMContentLoaded 与 load 的区别是？」的判断依据。
- [ ] 至少运行一次 querySelectorAll 的示例，记录输入、输出和 DOM 的边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

---

## 术语速查

把「DOM 与事件」里反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 一句话说明 |
| --- | --- |
| `DOM` | DOM 操作记住三件事：用 querySelector 选择、用 addEventListener 绑定、用事件委托处理动态列表，并把用户内容当作不可信数据。 |
| `事件` | 事件是「用户做了什么」的通知，你注册回调函数来决定怎么响应。 |
| `冒泡` | 事件从触发元素向上传播到祖先节点的过程。 |
| `事件委托` | 把监听器挂在父元素上，靠事件冒泡统一处理子元素事件，避免为每个子节点绑定监听。 |
| `localStorage` | 浏览器提供的同源持久化键值存储，容量有限且只能存字符串。 |
| `XSS` | 插入用户输入时优先 textContent，使用 innerHTML 前必须转义，否则存在 XSS 风险。 |

## 考点精讲

### 考点 1：代码补全·DOM

- **题目**：这段 JavaScript 代码是「DOM 与事件」的示例片段，下面哪一项描述与它一致？
- **判断依据**：题干的正确项是这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行，在「DOM 与事件」里封装边界决定DOM从哪一步开始生效。这段代码出自「DOM 与事件」的正文示例，围绕DOM、事件、冒泡展开；把输入或边界换成空值、极值或失败情况后，结论要以「DOM 与事件」的实际运行结果为准。“JavaScript”与「DOM 与事件」的术语表相呼应，只有符合DOM、事件、冒泡约束的“这段代码把主要逻辑封装在函数或方法里”才是正文支持的结论。

### 考点 2：概念判断·DOM

- **题目**：把用户输入插入页面，安全的做法是？
- **判断依据**：在「DOM 与事件」里，textContent 把内容当纯文本，不会执行脚本。在「DOM 与事件」里，innerHTML 需先转义以防 XSS。「DOM 与事件」要求先交代DOM、事件、冒泡的前提再下结论，所以“textContent”只在题干“把用户输入插入页面”给定的条件下成立。

### 考点 3：概念判断·DOM

- **题目**：event.preventDefault 的作用是？
- **判断依据**：在「DOM 与事件」里，阻止浏览器默认行为（如提交表单、跳转链接）。preventDefault 取消默认行为，stopPropagation 才是阻止冒泡，两者常被混淆。这道题的关键在「DOM 与事件」的DOM、事件、冒泡：先确认题干“event.preventDefau”问的是哪一步，再排除偷换前提的选项。

### 考点 4：多选辨析·DOM

- **题目**：围绕“DOM 与事件”中的 DOM、事件、冒泡，下列哪两项是本课强调的实践判断？
- **判断依据**：结论应落在验证 事件 时要固定版本并覆盖边界输入。本课把DOM 与事件拆成概念、示例与故障现场三部分，因此判断 DOM 时必须同时交代输入、输出和失败路径，这使“学习 DOM 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在DOM 与事件里，判断 事件 时要固定版本与边界输入，所以“验证 事件 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 5：概念判断·DOM

- **题目**：DOMContentLoaded 与 load 的区别是？
- **判断依据**：在「DOM 与事件」里，DOMContentLoaded 在 HTML 解析完成时触发。脚本尽早绑定事件应使用 DOMContentLoaded，统计完整加载耗时才用 load。在「DOM 与事件」里判断这道题，要把DOM、事件、冒泡的条件、过程与失败路径逐项对齐，换成“DOMContentLoaded 与”这个场景，只有满足前提的结论才成立。

### 考点 6：填空·DOM

- **题目**：补全代码：「DOM 与事件」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `button.____('click', handleClick); // 移除需传同一函数引用`
- **判断依据**：空格应填写「removeEventListener」、「removeeventlistener」。把“removeEventListener”代回「DOM 与事件」里“DOM 与事件示例中”的例子核对，条件一旦改变，结论就要用DOM、事件、冒泡重新推导。「DOM 与事件」要求先交代DOM、事件、冒泡的前提再下结论，所以“removeEventListener”只在题干“与事件示例中”给定的条件下成立。

## English Overview

**Title:** DOM & Events

**Summary:** Selecting elements, events, delegation, forms and storage.

**Category:** JavaScript
**Level:** 进阶
**Key terms:** DOM, 事件, 冒泡, 事件委托, localStorage, XSS

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Node.js 22+ / 现代浏览器；本课聚焦 DOM。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：DOM、事件、冒泡、事件委托、localStorage、XSS
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-05-17
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [MDN JavaScript 指南](https://developer.mozilla.org/docs/Web/JavaScript/Guide) | 语言基础与浏览器 API |
| [MDN 模块](https://developer.mozilla.org/docs/Web/JavaScript/Guide/Modules) | ES Module 与依赖组织 |
| [Node 事件循环](https://nodejs.org/en/learn/asynchronous-work/event-loop-timers-and-nexttick) | 事件循环与异步顺序 |

> 「DOM 与事件」的链接用于离线阅读后的延伸核对；App 不会自动联网。
