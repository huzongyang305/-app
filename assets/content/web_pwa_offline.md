# PWA 与离线能力

![Service Worker 缓存策略](images/diagram_web_pwa.webp)

![PWA 与离线能力](images/category_web_pwa_offline.webp)

> 内容更新时间：2026-10-06 · 学习阶段：高级 · 预计用时：18 分钟

## 学习目标

- 能用自己的话解释PWA 与离线能力解决了什么问题，而不是只背术语。
- 能说清 「PWA」、「ServiceWorker」、「离线」、「缓存策略」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「HTML 与 CSS」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：Service Worker 五种缓存策略、离线队列与版本更新。

## 前置知识

- 先完成上一课《浏览器渲染与事件循环深入》；如果已经掌握，可以直接用本课练习自测。
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

1. PWA 与离线能力解决了什么问题？
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

- 核心问题：PWA 与离线能力不是孤立术语，而是在「HTML 与 CSS」中解决一类具体问题。
- 关键关系：先分清「PWA」与「ServiceWorker」的职责，再理解「离线」的适用边界。
- 判断标准：能解释正常场景、边界条件和失败场景，才算真正掌握。
- 下一步：完成练习后，用自己的话写下 3 条要点，再去做本课测验。

## 可运行练习

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

### 任务 2：只改一个条件

把「PWA 与离线能力」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：只把PWA的输入换成空值、极值或错误输入，其余保持不变。
- 预测：先写下「PWA 与离线能力」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响PWA。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的数据或场景，保持输出格式与任务 1 一致。

## 故障现场

### 现场 1：本课的 PWA 常规用例通过，但边界用例失败

**症状**：在本课的练习或生产场景里出现“本课的 PWA 常规用例通过，但边界用例失败”。

**复现**：准备一组最小输入，只保留触发“本课的 PWA 常规用例通过，但边界用例失败”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“PWA 的前置条件与取值边界没有写进代码，默认值掩盖了空值和极值”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 PWA 常规用例通过，但边界用例失败”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 2：本课的 ServiceWorker 结果在两次运行之间不一致

**症状**：在本课的练习或生产场景里出现“本课的 ServiceWorker 结果在两次运行之间不一致”。

**复现**：准备一组最小输入，只保留触发“本课的 ServiceWorker 结果在两次运行之间不一致”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“ServiceWorker 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 ServiceWorker 结果在两次运行之间不一致”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 3：本课的验证只在开发机通过

**症状**：在本课的练习或生产场景里出现“本课的验证只在开发机通过”。

**定位**：围绕“环境版本、配置和输入规模与目标环境不同，PWA 缺少可重复的验证记录”检查调用链、输入数据和环境配置，先验证假设再改代码。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「Service Worker 注册的前置条件是？」的判断依据。
- [ ] 不看解析，能说出「静态资源（JS、CSS、字体）适合哪种缓存策略？」的判断依据。
- [ ] 不看解析，能说出「离线状态下用户提交了一个订单，正确做法是？」的判断依据。
- [ ] 不看解析，能说出「为什么要在 activate 阶段清理旧缓存？」的判断依据。
- [ ] 不看解析，能说出「发版后用户仍加载旧版 JS，最可能的原因是？」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

把「PWA 与离线能力」里反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 本课语境 |
| --- | --- |
| `PWA` | 围绕“环境版本、配置和输入规模与目标环境不同，PWA 缺少可重复的验证记录”检查调用链、输入数据和环境配置，先验证假设再改代码。 |
| `ServiceWorker` | 围绕“ServiceWorker 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。 |
| `离线` | 关键关系：先分清「PWA」与「ServiceWorker」的职责，再理解「离线」的适用边界。 |
| `缓存策略` | 它在「PWA 与离线能力」里是理解「缓存策略」的关键术语，用来解释定义、适用条件与失败路径；它与PWA、离线共同决定这一节的判断边界。复习时回到正文示例核对输入、输出和验证方式。 |
| `IndexedDB` | 它在「PWA 与离线能力」里是理解「IndexedDB」的关键术语，用来解释定义、适用条件与失败路径；它与PWA、离线共同决定这一节的判断边界。复习时回到正文示例核对输入、输出和验证方式。 |
| `BackgroundSync` | 它在「PWA 与离线能力」里是理解「BackgroundSync」的关键术语，用来解释定义、适用条件与失败路径；它与PWA、离线共同决定这一节的判断边界。复习时回到正文示例核对输入、输出和验证方式。 |

