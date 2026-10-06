# PWA 与离线能力

![Service Worker 缓存策略](images/diagram_web_pwa.webp)

![PWA 与离线能力](images/category_web_pwa_offline.webp)

> 内容更新时间：2026-10-03 · 学习阶段：高级 · 预计用时：18 分钟

## 学习目标

- 能用自己的话解释「PWA 与离线能力」解决了什么问题，而不是只背术语。
- 能说清 「PWA」、「ServiceWorker」、「离线」、「缓存策略」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「HTML 与 CSS」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：Service Worker 五种缓存策略、离线队列与版本更新。

## 前置知识

- 先完成上一课《浏览器渲染与事件循环深入》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：高级。建议具备同一方向的完整基础，能阅读较长的代码、配置或系统设计说明。
- 开始前先复习：PWA、ServiceWorker、离线。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 核心组成速查

| 组成 | 作用 |
| --- | --- |
| Web App Manifest | 定义名称、图标、启动方式，支持「添加到主屏」 |
| Service Worker | 独立于页面的后台脚本，拦截请求、管理缓存 |
| Cache Storage | 存放静态资源与离线响应 |
| IndexedDB | 存放结构化业务数据 |
| Background Sync | 网络恢复后补发请求 |
| Push API | 服务端推送通知（需用户授权） |

能力边界要清楚：**Service Worker 只能拦截同源（或受控范围）请求**，且必须运行在 HTTPS（localhost 例外）。

## 缓存策略速查

| 策略 | 做法 | 适用 |
| --- | --- | --- |
| Cache First | 先读缓存，未命中再请求 | 静态资源、字体、图标 |
| Network First | 先请求网络，失败回落缓存 | 列表接口、需要新鲜度 |
| Stale While Revalidate | 立刻用缓存，同时后台更新 | 头像、配置、可容忍短暂陈旧 |
| Network Only | 不缓存 | 支付、登录等敏感接口 |
| Cache Only | 只读缓存 | 预下载的离线资源 |

```javascript
// service-worker.js：按资源类型选择策略
const SHELL_CACHE = "app-shell-v3";
const DATA_CACHE = "api-v1";
const SHELL_ASSETS = ["/", "/index.html", "/app.css", "/app.js"];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(SHELL_CACHE).then((cache) => cache.addAll(SHELL_ASSETS)),
  );
});

self.addEventListener("activate", (event) => {
  // 清理旧版本缓存，避免磁盘无限增长
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys
          .filter((key) => ![SHELL_CACHE, DATA_CACHE].includes(key))
          .map((key) => caches.delete(key)),
      ),
    ),
  );
});

self.addEventListener("fetch", (event) => {
  const { request } = event;
  const url = new URL(request.url);

  if (request.method !== "GET") return;                 // 写请求不缓存
  if (url.pathname.startsWith("/api/pay")) return;      // 敏感接口直连网络

  if (url.pathname.startsWith("/api/")) {
    // Network First：保证数据尽量新鲜，离线时回落缓存
    event.respondWith(
      fetch(request)
        .then((response) => {
          const copy = response.clone();
          caches.open(DATA_CACHE).then((cache) => cache.put(request, copy));
          return response;
        })
        .catch(() => caches.match(request)),
    );
    return;
  }

  // Cache First：静态资源优先走缓存
  event.respondWith(
    caches.match(request).then((cached) => cached || fetch(request)),
  );
});
```

```javascript
// 页面侧：注册 SW、监听更新、离线排队
if ("serviceWorker" in navigator) {
  window.addEventListener("load", async () => {
    const registration = await navigator.serviceWorker.register("/service-worker.js");
    registration.addEventListener("updatefound", () => {
      console.info("发现新版本，将在下次进入时生效");
    });
  });
}

async function submitOrder(payload) {
  try {
    const response = await fetch("/api/orders", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    return await response.json();
  } catch (error) {
    // 离线：先入队，网络恢复后重放（务必带幂等键）
    const queue = (await getQueue()) || [];
    queue.push({ payload, idempotencyKey: crypto.randomUUID() });
    await saveQueue(queue);
    if ("sync" in (await navigator.serviceWorker.ready)) {
      await (await navigator.serviceWorker.ready).sync.register("order-sync");
    }
    return { queued: true };
  }
}
```

