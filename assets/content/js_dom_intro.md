# JavaScript DOM 入门

> 内容更新时间：2026-10-06 · 学习阶段：基础 · 预计用时：35 分钟

![DOM 操作入门四步](images/diagram_js_dom_intro.webp)

![JavaScript DOM 入门](images/remaining_js_dom_intro.webp)

## 学习目标

- 先认识JavaScript DOM 入门需要的工具、输入和输出。
- 按步骤运行最小示例，并记录结果与错误。
- 用一个边界输入验证自己是否真正掌握。

## 前置知识

- 会进行基本的文件或命令行操作。
- 不需要预先掌握「JavaScript」的高级知识。

## 一句话入门

查找元素、修改文本并响应用户点击。

## 最小示例

```javascript
const button = document.createElement("button");
button.textContent = "点击我";
document.body.append(button);
console.log(document.querySelector("button").textContent);
```

## 预期输出

```text
点击我
```

## 常见错误与排查

> 说明：本表由《JavaScript DOM 入门》的核心知识整理（2026-10-07），人工复核进度见 docs/content_review_batches.md。

| 易错点 | 容易踩的做法 | 正确结论 |
| --- | --- | --- |
| 样式与文本状态各自为政 | 界面与数据不一致 | 统一由状态驱动渲染，类名切换而不是零散改样式 |
| 查询结果不判空就操作 | 空引用直接报错 | 查询后先判断元素是否存在 |
| 频繁读写布局属性 | 触发多次重排，页面卡顿 | 批量读写，先集中读再集中写 |

## 动手练习

1. 原样运行最小示例，保存命令和输出。
2. 把数字 2 改成 10，预测并验证新结果。
3. 制造一个错误输入，写出错误信息和修复方法。

## 本课小结

- 入门阶段先保证能运行、能观察、能解释，再追求复杂功能。
- 每次只改一个变量，记录预测与实际结果。
- 遇到错误先看第一条错误信息，再回到最小示例。

## 代码实验：把示例跑成证据

### 实验一：建立基线

```javascript
const button = document.createElement("button");
button.textContent = "点击我";
document.body.append(button);
console.log(document.querySelector("button").textContent);
```

### 实验二：只改一个输入

沿用「JavaScript DOM 入门」的最小示例做一次单变量实验：

| 实验 | 改动 | 预测 | 实际 | 结论 |
| --- | --- | --- | --- | --- |
| 基线 | 保持「JavaScript DOM 入门」示例原样 |  |  |  |
| 边界 | 把JavaScript DOM 入门换成空值或极值 |  |  |  |
| 失败 | 给JavaScript传入非法输入 |  |  |  |

做完后用一句话写出「JavaScript DOM 入门」的结论：输入怎么变，结果才怎么变。

### 实验三：制造一个可控错误

把 JavaScript DOM 入门 相关的那一行改成边界值（空、极值或类型不符），记录第一条错误信息、发生位置和恢复方式。

| 实验 | 改动 | 预测 | 实际 | 结论 |
| --- | --- | --- | --- | --- |
| 基线 | 保持原样 |  |  |  |
| 边界 |  |  |  |  |
| 失败 |  |  |  |  |

### 实验四：用三句话复述

1. JavaScript DOM 入门 的输入是什么，哪些取值合法，哪些属于边界或非法范围？
2. createElement 的执行顺序里，哪一步会写数据或产生外部副作用？
3. 输出如何验证，失败时第一条可观察证据是什么？

## JavaScript 基础机制速览

### 引擎、事件循环与执行上下文

JavaScript 是单线程执行模型，调用栈执行同步代码，事件循环在栈清空后处理任务队列和微任务队列。`setTimeout`、Promise、事件回调都通过异步机制排队执行。理解调用栈、任务队列和微任务的顺序，才能解释“为什么日志顺序和代码顺序不同”。浏览器和 Node.js 提供不同的宿主 API，但语言核心相同。

### 变量、作用域与类型转换

`var` 函数作用域且会提升，`let` 和 `const` 块级作用域并有暂时性死区。`const` 禁止重新赋值，但对象内容仍可修改。JavaScript 有原始类型和对象类型，`==` 会做隐式类型转换，`===` 同时比较类型和值；日常判断优先使用 `===`，只有明确需要转换时才用 `==`。`null`、`undefined`、`NaN` 的语义不同，判断存在性时要写清。

### 函数、闭包与 this

