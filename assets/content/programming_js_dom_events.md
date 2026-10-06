# DOM 与事件

![DOM 选择、事件监听与委托](images/diagram_js_dom.webp)

![DOM 与事件](images/remaining_js_dom_events.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：14 分钟

## 学习目标

- 能用自己的话解释「DOM 与事件」解决了什么问题，而不是只背术语。
- 能说清 「DOM」、「事件」、「冒泡」、「事件委托」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「JavaScript」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：元素选择与修改、事件监听、冒泡与事件委托、表单与本地存储。

## 前置知识

- 先完成上一课《异步编程》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：DOM、事件、冒泡。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 选择与修改元素

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

## 事件监听

```javascript
const button = document.querySelector('#save');

function handleClick(event) {
  console.log('点击了', event.target);
}
button.addEventListener('click', handleClick);
button.removeEventListener('click', handleClick);   // 移除需传同一函数引用
```

## 冒泡与事件委托

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

## 表单与本地存储

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

## 开发者工具

Elements 看结构、Console 试代码、Network 看请求、Sources 打断点、Application 看存储与缓存。

## 事件与 DOM 的性能注意点

| 场景 | 问题 | 做法 |
| --- | --- | --- |
| 列表渲染上千项 | 逐个 append 触发多次重排 | 用 DocumentFragment 批量插入，或虚拟滚动 |
| 高频事件（scroll/resize/input） | 每秒触发几十次 | 用防抖（debounce）或节流（throttle） |
| 大量子元素事件 | 绑定上千个监听器 | 事件委托到父容器 |
| 读写布局属性交替 | 强制同步布局（layout thrashing） | 先批量读，再批量写 |
| 频繁改样式 | 逐条改 style 触发多次重绘 | 改 class 或使用 CSS 变量 |

清理与正确性：组件卸载时移除监听器（`removeEventListener` 需同一函数引用）与取消定时器；`requestAnimationFrame` 适合逐帧更新；表单提交用 `preventDefault` 后自行校验，避免页面刷新丢失状态。

## 本课小结
DOM 操作记住三件事：**用 querySelector 选择、用 addEventListener 绑定、用事件委托处理动态列表**，并把用户内容当作不可信数据。


## DOM 查询与修改速查

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

## 表单速查

| 目的 | 写法 |
| --- | --- |
| 阻止提交刷新页面 | `form.addEventListener("submit", (e) => { e.preventDefault(); ... })` |
| 读取输入 | `input.value.trim()` |
| 复选框状态 | `checkbox.checked` |
| 单选组取值 | `form.elements["gender"].value` |
| 表单整体取值 | `new FormData(form)` 或 `Object.fromEntries(new FormData(form))` |
| 自定义校验 | `input.setCustomValidity("提示")` |
| 触发原生校验 | `form.reportValidity()` |

## 常见错误对照表

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

## 自测清单

- [ ] 会用 `querySelector` 与 `querySelectorAll` 查询元素。
- [ ] 插入不可信文本时使用 `textContent`。
- [ ] 会用事件委托处理动态列表。
- [ ] 表单提交先 `preventDefault`，再用 `FormData` 取值。
- [ ] 知道脚本要等 DOM 就绪，或用 `defer`。


## 零基础详解：DOM 操作与事件处理

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

## 动手练习


> 本课练习重点：围绕「DOM、事件、冒泡」完成复述、实验和交付，每个结果都要能被别人检查。

先在 Node 或浏览器复现行为，再改写异步与错误路径，最后补测试。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「DOM 与事件」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「事件」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

在浏览器控制台或 Node.js 中写一个最小示例，列出至少 3 组输入输出。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「DOM」和「事件」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。


## 可运行练习

下面 3 个任务围绕“DOM 与事件”展开，代码可以直接粘贴到 App 的离线沙箱里运行；如果示例会读取标准输入，请按代码注释在沙箱的 stdin 区域填入同样格式的数据。

### 任务 1：先跑通，再解释

```javascript
const button = document.querySelector('#save');

function handleClick(event) {
  console.log('点击了', event.target);
}
button.addEventListener('click', handleClick);
button.removeEventListener('click', handleClick);   // 移除需传同一函数引用
```

**预期输出**：运行后会输出与“DOM 与事件”相关的关键结果；请重点核对输出行数、最后一个数值和异常提示。

**验收标准**：代码能正常运行；逐行解释每个变量的值如何变化，并指出哪一行决定了最终结果。

### 任务 2：只改一个条件

复制上面的代码，只修改一个输入、边界或参数（例如空值、最大值、循环次数、过滤条件），先写出你的预测，再实际运行。

**验收标准**：留下“原结果 → 改动 → 预测 → 实际结果 → 差异原因”五步记录；如果预测错误，要写出修正后的心智模型。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的数据或场景，保持输出格式与任务 1 一致。

**验收标准**：代码不少于 10 行，至少包含 1 个边界检查；把代码和运行结果保存到笔记或片段库。


## 故障现场

这一节把“DOM 与事件”最常见的失败方式还原成现场记录，练习时按“症状 → 复现 → 定位 → 修复 → 预防”的顺序排查。

### 现场 1：“DOM 与事件”的 DOM 常规用例通过，但边界用例失败

**症状**：在“DOM 与事件”的练习或生产场景里出现““DOM 与事件”的 DOM 常规用例通过，但边界用例失败”。

**复现**：准备一组最小输入，只保留触发““DOM 与事件”的 DOM 常规用例通过，但边界用例失败”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“DOM 的前置条件与取值边界没有写进代码，默认值掩盖了空值和极值”检查调用链、输入数据和环境配置，先验证假设再改代码。

**修复**：为“DOM 与事件”补一条空值或极值用例，把前置条件写成断言，并让失败信息直接指出是哪个输入越界

**预防**：把““DOM 与事件”的 DOM 常规用例通过，但边界用例失败”写成一条自动化用例，并在“DOM 与事件”的验收清单里保留对应检查项。


### 现场 2：“DOM 与事件”的 事件 结果在两次运行之间不一致

**症状**：在“DOM 与事件”的练习或生产场景里出现““DOM 与事件”的 事件 结果在两次运行之间不一致”。

**复现**：准备一组最小输入，只保留触发““DOM 与事件”的 事件 结果在两次运行之间不一致”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“事件 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。

**修复**：固定“DOM 与事件”使用的版本与随机种子，记录两次运行的完整输入和输出，再逐项消除非确定性来源

**预防**：把““DOM 与事件”的 事件 结果在两次运行之间不一致”写成一条自动化用例，并在“DOM 与事件”的验收清单里保留对应检查项。


### 现场 3：“DOM 与事件”的验证只在开发机通过

**症状**：在“DOM 与事件”的练习或生产场景里出现““DOM 与事件”的验证只在开发机通过”。

**复现**：准备一组最小输入，只保留触发““DOM 与事件”的验证只在开发机通过”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“环境版本、配置和输入规模与目标环境不同，DOM 缺少可重复的验证记录”检查调用链、输入数据和环境配置，先验证假设再改代码。

**修复**：把“DOM 与事件”的运行环境、输入样本和预期输出写成清单，并在另一套环境复跑同一条命令

**预防**：把““DOM 与事件”的验证只在开发机通过”写成一条自动化用例，并在“DOM 与事件”的验收清单里保留对应检查项。



## 版本与时效

这一节记录“DOM 与事件”涉及的版本基线与升级检查点，避免把某个版本的默认行为当成永久结论。

- ECMAScript 2025/2026 持续加入新能力，Node 24 是当前 LTS 主线
- 运行时要同时考虑浏览器基线、Node LTS 与打包工具的降级策略
- 升级前用特性检测和构建目标矩阵验证，不要只在本机浏览器测试
- 标准与兼容表：https://developer.mozilla.org/docs/Web/JavaScript

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改一个版本变量，记录编译、测试、性能与产物体积的变化。
- 重点回归默认值、弃用警告、序列化格式、并发语义和错误信息。
- 升级完成后更新本课的“最后复核 / 下次复核”日期与版本说明。


## 考点精讲：把测验题还原成判断过程

本课有 6 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：事件委托能生效的前提是？

- **正确判断**：事件会冒泡到父元素
- **判断依据**：正确答案是「事件会冒泡到父元素」，本课在「本课小结」中说明：DOM 操作记住三件事：用 querySelector 选择、用 addEventListener 绑定、用事件委托处理动态列表，并把用户内容当作不可信数据。事件冒泡让父元素可以统一处理子元素事件，动态新增的子元素也不需要重新绑定。本课还在「冒泡与事件委托」中说明：事件默认从目标向外冒泡（target → 祖先），因此可以在父元素上统一处理子元素事件。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 2：把用户输入插入页面，安全的做法是？

- **正确判断**：textContent
- **判断依据**：textContent 把内容当纯文本，不会执行脚本。innerHTML 需先转义以防 XSS。针对「把用户输入插入页面，安全的做法是，」，本课在「选择与修改元素」中说明：插入用户输入时优先 textContent，使用 innerHTML 前必须转义，否则存在 XSS 风险。本课还在「本课小结」中说明：DOM 操作记住三件事：用 querySelector 选择、用 addEventListener 绑定、用事件委托处理动态列表，并把用户内容当作不可信数据。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 3：event.preventDefault() 的作用是？

- **正确判断**：阻止浏览器默认行为（如提交表单、跳转链接）
- **判断依据**：正确答案是「阻止浏览器默认行为（如提交表单、跳转链接）」，本课在「事件与 DOM 的性能注意点」中说明：清理与正确性：组件卸载时移除监听器（removeEventListener 需同一函数引用）与取消定时器。preventDefault 取消默认行为，stopPropagation 才是阻止冒泡，两者常被混淆。本课还在「冒泡与事件委托」中说明：委托的好处：动态新增的元素无需重新绑定监听器。本课还在「零基础详解：DOM 操作与事件处理」中说明：DOM 是浏览器把 HTML 变成的一棵「节点树」，JS 通过它读写页面。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 4：addEventListener 的第三个参数 capture: true 表示？

- **正确判断**：在捕获阶段触发监听（从外到内）
- **判断依据**：正确答案是「在捕获阶段触发监听（从外到内）」，本课在「冒泡与事件委托」中说明：事件默认从目标向外冒泡（target → 祖先），因此可以在父元素上统一处理子元素事件。事件先捕获到目标再冒泡回来，理解这个顺序才能处理好委托与阻止传播。本课还在「零基础详解：DOM 操作与事件处理」中说明：事件是「用户做了什么」的通知，你注册回调函数来决定怎么响应。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 5：DOMContentLoaded 与 load 的区别是？

- **正确判断**：DOMContentLoaded 在 HTML 解析完成时触发
- **判断依据**：正确答案是「DOMContentLoaded 在 HTML 解析完成时触发」，本课在「零基础详解：DOM 操作与事件处理」中说明：能说出 querySelector 与 querySelectorAll 的区别。脚本尽早绑定事件应使用 DOMContentLoaded，统计完整加载耗时才用 load。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 6：补全代码：「DOM 与事件」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `button.____('click', handleClick); // 移除需传同一函数引用`

- **正确判断**：removeEventListener / removeeventlistener
- **判断依据**：正确答案是「removeEventListener」，本课在「事件与 DOM 的性能注意点」中说明：清理与正确性：组件卸载时移除监听器（removeEventListener 需同一函数引用）与取消定时器。本课还在「开发者工具」中说明：Elements 看结构、Console 试代码、Network 看请求、Sources 打断点、Application 看存储与缓存。
- **迁移检查**：不看题干，用自己的话补全这句话，再与标准答案对照。

### 补充自测（2 题）

1. 围绕“DOM 与事件”中的 DOM、事件、冒泡，下列哪两项是本课强调的实践判断？
2. 下面这段 JavaScript 代码复现了“DOM 与事件”中 DOM、事件、冒泡 相关的一个常见故障，哪一项最准确地解释了问题？

这些题按“先定位概念、再排除边界错误、最后核对答案”的顺序作答；每题解析都给出了判断依据。


## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「事件委托能生效的前提是？」的判断依据。
- [ ] 不看解析，能说出「把用户输入插入页面，安全的做法是？」的判断依据。
- [ ] 不看解析，能说出「event.preventDefault() 的作用是？」的判断依据。
- [ ] 不看解析，能说出「addEventListener 的第三个参数 capture: true 表示…」的判断依据。
- [ ] 不看解析，能说出「DOMContentLoaded 与 load 的区别是？」的判断依据。
- [ ] 不看解析，能说出「补全代码：「DOM 与事件」示例中，下面这行代码缺少哪个关键字或函数名？请填入 …」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

把本课反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 本课语境 |
| --- | --- |
| `textContent` | 插入用户输入时优先 `textContent`，使用 `innerHTML` 前必须转义，否则存在 XSS 风险。 |
| `innerHTML` | 插入用户输入时优先 `textContent`，使用 `innerHTML` 前必须转义，否则存在 XSS 风险。 |
| `removeEventListener` | 清理与正确性：组件卸载时移除监听器（`removeEventListener` 需同一函数引用）与取消定时器；`requestAnimationFrame` 适合逐帧更新；表单提交用 `preventDefault` 后… |
| `requestAnimationFrame` | 清理与正确性：组件卸载时移除监听器（`removeEventListener` 需同一函数引用）与取消定时器；`requestAnimationFrame` 适合逐帧更新；表单提交用 `preventDefault` 后… |
| `preventDefault` | 清理与正确性：组件卸载时移除监听器（`removeEventListener` 需同一函数引用）与取消定时器；`requestAnimationFrame` 适合逐帧更新；表单提交用 `preventDefault` 后… |
| `document.querySelector(".card")` | \| 查单个元素 \| `document.querySelector(".card")` \| 返回第一个匹配或 `null` \| |
| `null` | \| 查单个元素 \| `document.querySelector(".card")` \| 返回第一个匹配或 `null` \| |
| `document.querySelectorAll(".card")` | \| 查全部元素 \| `document.querySelectorAll(".card")` \| 返回静态 NodeList，可 `forEach` \| |
| `forEach` | \| 查全部元素 \| `document.querySelectorAll(".card")` \| 返回静态 NodeList，可 `forEach` \| |
| `document.getElementById("app")` | \| 按 id 查 \| `document.getElementById("app")` \| 最快，但只按 id \| |
| `el.textContent = "内容"` | \| 改文本 \| `el.textContent = "内容"` \| 安全，不解析 HTML \| |
| `el.innerHTML = html` | \| 改 HTML \| `el.innerHTML = html` \| 有 XSS 风险，只用可信内容 \| |

## 面试问答与自测

下面把本课考点换成面试追问。先口述自己的答案，
再对照参考回答检查是否遗漏了前提、边界或失败路径。

### 追问 1：事件委托能生效的前提是？

**参考回答**：正确答案是「事件会冒泡到父元素」，本课在「本课小结」中说明：DOM 操作记住三件事：用 querySelector 选择、用 addEventListener 绑定、用事件委托处理动态列表，并把用户内容当作不可信数据。事件冒泡让父元素可以统一处理子元素事件，动态新增的子元素也不需要重新绑定。本课还在「冒泡与事件委托」中说明：事件默认从目标向外冒泡（target → 祖先），因此可以在父元素上统一处理子元素事件。

### 追问 2：把用户输入插入页面，安全的做法是？

**参考回答**：textContent 把内容当纯文本，不会执行脚本。innerHTML 需先转义以防 XSS。针对「把用户输入插入页面，安全的做法是，」，本课在「选择与修改元素」中说明：插入用户输入时优先 textContent，使用 innerHTML 前必须转义，否则存在 XSS 风险。本课还在「本课小结」中说明：DOM 操作记住三件事：用 querySelector 选择、用 addEventListener 绑定、用事件委托处理动态列表，并把用户内容当作不可信数据。

### 追问 3：event.preventDefault() 的作用是？

**参考回答**：正确答案是「阻止浏览器默认行为（如提交表单、跳转链接）」，本课在「事件与 DOM 的性能注意点」中说明：清理与正确性：组件卸载时移除监听器（removeEventListener 需同一函数引用）与取消定时器。preventDefault 取消默认行为，stopPropagation 才是阻止冒泡，两者常被混淆。本课还在「冒泡与事件委托」中说明：委托的好处：动态新增的元素无需重新绑定监听器。本课还在「零基础详解·DOM 操作与事件处理」中说明：DOM 是浏览器把 HTML 变成的一棵「节点树」，JS 通过它读写页面。

### 追问 4：addEventListener 的第三个参数 capture: true 表示？

**参考回答**：正确答案是「在捕获阶段触发监听（从外到内）」，本课在「冒泡与事件委托」中说明：事件默认从目标向外冒泡（target → 祖先），因此可以在父元素上统一处理子元素事件。事件先捕获到目标再冒泡回来，理解这个顺序才能处理好委托与阻止传播。本课还在「零基础详解·DOM 操作与事件处理」中说明：事件是「用户做了什么」的通知，你注册回调函数来决定怎么响应。

### 追问 5：DOMContentLoaded 与 load 的区别是？

**参考回答**：正确答案是「DOMContentLoaded 在 HTML 解析完成时触发」，本课在「零基础详解·DOM 操作与事件处理」中说明：能说出 querySelector 与 querySelectorAll 的区别。脚本尽早绑定事件应使用 DOMContentLoaded，统计完整加载耗时才用 load。

## English Overview

**Title:** DOM & Events

**Summary:** Selecting elements, events, delegation, forms and storage.

**Category:** JavaScript  
**Level:** 进阶  
**Key terms:** DOM, 事件, 冒泡, 事件委托, localStorage, XSS

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：Node.js 22+ / 现代浏览器
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：DOM、事件、冒泡、事件委托、localStorage、XSS
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [MDN JavaScript](https://developer.mozilla.org/docs/Web/JavaScript) | 语言、DOM 与运行时 |
| [ECMAScript](https://ecma-international.org/publications-and-standards/standards/ecma-262/) | 语言标准 |

> 本课主题：元素选择与修改、事件监听、冒泡与事件委托、表单与本地存储。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。