## 离线数据与同步速查

| 主题 | 做法 |
| --- | --- |
| 本地存储选型 | 大数据用 IndexedDB，配置用 localStorage，二进制用 Cache Storage |
| 冲突解决 | 以服务端版本号为准，或按业务规则合并 |
| 幂等 | 每条离线操作带幂等键，重放不会重复 |
| 版本迁移 | 数据库带版本号，升级时写迁移逻辑 |
| 容量控制 | 定期清理过期数据，设置上限 |
| 用户提示 | 明确显示「离线中，将在联网后同步」 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 在 HTTP 下注册 SW | 注册失败 | 必须 HTTPS（localhost 例外） |
| 缓存所有请求 | 用户永远看到旧数据 | 按资源类型选择策略，接口用 Network First |
| 缓存写请求 | 数据错乱 | 只缓存 GET，写请求直连并做离线队列 |
| 不清理旧缓存 | 磁盘占用增长、旧版本残留 | activate 时删除非当前版本缓存 |
| 离线操作无幂等键 | 重放产生重复订单 | 每次操作生成幂等键 |
| 更新 SW 后不提示 | 用户不知道要刷新 | 监听 updatefound 并提示 |
| 忽略缓存失效 | 发版后仍加载旧 JS | 文件名带哈希或改缓存名 |

## 自测清单

- [ ] 能用 Manifest 与 Service Worker 让应用可安装、可离线。
- [ ] 按资源类型选择五种缓存策略之一。
- [ ] 离线写操作入队并带幂等键，联网后重放。
- [ ] activate 阶段清理旧版本缓存。
- [ ] 版本更新有提示机制且能强制刷新。

## 动手练习


> 本课练习重点：围绕「PWA、ServiceWorker、离线」完成复述、实验和交付，每个结果都要能被别人检查。

先写最小语义结构，再调整布局与样式，最后检查键盘、窄屏和对比度。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「PWA 与离线能力」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「ServiceWorker」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

做一个只有标题、卡片和按钮的最小页面，并用浏览器设备模式检查窄屏。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「PWA」和「ServiceWorker」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 本课小结

- 核心问题：「PWA 与离线能力」不是孤立术语，而是在「HTML 与 CSS」中解决一类具体问题。
- 关键关系：先分清「PWA」与「ServiceWorker」的职责，再理解「离线」的适用边界。
- 判断标准：能解释正常场景、边界条件和失败场景，才算真正掌握。
- 下一步：完成练习后，用自己的话写下 3 条要点，再去做本课测验。



## 可运行练习

下面 3 个任务围绕“PWA 与离线能力”展开，代码可以直接粘贴到 App 的离线沙箱里运行；如果示例会读取标准输入，请按代码注释在沙箱的 stdin 区域填入同样格式的数据。

### 任务 1：先跑通，再解释

```javascript
// service-worker.js：按资源类型选择策略
const SHELL_CACHE = "app-shell-v3";
const DATA_CACHE = "api-v1";
const SHELL_ASSETS = ["/", "/index.html", "/app.css", "/app.js"];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(SHELL_CACHE).then((cache) => cache.addAll(SHELL_ASSETS)),
  );
});

self.addEventListener("activate", (event) => {
  // 清理旧版本缓存，避免磁盘无限增长
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys
          .filter((key) => ![SHELL_CACHE, DATA_CACHE].includes(key))
          .map((key) => caches.delete(key)),
      ),
    ),
  );
});

self.addEventListener("fetch", (event) => {
  const { request } = event;
  const url = new URL(request.url);

  if (request.method !== "GET") return;                 // 写请求不缓存
  if (url.pathname.startsWith("/api/pay")) return;      // 敏感接口直连网络

  if (url.pathname.startsWith("/api/")) {
    // Network First：保证数据尽量新鲜，离线时回落缓存
    event.respondWith(
      fetch(request)
        .then((response) => {
          const copy = response.clone();
          caches.open(DATA_CACHE).then((cache) => cache.put(request, copy));
          return response;
        })
        .catch(() => caches.match(request)),
    );
    return;
  }

  // Cache First：静态资源优先走缓存
  event.respondWith(
    caches.match(request).then((cached) => cached || fetch(request)),
  );
});
```