函数是一等对象，可以作为参数、返回值和对象属性。闭包让函数记住定义时的词法作用域，常用于回调、模块私有状态和工厂函数。`this` 的值取决于调用方式，普通调用、方法调用、构造函数和箭头函数规则不同；箭头函数不绑定自己的 this，适合回调，不适合需要动态 this 的方法。

### 对象、原型与模块

对象是键值集合，原型链提供属性查找和继承。`class` 是原型继承的语法糖，`extends` 和 `super` 简化继承写法。模块使用 `import`/`export` 显式声明依赖，避免全局污染。不可变数据、展开运算符和结构化克隆各有边界，浅拷贝不会复制嵌套对象。

### Promise、async 与 DOM

Promise 表示未来完成或失败的结果，`async/await` 让异步代码更接近同步写法，但不会把异步变成阻塞。错误要用 try/catch 或 `.catch` 处理，多个独立任务可以用 `Promise.all`，需要全部结束再汇总可以用 `Promise.allSettled`。DOM 操作应批量进行，避免在循环中反复读写布局；事件监听要注意冒泡、捕获、默认行为和移除监听器，防止内存泄漏。

## 可运行练习

### 任务 1：先跑通，再解释

```javascript
const button = document.createElement("button");
button.textContent = "点击我";
document.body.append(button);
console.log(document.querySelector("button").textContent);
```

### 任务 2：只改一个条件

把「JavaScript DOM 入门」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：只把 JavaScript DOM 入门 的输入换成空值、极值或错误输入，其余保持不变。
- 预测：先写下「JavaScript DOM 入门」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响JavaScript DOM 入门。

### 任务 3：迁移到自己的数据

换一个 JavaScript 场景重做一次，确认结论不是只对示例数据成立。

## 故障现场

### 现场 1：样式与文本状态各自为政

**症状**：在《JavaScript DOM 入门》的复现场景中，界面与数据不一致。

**根因**：“界面与数据不一致”只是表层结果。向上追溯会落到“样式与文本状态各自为政”这一步，因为它省略了《JavaScript DOM 入门》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《JavaScript DOM 入门》的问题，统一由状态驱动渲染，类名切换而不是零散改样式。

**验证**：保留《JavaScript DOM 入门》里触发“界面与数据不一致”的输入、版本和日志，按“统一由状态驱动渲染，类名切换而不是零散改样式”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 2：查询结果不判空就操作

**症状**：在《JavaScript DOM 入门》的复现场景中，空引用直接报错。

**根因**：“空引用直接报错”只是表层结果。向上追溯会落到“查询结果不判空就操作”这一步，因为它省略了《JavaScript DOM 入门》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《JavaScript DOM 入门》的问题，查询后先判断元素是否存在。

**验证**：先在《JavaScript DOM 入门》中记录“查询结果不判空就操作”留下的失败证据，再执行“查询后先判断元素是否存在”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 3：频繁读写布局属性

**症状**：在《JavaScript DOM 入门》的复现场景中，触发多次重排，页面卡顿。

**根因**：“触发多次重排，页面卡顿”只是表层结果。向上追溯会落到“频繁读写布局属性”这一步，因为它省略了《JavaScript DOM 入门》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《JavaScript DOM 入门》的问题，批量读写，先集中读再集中写。

**验证**：在《JavaScript DOM 入门》中按“批量读写，先集中读再集中写”调整后，从“频繁读写布局属性”的触发条件重放同一条路径，确认“触发多次重排，页面卡顿”不再出现，并补一个相邻边界用例检查没有引入新问题。

## 版本与时效

- 打包与运行时版本会共同影响 JavaScript，升级前先固定二者版本。
- 升级前先用 createElement 建立基线：记录版本、命令和输出，升级后只比较这些可观察量。

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 一次只改一个版本条件，把 JavaScript DOM 入门 相关的差异单独记成一条结论。
- 升级后重点回归 JavaScript DOM 入门 的默认值、警告信息与错误格式。
- 升级后把 createElement 的实测版本写进「内容元数据」，再更新复核日期。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「document.createElement("button") 的作用是？」的判断依据。
- [ ] 不看解析，能说出「document.querySelector("button") 会返回什么？」的判断依据。
- [ ] 不看解析，能说出「要让按钮响应用户点击，应该使用哪个方法？」的判断依据。
- [ ] 不看解析，能说出「填空：JavaScript DOM 入门术语速查中，表示的判断依据。
- [ ] 用 JavaScript DOM 入门 构造一个正常输入和一个边界输入，分别记录输出与判断依据。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 复习与自测

逐节自检：能说清 JavaScript DOM 入门 的输入、输出与失败路径才算通过，否则回到原文。