## 考点精讲

### 考点 1：概念判断·PWA

- **题目**：Service Worker 注册的前置条件是？
- **判断依据**：在「PWA 与离线能力」里，必须使用 HTTPS（localhost 例外）。Service Worker 能拦截请求，属于高权限能力，因此要求安全上下文。回到「PWA 与离线能力」的正文示例，用“Service Worker 注册的”走一遍PWA、ServiceWorker、离线的完整流程，能复现的结论才可以保留。

### 考点 2：代码补全·PWA

- **题目**：阅读「PWA 与离线能力」正文里的这段 JavaScript 代码，下面哪一项判断是正确的？
- **判断依据**：在「PWA 与离线能力」里，题干的正确项是这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行，在「PWA 与离线能力」里封装边界决定PWA从哪一步开始生效。把输入或边界换成空值、极值或失败情况后，结论要以「PWA 与离线能力」的实际运行结果为准。「PWA 与离线能力」要求先交代PWA、ServiceWorker、离线的前提再下结论，所以“这段代码把主要逻辑封装在函数或方法里”只在题干“阅读PWA 与离线能力正文里的这段 JavaScript 代”给定的条件下成立。

### 考点 3：概念判断·PWA

- **题目**：离线状态下用户提交了一个订单，正确做法是？
- **判断依据**：在「PWA 与离线能力」里，存入本地队列并带幂等键，联网后重放。离线写操作要入队（通常用 IndexedDB），并带幂等键保证重放不会重复下单。在「PWA 与离线能力」里判断这道题，要把PWA、ServiceWorker、离线的条件、过程与失败路径逐项对齐，换成“离线状态下用户提交了一个订单”这个场景，只有满足前提的结论才成立。

### 考点 4：多选辨析·PWA

- **题目**：围绕“PWA 与离线能力”中的 PWA、ServiceWorker、离线，下列哪两项是本课强调的实践判断？
- **判断依据**：结论应落在验证 ServiceWorker 时要固定版本并覆盖边界输入。本课把PWA 与离线能力拆成概念、示例与故障现场三部分，因此判断 PWA 时必须同时交代输入、输出和失败路径，这使“学习 PWA 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在PWA 与离线能力里，判断 ServiceWorker 时要固定版本与边界输入，所以“验证 ServiceWorker 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 5：概念判断·PWA

- **题目**：发版后用户仍加载旧版 JS，最可能的原因是？
- **判断依据**：在「PWA 与离线能力」里，Service Worker 缓存策略没有随版本更新。缓存名或资源指纹未变时，SW 会继续返回旧资源，因此要用内容哈希或新的缓存版本号，并提供更新提示。把“Service Worker 缓存策略没”代回「PWA 与离线能力」里“发版后用户仍加载旧版 JS”的例子核对，条件一旦改变，结论就要用PWA、ServiceWorker、离线重新推导。

### 考点 6：填空·PWA

- **题目**：补全代码：「PWA 与离线能力」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `const registration = await navigator.____.register("/service-worker.js");`
- **判断依据**：把“serviceWorker”代回「PWA 与离线能力」里“PWA 与离线能力示例中”的例子核对，条件一旦改变，结论就要用PWA、ServiceWorker、离线重新推导。「PWA 与离线能力」要求先交代PWA、ServiceWorker、离线的前提再下结论，所以“serviceWorker”只在题干“与离线能力示例中”给定的条件下成立。

## English Overview

**Title:** PWA & Offline

**Summary:** Service worker caching strategies, offline queue and updates.

**Category:** HTML & CSS
**Level:** 高级
**Key terms:** PWA, ServiceWorker, 离线, 缓存策略, IndexedDB, BackgroundSync

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：高级
- 适用环境：现代浏览器（Chrome/Firefox/Safari）
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：PWA、ServiceWorker、离线、缓存策略、IndexedDB、BackgroundSync
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [MDN HTTP](https://developer.mozilla.org/docs/Web/HTTP) | HTTP 语义与缓存 |
| [W3C Web 标准](https://www.w3.org/TR/) | HTML、CSS 与 Web 标准 |
| [MDN JavaScript](https://developer.mozilla.org/docs/Web/JavaScript) | 浏览器脚本语言 |

> 「PWA 与离线能力」的链接用于离线阅读后的延伸核对；App 不会自动联网。