**预期输出**：运行后会输出与“PWA 与离线能力”相关的关键结果；请重点核对输出行数、最后一个数值和异常提示。

**验收标准**：代码能正常运行；逐行解释每个变量的值如何变化，并指出哪一行决定了最终结果。

### 任务 2：只改一个条件

复制上面的代码，只修改一个输入、边界或参数（例如空值、最大值、循环次数、过滤条件），先写出你的预测，再实际运行。

**验收标准**：留下“原结果 → 改动 → 预测 → 实际结果 → 差异原因”五步记录；如果预测错误，要写出修正后的心智模型。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的数据或场景，保持输出格式与任务 1 一致。

**验收标准**：代码不少于 10 行，至少包含 1 个边界检查；把代码和运行结果保存到笔记或片段库。


## 故障现场

这一节把“PWA 与离线能力”最常见的失败方式还原成现场记录，练习时按“症状 → 复现 → 定位 → 修复 → 预防”的顺序排查。

### 现场 1：“PWA 与离线能力”的 PWA 常规用例通过，但边界用例失败

**症状**：在“PWA 与离线能力”的练习或生产场景里出现““PWA 与离线能力”的 PWA 常规用例通过，但边界用例失败”。

**复现**：准备一组最小输入，只保留触发““PWA 与离线能力”的 PWA 常规用例通过，但边界用例失败”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“PWA 的前置条件与取值边界没有写进代码，默认值掩盖了空值和极值”检查调用链、输入数据和环境配置，先验证假设再改代码。

**修复**：为“PWA 与离线能力”补一条空值或极值用例，把前置条件写成断言，并让失败信息直接指出是哪个输入越界

**预防**：把““PWA 与离线能力”的 PWA 常规用例通过，但边界用例失败”写成一条自动化用例，并在“PWA 与离线能力”的验收清单里保留对应检查项。


### 现场 2：“PWA 与离线能力”的 ServiceWorker 结果在两次运行之间不一致

**症状**：在“PWA 与离线能力”的练习或生产场景里出现““PWA 与离线能力”的 ServiceWorker 结果在两次运行之间不一致”。

**复现**：准备一组最小输入，只保留触发““PWA 与离线能力”的 ServiceWorker 结果在两次运行之间不一致”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“ServiceWorker 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。

**修复**：固定“PWA 与离线能力”使用的版本与随机种子，记录两次运行的完整输入和输出，再逐项消除非确定性来源

**预防**：把““PWA 与离线能力”的 ServiceWorker 结果在两次运行之间不一致”写成一条自动化用例，并在“PWA 与离线能力”的验收清单里保留对应检查项。


### 现场 3：“PWA 与离线能力”的验证只在开发机通过

**症状**：在“PWA 与离线能力”的练习或生产场景里出现““PWA 与离线能力”的验证只在开发机通过”。

**复现**：准备一组最小输入，只保留触发““PWA 与离线能力”的验证只在开发机通过”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“环境版本、配置和输入规模与目标环境不同，PWA 缺少可重复的验证记录”检查调用链、输入数据和环境配置，先验证假设再改代码。

**修复**：把“PWA 与离线能力”的运行环境、输入样本和预期输出写成清单，并在另一套环境复跑同一条命令

**预防**：把““PWA 与离线能力”的验证只在开发机通过”写成一条自动化用例，并在“PWA 与离线能力”的验收清单里保留对应检查项。


## 考点精讲：把测验题还原成判断过程

本课有 6 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：Service Worker 注册的前置条件是？

- **正确判断**：必须使用 HTTPS（localhost 例外）
- **判断依据**：正确答案是「必须使用 HTTPS（localhost 例外）」，本课在「核心组成速查」中说明：能力边界要清楚：Service Worker 只能拦截同源（或受控范围）请求，且必须运行在 HTTPS（localhost 例外）。Service Worker 能拦截请求，属于高权限能力，因此要求安全上下文。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 2：静态资源（JS、CSS、字体）适合哪种缓存策略？