### 最小示例

```javascript
const button = document.createElement("button");
button.textContent = "点击我";
document.body.append(button);
console.log(document.querySelector("button").textContent);
```

自检：这一节与相邻主题的边界在哪里？

### 预期输出

```text
点击我
```

### 常见错误

自检：把这一节讲给没学过的人，最需要强调哪一点？

### 动手练习

自检：如果去掉这一节里的一个前提，结论会怎样变化？

## 术语速查

把「JavaScript DOM 入门」里反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 一句话说明 |
| --- | --- |
| `DOM` | 浏览器把 HTML 解析成的对象树，JavaScript 通过它读写页面。 |
| `querySelector` | 用 CSS 选择器找到第一个匹配元素，querySelectorAll 返回全部。 |
| `textContent 与 innerHTML` | 前者按纯文本读写，后者会解析 HTML，有注入风险。 |
| `事件监听` | addEventListener 把处理函数绑定到事件，回调里用 event 取详情。 |
| `事件冒泡` | 事件从触发元素向上传播，可用 stopPropagation 阻止。 |
| `函数` | 函数是一等对象，可以作为参数、返回值和对象属性 |

## 考点精讲

### 考点 1：代码补全·JavaScript DOM 入门

- **题目**：下面这段 JavaScript 代码摘自「JavaScript DOM 入门」的正文示例。关于这段代码，下面哪一项说法与实际内容相符？
- **判断依据**：在「JavaScript DOM 入门」里，题干的正确项是这段代码会产生可观察的输出，运行后能看到结果，在「JavaScript DOM 入门」里要结合JavaScript DOM 入门核对输出是否符合预期。这段代码出自「JavaScript DOM 入门」的正文示例，围绕JavaScript DOM 入门、JavaScript、入门练习展开；把输入或边界换成空值、极值或失败情况后，结论要以「JavaScript DOM 入门」的实际运行结果为准。

### 考点 2：多选辨析·JavaScript DOM 入门

- **题目**：围绕“JavaScript DOM 入门”中的 JavaScript DOM 入门、JavaScript、入门练习，下列哪两项是本课强调的实践判断？
- **判断依据**：题干的正确项是学习 JavaScript DOM 入门 时要同时说明输入、输出和失败路径，不能只看正常流程。在「JavaScript DOM 入门」里，验证 JavaScript 时要固定版本并覆盖边界输入，结论才可复现。在「JavaScript DOM 入门」里判断这道题，要把JavaScript DOM 入门、JavaScript、入门练习的条件、过程与失败路径逐项对齐，换成“围绕JavaScript DOM 入”这个场景，只有满足前提的结论才成立。

### 考点 3：概念判断·JavaScript DOM 入门

- **题目**：示例中 console.log(document.querySelector("button").textContent) 输出什么？
- **判断依据**：在「JavaScript DOM 入门」里，点击我，读取的是按钮元素的文本内容。示例先把按钮挂载到 body，再通过选择器找到它并读取 textContent，因此输出创建时设置的文本「点击我」。“console.log(document.querySele”与「JavaScript DOM 入门」的术语表相呼应，只有符合JavaScript DOM 入门、JavaScript、入门练习约束的“点击我，读取的是按钮元素的文本内容”才是正文支持的结论。

### 考点 4：概念判断·JavaScript DOM 入门

- **题目**：要让按钮响应用户点击，应该使用哪个方法？
- **判断依据**：在「JavaScript DOM 入门」里，结论应落在「addEventListener」。addEventListener 把事件类型与处理函数绑定到元素上，点击发生时浏览器调用处理函数并传入事件对象。要让按钮响应用户点击，应该使用哪个方法。「JavaScript DOM 入门」要求先交代JavaScript DOM 入门、JavaScript、入门练习的前提再下结论，所以“addEventListener("cl”只在题干“要让按钮响应用户点击”给定的条件下成立。

### 考点 5：填空·____

- **题目**：填空：在「JavaScript DOM 入门」的术语速查里，「JavaScript 是单线程执行模型，调用栈执行同步代码，事件循环在栈清空后处理任务队列和微任务队列。`____`、Promise、事件回调都通过异步机制排队执行。理解调用栈、任务队列和微任务的顺序，才能解释“为什么日志顺序和」描述的是哪个术语？
- **判断依据**：在「JavaScript DOM 入门」里，setTimeout。这道题的关键在「JavaScript DOM 入门」的JavaScript DOM 入门、JavaScript、入门练习：先确认题干“填空”问的是哪一步，再排除偷换前提的选项。这道题的关键在JavaScript DOM 入门、JavaScript、入门练习：先确认题干“在JavaScript”问的是哪一步，再排除偷换前提的选项。

## English Overview

**Title:** JavaScript DOM Basics

**Summary:** Find elements, update text and handle clicks.

**Category:** JavaScript
**Level:** 入门
**Key terms:** JavaScript DOM 入门, JavaScript, 入门练习

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：基础
- 适用环境：Node.js 22+ / 现代浏览器
；本课聚焦 JavaScript DOM 入门。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：JavaScript DOM 入门、JavaScript、入门练习
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-05-17
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [MDN JavaScript 指南](https://developer.mozilla.org/docs/Web/JavaScript/Guide) | 语言基础与浏览器 API |
| [ECMAScript 标准](https://tc39.es/ecma262/) | JavaScript 语言标准 |
| [MDN Fetch API](https://developer.mozilla.org/docs/Web/API/Fetch_API) | 网络请求与响应处理 |

> 「JavaScript DOM 入门」的链接用于离线阅读后的延伸核对；App 不会自动联网。

## 复习与迁移

复习目标：把「JavaScript DOM 入门」的判断标准放回可复现的例子里。先自己作答，再对照依据；如果结论正确但理由不完整，回到正文补足前提。

### 概念复述

- 用一句话说明「JavaScript DOM 入门」解决什么问题：查找元素、修改文本并响应用户点击。
- 写出JavaScript DOM 入门、JavaScript、入门练习之间的关系，并各举一个例子。
- 说出本课最容易混淆的两个概念，以及区分它们的判据。

### 正文逐节复核

- **JavaScript 基础机制速览**：JavaScript 是单线程执行模型，调用栈执行同步代码，事件循环在栈清空后处理任务队列和微任务队列。

### 测验回顾

1. 下面这段 JavaScript 代码摘自「JavaScript DOM 入门」的正文示例。关于这段代码，下面哪一项说法与实际内容相符？
   - 依据：在「JavaScript DOM 入门」里，题干的正确项是这段代码会产生可观察的输出，运行后能看到结果，在「JavaScript DOM 入门」里要结合JavaScript DOM 入门核对输出是否符合预期。这段代码出自「JavaScript DOM 入门」的正文示例，围绕JavaScript DOM 入门、JavaScript、入门练习展开；把输入或边界换成空值、极值或失败情况后，结论要以「JavaScript DOM 入门」的实际运行结果为准。
2. 围绕“JavaScript DOM 入门”中的 JavaScript DOM 入门、JavaScript、入门练习，下列哪两项是本课强调的实践判断？
   - 依据：题干的正确项是学习 JavaScript DOM 入门 时要同时说明输入、输出和失败路径，不能只看正常流程。在「JavaScript DOM 入门」里，验证 JavaScript 时要固定版本并覆盖边界输入，结论才可复现。在「JavaScript DOM 入门」里判断这道题，要把JavaScript DOM 入门、JavaScript、入门练习的条件、过程与失败路径逐项对齐，换成“围绕JavaScript DOM 入”这个场景，只有满足前提的结论才成立。
3. 示例中 console.log(document.querySelector("button").textContent) 输出什么？
   - 依据：在「JavaScript DOM 入门」里，点击我，读取的是按钮元素的文本内容。示例先把按钮挂载到 body，再通过选择器找到它并读取 textContent，因此输出创建时设置的文本「点击我」。“console.log(document.querySele”与「JavaScript DOM 入门」的术语表相呼应，只有符合JavaScript DOM 入门、JavaScript、入门练习约束的“点击我，读取的是按钮元素的文本内容”才是正文支持的结论。
4. 要让按钮响应用户点击，应该使用哪个方法？
   - 依据：在「JavaScript DOM 入门」里，结论应落在「addEventListener("click", 处理函数)」。addEventListener 把事件类型与处理函数绑定到元素上，点击发生时浏览器调用处理函数并传入事件对象。要让按钮响应用户点击，应该使用哪个方法。「JavaScript DOM 入门」要求先交代JavaScript DOM 入门、JavaScript、入门练习的前提再下结论，所以“addEventListener("cl”只在题干“要让按钮响应用户点击”给定的条件下成立。
5. 填空：在「JavaScript DOM 入门」的术语速查里，「JavaScript 是单线程执行模型，调用栈执行同步代码，事件循环在栈清空后处理任务队列和微任务队列。`____`、Promise、事件回调都通过异步机制排队执行。理解调用栈、任务队列和微任务的顺序，才能解释“为什么日志顺序和」描述的是哪个术语？
   - 依据：在「JavaScript DOM 入门」里，setTimeout。这道题的关键在「JavaScript DOM 入门」的JavaScript DOM 入门、JavaScript、入门练习：先确认题干“填空”问的是哪一步，再排除偷换前提的选项。这道题的关键在JavaScript DOM 入门、JavaScript、入门练习：先确认题干“在JavaScript”问的是哪一步，再排除偷换前提的选项。

### 迁移练习

把「JavaScript DOM 入门」的结论迁移到相邻主题，每次迁移都写清预测与证据：

1. 换输入：用JavaScript DOM 入门处理一组你自己的数据，对比教材示例的结果差异。
2. 换失败条件：制造一个JavaScript相关的错误，说明如何从错误信息定位根因。
3. 换规模：把数据量或并发度提高一个数量级，说明「JavaScript DOM 入门」的结论是否仍成立。

<!-- language-intro-deep-dive:start -->

## 零基础通俗讲：JavaScript 操作页面

### 一句话说清它是什么

DOM 是浏览器把 HTML 解析成的一棵树，JavaScript 通过选择器找到节点、修改内容或监听事件，从而让页面动起来。

### 用生活比喻理解

把 DOM 想成一棵家族树：每个标签是一个成员，id 是身份证号。querySelector 按身份证找人，addEventListener 是给这个人装上「听到门铃就开门」的机关。

### 完整可运行代码

```html
<button id="count-button">点我加一</button>
<p id="count-text">当前计数：0</p>

<script>
  let count = 0;
  const button = document.querySelector("#count-button");
  const text = document.querySelector("#count-text");

  button.addEventListener("click", () => {
    count += 1;
    text.textContent = `当前计数：${count}`;
  });
</script>
```

### 逐行拆开看

- 页面上放了一个按钮和一个段落，各自带 id 方便定位。
- `let count = 0;` 用来保存点击次数，必须放在事件函数外面，否则每次点击都会重新归零。
- `document.querySelector("#count-button")` 按 CSS 选择器语法查找第一个匹配元素并返回。
- `addEventListener("click", ...)` 注册点击监听器，事件发生时浏览器会调用后面的函数。
- 回调里先让 count 加一，再更新段落的 textContent，文字立刻反映在页面上。
- 用 textContent 而不是 innerHTML 写入纯文本，可以避免把用户内容当成 HTML 执行。


### 把程序跑一遍

- 页面加载时执行脚本，count 初始化为 0，两个元素被找到并保存。
- 用户点一次按钮，click 事件触发，count 变成 1。
- textContent 被更新为「当前计数：1」，页面文字立刻变化。
- 再点一次，count 变成 2，如此往复。


### 新手最容易踩的坑

- 脚本写在 head 里且没有 defer：DOM 还没解析到按钮，querySelector 返回 null，调用时报错。
- id 拼写错：选择器找不到元素，报无法读取 null 的属性。
- 用 innerHTML 拼接用户输入：可能被注入脚本，存在 XSS 风险。
- 把 count 定义在回调里面：每次点击都重新初始化为 0，计数永远显示 1。
- 同一个事件重复注册监听器：一次点击触发多次处理，数字会跳着涨。


### 动手练一练

- 把按钮文字改成「增加」，确认点击后的行为不变。
- 再加一个重置按钮，把计数恢复为 0。
- 把 textContent 换成 innerHTML 并输入一段带有尖括号的文字，观察差异。


### 本课速查卡

把下面八行抄进自己的笔记，复习时只看这一页就能回忆整课：

| 复习项 | 本课要点 |
| --- | --- |
| 核心结论 | DOM 是浏览器把 HTML 解析成的一棵树，JavaScript 通过选择器找到节点、修改内容或监听事件，从而让页面动起来。 |
| 最少要写的代码 | `<button id="count-button">点我加一</button>` |
| 正确做法 | 页面加载时执行脚本，count 初始化为 0，两个元素被找到并保存。 |
| 最常见的错误 | 脚本写在 head 里且没有 defer：DOM 还没解析到按钮，querySelector 返回 null，调用时报错。 |
| 出错先查什么 | 先读第一条报错信息，再回到最小示例只改一个地方 |
| 怎么确认学会了 | 把按钮文字改成「增加」，确认点击后的行为不变。 |
| 和别的知识点的关系 | 本课打下的语法与思维方式会被后面每一课反复用到 |
| 接下来做什么 | 合上教程，凭记忆把上面的最小代码重写一遍再运行 |