- **正确判断**：Cache First
- **判断依据**：正确答案是「Cache First」，这道题在问静态资源（JS、CSS、字体）适合哪种缓存策略，判断时要把题干限定的输入、边界与目标逐项对齐。带哈希指纹的静态资源内容不变，缓存优先能显著提升加载速度并支持离线。本课示例中还能看到 `// Cache First：静态资源优先走缓存` 这样的用法，说明该关键字在本课代码中承担实际功能。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 3：离线状态下用户提交了一个订单，正确做法是？

- **正确判断**：存入本地队列并带幂等键，联网后重放
- **判断依据**：正确答案是「存入本地队列并带幂等键，联网后重放」，这道题在问离线状态下用户提交了一个订单，正确做法是，判断时要把题干限定的输入、边界与目标逐项对齐。离线写操作要入队（通常用 IndexedDB），并带幂等键保证重放不会重复下单。课程摘要指出Service Worker 五种缓存策略，离线队列与版本更新，本课要判断的正是离线状态下用户提交了一个订单，正确做法是。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 4：为什么要在 activate 阶段清理旧缓存？

- **正确判断**：避免磁盘占用增长和旧版本资源残留导致的行为异常
- **判断依据**：正确答案是「避免磁盘占用增长和旧版本资源残留导致的行为异常」，这道题在问为什么要在activate阶段清理旧缓存，判断时要把题干限定的输入、边界与目标逐项对齐。每次发版都会产生新缓存，不清理就会累积并可能取到旧资源。课程摘要指出Service Worker 五种缓存策略，离线队列与版本更新，本课要判断的正是为什么要在activate阶段清理旧缓存。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 5：发版后用户仍加载旧版 JS，最可能的原因是？

- **正确判断**：Service Worker 缓存策略没有随版本更新
- **判断依据**：正确答案是「Service Worker 缓存策略没有随版本更新」，这道题在问发版后用户仍加载旧版JS，最可能的原因是，判断时要把题干限定的输入、边界与目标逐项对齐。缓存名或资源指纹未变时，SW 会继续返回旧资源，因此要用内容哈希或新的缓存版本号，并提供更新提示。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 6：补全代码：「PWA 与离线能力」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `const registration = await navigator.____.register("/service-worker.js");`

- **正确判断**：serviceWorker / serviceworker
- **判断依据**：正确答案是「serviceWorker」，这道题在问补全代码：PWA与离线能力示例中，下面这行代码缺少哪…ervice-worker.js");`，判断时要把题干限定的输入、边界与目标逐项对齐。本课示例中还能看到 `if ("serviceWorker" in navigator) {` 这样的用法，说明该关键字在本课代码中承担实际功能。
- **迁移检查**：不看题干，用自己的话补全这句话，再与标准答案对照。

### 补充自测（2 题）

1. 围绕“PWA 与离线能力”中的 PWA、ServiceWorker、离线，下列哪两项是本课强调的实践判断？
2. 下面这段 JavaScript 代码复现了“PWA 与离线能力”中 PWA、ServiceWorker、离线 相关的一个常见故障，哪一项最准确地解释了问题？

这些题按“先定位概念、再排除边界错误、最后核对答案”的顺序作答；每题解析都给出了判断依据。


## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「Service Worker 注册的前置条件是？」的判断依据。
- [ ] 不看解析，能说出「静态资源（JS、CSS、字体）适合哪种缓存策略？」的判断依据。
- [ ] 不看解析，能说出「离线状态下用户提交了一个订单，正确做法是？」的判断依据。
- [ ] 不看解析，能说出「为什么要在 activate 阶段清理旧缓存？」的判断依据。
- [ ] 不看解析，能说出「发版后用户仍加载旧版 JS，最可能的原因是？」的判断依据。
- [ ] 不看解析，能说出「补全代码：「PWA 与离线能力」示例中，下面这行代码缺少哪个关键字或函数名？请填…」的判断依据。
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
| `// Cache First：静态资源优先走缓存` | 判断依据**：正确答案是「Cache First」，这道题在问静态资源（JS、CSS、字体）适合哪种缓存策略，判断时要把题干限定的输入、边界与目标逐项对齐。带哈希指纹的静态资源内容不变，缓存优先能显著提升加载速度并支持离… |
| `，判断时要把题干限定的输入、边界与目标逐项对齐。本课示例中还能看到` | 判断依据**：正确答案是「serviceWorker」，这道题在问补全代码：PWA与离线能力示例中，下面这行代码缺少哪…ervice-worker.js");`，判断时要把题干限定的输入、边界与目标逐项对齐。本课示例中还… |
| `PWA` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |
| `ServiceWorker` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |
| `离线` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |
| `缓存策略` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |
| `IndexedDB` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |
| `BackgroundSync` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |

## 面试问答与自测

下面把本课考点换成面试追问。先口述自己的答案，
再对照参考回答检查是否遗漏了前提、边界或失败路径。

### 追问 1：Service Worker 注册的前置条件是？

**参考回答**：正确答案是「必须使用 HTTPS（localhost 例外）」，本课在「核心组成速查」中说明：能力边界要清楚：Service Worker 只能拦截同源（或受控范围）请求，且必须运行在 HTTPS（localhost 例外）。Service Worker 能拦截请求，属于高权限能力，因此要求安全上下文。

### 追问 2：静态资源（JS、CSS、字体）适合哪种缓存策略？

**参考回答**：正确答案是「Cache First」，这道题在问静态资源（JS、CSS、字体）适合哪种缓存策略，判断时要把题干限定的输入、边界与目标逐项对齐。带哈希指纹的静态资源内容不变，缓存优先能显著提升加载速度并支持离线。本课示例中还能看到 `// Cache First：静态资源优先走缓存` 这样的用法，说明该关键字在本课代码中承担实际功能。

### 追问 3：离线状态下用户提交了一个订单，正确做法是？

**参考回答**：正确答案是「存入本地队列并带幂等键，联网后重放」，这道题在问离线状态下用户提交了一个订单，正确做法是，判断时要把题干限定的输入、边界与目标逐项对齐。离线写操作要入队（通常用 IndexedDB），并带幂等键保证重放不会重复下单。课程摘要指出Service Worker 五种缓存策略，离线队列与版本更新，本课要判断的正是离线状态下用户提交了一个订单，正确做法是。

### 追问 4：为什么要在 activate 阶段清理旧缓存？

**参考回答**：正确答案是「避免磁盘占用增长和旧版本资源残留导致的行为异常」，这道题在问为什么要在activate阶段清理旧缓存，判断时要把题干限定的输入、边界与目标逐项对齐。每次发版都会产生新缓存，不清理就会累积并可能取到旧资源。课程摘要指出Service Worker 五种缓存策略，离线队列与版本更新，本课要判断的正是为什么要在activate阶段清理旧缓存。

### 追问 5：发版后用户仍加载旧版 JS，最可能的原因是？

**参考回答**：正确答案是「Service Worker 缓存策略没有随版本更新」，这道题在问发版后用户仍加载旧版JS，最可能的原因是，判断时要把题干限定的输入、边界与目标逐项对齐。缓存名或资源指纹未变时，SW 会继续返回旧资源，因此要用内容哈希或新的缓存版本号，并提供更新提示。

## English Overview

**Title:** PWA & Offline

**Summary:** Service worker caching strategies, offline queue and updates.

**Category:** HTML & CSS  
**Level:** 高级  
**Key terms:** PWA, ServiceWorker, 离线, 缓存策略, IndexedDB, BackgroundSync

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：高级
- 适用环境：现代浏览器（Chrome/Firefox/Safari）
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：PWA、ServiceWorker、离线、缓存策略、IndexedDB、BackgroundSync
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [MDN Web Docs](https://developer.mozilla.org/docs/Web) | HTML、CSS 与浏览器行为 |
| [W3C Standards](https://www.w3.org/TR/) | Web 标准与可访问性规范 |

> 本课主题：Service Worker 五种缓存策略、离线队列与版本更新。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。
