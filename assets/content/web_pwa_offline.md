# PWA 与离线能力

![Service Worker 缓存策略](images/diagram_web_pwa.webp)

![PWA 与离线能力](images/category_web_pwa_offline.webp)

> 内容更新时间：2026-10-06 · 学习阶段：高级 · 预计用时：50 分钟

## 本节知识框架

**课程定位**：所属分类为「HTML 与 CSS」，课程主题为「PWA 与离线能力」，学习阶段为「高级」，建议用时 50 分钟。

**本课要解决的主问题**：Service Worker 五种缓存策略、离线队列与版本更新。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「PWA 与离线能力」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「PWA 与离线能力」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「PWA」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《浏览器渲染与事件循环深入》

**学习位置**：本课位于《浏览器渲染与事件循环深入》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《Web Components 实战》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释PWA 与离线能力解决了什么问题，而不是只背术语。
- 能说清 「PWA」、「ServiceWorker」、「离线」、「缓存策略」 之间的关系，并分别举出一个例子。
- 能把 PWA 放回「PWA 与离线能力」的知识体系，说明它和 ServiceWorker 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：Service Worker 五种缓存策略、离线队列与版本更新。

**教材衔接：前置知识**

- 先完成上一课《浏览器渲染与事件循环深入》；如果已经掌握，可以直接用本课练习自测。
- 开始前先复习：PWA、ServiceWorker、离线。
- 卡在 PWA 上时不要跳过：把输入、预期和实际输出写成三行，再回头读正文。

**教材衔接：本课小结**

- 核心问题：PWA 与离线能力不是孤立术语，而是在「HTML 与 CSS」中解决一类具体问题。
- 关键关系：先分清「PWA」与「ServiceWorker」的职责，再理解「离线」的适用边界。
- 判断标准：能举出 ServiceWorker 的一个反例并解释原因。
- 下一步：把 SHELL_ASSETS 的实验结论记成三句话，然后进入测验。

## 核心概念定义

> 阅读约定：本课先给「PWA 与离线能力」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| PWA | 用 Service Worker、清单和缓存增强网页，使其具备安装与离线能力。 | 仅在「PWA 与离线能力」明确给出的输入、版本与资源条件下成立。 |
| ServiceWorker | 浏览器在页面之外运行的后台脚本，用于缓存、离线与推送。 | 仅在「PWA 与离线能力」明确给出的输入、版本与资源条件下成立。 |
| 离线 | 关键关系：先分清「PWA」与「ServiceWorker」的职责，再理解「离线」的适用边界。 | 仅在「PWA 与离线能力」明确给出的输入、版本与资源条件下成立。 |
| 缓存策略 | 规定写入、过期、淘汰和失效方式，在命中率与一致性之间取舍。 | 仅在「PWA 与离线能力」明确给出的输入、版本与资源条件下成立。 |
| IndexedDB | 浏览器内置的异步事务型对象数据库，适合保存大量离线结构化数据。 | 仅在「PWA 与离线能力」明确给出的输入、版本与资源条件下成立。 |
| BackgroundSync | 浏览器在恢复网络后由 Service Worker 重试后台同步任务。 | 仅在「PWA 与离线能力」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「PWA 与离线能力」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「PWA」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「ServiceWorker」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「离线」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「PWA 与离线能力」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | PWA | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | ServiceWorker | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | 离线 | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「PWA 与离线能力」自己的示例验证。「PWA 与离线能力」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：核心组成速查**

| 组成 | 作用 |
| --- | --- |
| Web App Manifest | 定义名称、图标、启动方式，支持「添加到主屏」 |
| Service Worker | 独立于页面的后台脚本，拦截请求、管理缓存 |
| Cache Storage | 存放静态资源与离线响应 |
| IndexedDB | 存放结构化业务数据 |
| Background Sync | 网络恢复后补发请求 |
| Push API | 服务端推送通知（需用户授权） |

能力边界要清楚：**Service Worker 只能拦截同源（或受控范围）请求**，且必须运行在 HTTPS（localhost 例外）。

**教材衔接：离线数据与同步速查**

| 主题 | 做法 |
| --- | --- |
| 本地存储选型 | 大数据用 IndexedDB，配置用 localStorage，二进制用 Cache Storage |
| 冲突解决 | 以服务端版本号为准，或按业务规则合并 |
| 幂等 | 每条离线操作带幂等键，重放不会重复 |
| 版本迁移 | 数据库带版本号，升级时写迁移逻辑 |
| 容量控制 | 定期清理过期数据，设置上限 |
| 用户提示 | 明确显示「离线中，将在联网后同步」 |

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 PWA、ServiceWorker | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「PWA 与离线能力」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「PWA 与离线能力」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《PWA 与离线能力》原文中的最小示例。先预测《PWA 与离线能力》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

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

**教材衔接：深挖「PWA」的边界与代价**

这一章只用「PWA 与离线能力」自己的正文、代码和测验题，把PWA推到边界再看一遍：先确认它在什么条件下成立，再估计代价，最后给出可复现的证据。

### 一、PWA 的关键句与适用条件

| 正文出处 | 原句 | 用之前先确认 |
| --- | --- | --- |
| 现场 1：缓存所有请求 | 根因：“用户永远看到旧数据”只是表层结果。向上追溯会落到“缓存所有请求”这一步，因为它省略了《PWA 与离线能力》的约束，使实现行为和预期模型发生了偏离。 | 把 PWA 换成边界值时，这一步是否仍然成立 |
| 现场 1：缓存所有请求 | 验证：先在《PWA 与离线能力》中记录“缓存所有请求”留下的失败证据，再执行“按资源类型选择策略，接口用 Network First”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。 | 把 PWA 换成边界值时，这一步是否仍然成立 |
| 现场 2：不清理旧缓存 | 根因：“磁盘占用增长、旧版本残留”只是表层结果。向上追溯会落到“不清理旧缓存”这一步，因为它省略了《PWA 与离线能力》的约束，使实现行为和预期模型发生了偏离。 | 把 PWA 换成边界值时，这一步是否仍然成立 |
| 现场 3：离线操作无幂等键 | 根因：当出现“离线操作无幂等键”时，执行路径已经绕过了《PWA 与离线能力》的关键约束，最终以“重放产生重复订单”暴露出来；修复前必须先确认约束在哪里失效。 | 把 PWA 换成边界值时，这一步是否仍然成立 |
| 现场 3：离线操作无幂等键 | 修复：针对《PWA 与离线能力》的问题，每次操作生成幂等键 | 把 离线 换成边界值时，这一步是否仍然成立 |

读这张表时不要只记结论：每一句都要问「把PWA换成边界值还成立吗」。如果第二列的原句里已经写明前提，第三列就写成「前提不变」；如果原句省略了前提，第三列必须补出来。

### 二、把 SHELL_CACHE 推到边界

下面是本课第一段代码（javascript），先原样运行一次作为基线：

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
// …（其余部分见正文，此处为截断片段）
```

| 变式 | 怎么改 | 先写下什么 | 观察点 |
| --- | --- | --- | --- |
| 边界输入 | 把 SHELL_CACHE 的输入换成空值或最大值 | 预测输出 | 是否报错、是否静默返回 |
| 只改一处 | 把 DATA_CACHE 的一个参数改成另一档 | 预测差异来源 | 输出变化能否用本课结论解释 |
| 去掉一步 | 注释掉 SHELL_CACHE 之后的一行 | 预测哪一步先失败 | 错误位置是否与预期一致 |

三次实验都要保留「原例 → 改动 → 预测 → 结果 → 原因」五步记录；其中「原因」必须引用「PWA 与离线能力」正文里的结论，而不是只写「正常」或「报错」。

### 三、「PWA」的代价怎么量

| 观察项 | 怎么测 | 结论怎么写 |
| --- | --- | --- |
| 时间 | 把 PWA 的输入规模翻倍，记录耗时变化 | 写出增长是线性、对数还是常数，并给出实测数据 |
| 空间 | 记录 ServiceWorker 占用的内存或存储峰值 | 说明峰值出现在哪一步，以及能否提前释放 |
| 可读性 | 统计完成同一件事需要多少行代码或多少步操作 | 用具体行数代替「更简洁」这类主观描述 |
| 失败代价 | 触发一次失败，记录恢复所需步骤 | 写清失败后是否有残留状态、如何回滚 |

如果在「PWA 与离线能力」里量不出上表的任何一项，说明实验还停留在阅读层面：先把输入规模翻倍，再回来填表。

### 四、测验复盘

| 题号 | 正确答案 | 最容易选错的干扰项 | 复盘动作 |
| --- | --- | --- | --- |
| 1 | 必须使用 HTTPS（localhost 例外） | 必须使用 HTTP | 把干扰项改写成一句反例，再说明它违反本课哪条前提 |
| 2 | 这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。 | 这段代码只做静态声明，没有循环、分支或可观察输出。 | 把干扰项改写成一句反例，再说明它违反本课哪条前提 |
| 3 | 存入本地队列并带幂等键，联网后重放 | 直接丢弃请求 | 把干扰项改写成一句反例，再说明它违反本课哪条前提 |
| 4 | 验证 ServiceWorker 时要固定版本并覆盖边界输入，结论才… | 只要 PWA 的常规示例通过，就可以跳过边界与异常路径 | 把干扰项改写成一句反例，再说明它违反本课哪条前提 |
| 5 | Service Worker 缓存策略没有随版本更新 | 用户网络太慢 | 把干扰项改写成一句反例，再说明它违反本课哪条前提 |
| 6 | 0 | （无干扰项） | 把干扰项改写成一句反例，再说明它违反本课哪条前提 |

复盘「PWA 与离线能力」时只写「我记住了」没有意义：每个错误选项都要能对应到本课的一条前提，写完后再回到第一节的关键句表核对一次。

### 五、离开本课前的自检

- [ ] 能用一句话说明 PWA 解决什么问题、在什么条件下失效。
- [ ] 能指出 ServiceWorker 与相邻概念的分工，并各举一个反例。
- [ ] 能在不看解析的情况下重做本课测验，并解释PWA 与离线能力中每个错误选项。
- [ ] 能按第二节的表格完成至少两次 PWA 实验，并留下命令与输出。
- [ ] 能写出「PWA 与离线能力」的三条结论，每条都配一个适用边界。

全部勾选后，再去做「PWA 与离线能力」的测验与练习；只要有一项答不上来，就回到对应小节补一次实验，而不是先背结论。
<!-- p1-deep-dive:end -->

## 时间/空间复杂度或性能分析

**复杂度证据**：「PWA 与离线能力」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「PWA 与离线能力」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「PWA 与离线能力」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

**教材衔接：缓存策略速查**

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

## 常见误区与易错点

> 复核《PWA 与离线能力》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「PWA 与离线能力」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 在 HTTP 下注册 SW | 注册失败 | 必须 HTTPS（localhost 例外） |
| 缓存所有请求 | 用户永远看到旧数据 | 按资源类型选择策略，接口用 Network First |
| 缓存写请求 | 数据错乱 | 只缓存 GET，写请求直连并做离线队列 |
| 不清理旧缓存 | 磁盘占用增长、旧版本残留 | activate 时删除非当前版本缓存 |
| 离线操作无幂等键 | 重放产生重复订单 | 每次操作生成幂等键 |
| 更新 SW 后不提示 | 用户不知道要刷新 | 监听 updatefound 并提示 |
| 忽略缓存失效 | 发版后仍加载旧 JS | 文件名带哈希或改缓存名 |

**教材衔接：故障现场**

### 现场 1：缓存所有请求

**症状**：在《PWA 与离线能力》的复现场景中，用户永远看到旧数据。

**根因**：“用户永远看到旧数据”只是表层结果。向上追溯会落到“缓存所有请求”这一步，因为它省略了《PWA 与离线能力》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《PWA 与离线能力》的问题，按资源类型选择策略，接口用 Network First。

**验证**：先在《PWA 与离线能力》中记录“缓存所有请求”留下的失败证据，再执行“按资源类型选择策略，接口用 Network First”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 2：不清理旧缓存

**症状**：在《PWA 与离线能力》的复现场景中，磁盘占用增长、旧版本残留。

**根因**：“磁盘占用增长、旧版本残留”只是表层结果。向上追溯会落到“不清理旧缓存”这一步，因为它省略了《PWA 与离线能力》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《PWA 与离线能力》的问题，activate 时删除非当前版本缓存。

**验证**：保留《PWA 与离线能力》里触发“磁盘占用增长、旧版本残留”的输入、版本和日志，按“activate 时删除非当前版本缓存”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 3：离线操作无幂等键

**症状**：在《PWA 与离线能力》的复现场景中，重放产生重复订单。

**根因**：当出现“离线操作无幂等键”时，执行路径已经绕过了《PWA 与离线能力》的关键约束，最终以“重放产生重复订单”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《PWA 与离线能力》的问题，每次操作生成幂等键。

**验证**：保留《PWA 与离线能力》里触发“重放产生重复订单”的输入、版本和日志，按“每次操作生成幂等键”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《浏览器渲染与事件循环深入》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《Web Components 实战》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《浏览器渲染与事件循环深入》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《Web Components 实战》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「PWA 与离线能力」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《PWA 与离线能力》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

Service Worker 注册的前置条件是？

A. 必须有后端服务器推送证书，实际效果取决于具体实现
B. 必须使用 HTTPS（localhost 例外）
C. 必须使用 HTTP
D. 必须打包成原生应用

**参考答案**：必须使用 HTTPS（localhost 例外）

**解析**：在「PWA 与离线能力」里，必须使用 HTTPS（localhost 例外）。Service Worker 能拦截请求，属于高权限能力，因此要求安全上下文。回到「PWA 与离线能力」的正文示例，用“Service Worker 注册的”走一遍PWA、ServiceWorker、离线的完整流程，能复现的结论才可以保留。

### 自测 2

阅读「PWA 与离线能力」正文里的这段 JavaScript 代码，下面哪一项判断是正确的？

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

A. 这段代码只做静态声明，没有循环、分支或可观察输出。
B. 这段代码包含循环结构，同一段逻辑会被重复执行。
C. 这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。
D. 这段代码会产生可观察的输出，运行后能看到结果。

**参考答案**：这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。

**解析**：在「PWA 与离线能力」里，题干的正确项是这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行，在「PWA 与离线能力」里封装边界决定PWA从哪一步开始生效。把输入或边界换成空值、极值或失败情况后，结论要以「PWA 与离线能力」的实际运行结果为准。「PWA 与离线能力」要求先交代PWA、ServiceWorker、离线的前提再下结论，所以“这段代码把主要逻辑封装在函数或方法里”只在题干“阅读PWA 与离线能力正文里的这段 JavaScript 代”给定的条件下成立。

### 自测 3

围绕“PWA 与离线能力”中的 PWA、ServiceWorker、离线，下列哪两项是本课强调的实践判断？

A. 只要 PWA 的常规示例通过，就可以跳过边界与异常路径
B. 验证 ServiceWorker 时要固定版本并覆盖边界输入，结论才可复现
C. 把 ServiceWorker 的单次运行结果当成所有版本和规模都成立
D. 学习 PWA 时要同时说明输入、输出和失败路径，不能只看正常流程

**参考答案**：验证 ServiceWorker 时要固定版本并覆盖边界输入，结论才可复现；学习 PWA 时要同时说明输入、输出和失败路径，不能只看正常流程

**解析**：结论应落在验证 ServiceWorker 时要固定版本并覆盖边界输入。本课把PWA 与离线能力拆成概念、示例与故障现场三部分，因此判断 PWA 时必须同时交代输入、输出和失败路径，这使“学习 PWA 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在PWA 与离线能力里，判断 ServiceWorker 时要固定版本与边界输入，所以“验证 ServiceWorker 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

**教材衔接：复习与自测**

- [ ] 能用 Manifest 与 Service Worker 让应用可安装、可离线。
- [ ] 按资源类型选择五种缓存策略之一。
- [ ] 离线写操作入队并带幂等键，联网后重放。
- [ ] activate 阶段清理旧版本缓存。
- [ ] 版本更新有提示机制且能强制刷新。

**教材衔接：动手练习**

> 本课练习重点：围绕「PWA、ServiceWorker、离线」完成复述、实验和交付，每个结果都要能被别人检查。

先写 PWA 的最小语义结构，再调整样式，最后检查键盘、窄屏与对比度。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. PWA 与离线能力解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「ServiceWorker」是什么关系？

验收标准：说明 PWA 与 ServiceWorker 的分工，并写出一个失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：围绕「核心组成速查」小节做一次五步记录，原例取自 SHELL_ASSETS，改动只允许动一处PWA，原因要能指回正文的判断依据。

### 练习 3：交付一个小结果（30 分钟）

先完成 核心组成速查 的最小页面，再补交互与响应式。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「PWA」和「ServiceWorker」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

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

- 改动点：把 ServiceWorker 换成边界值，其他输入保持原样。
- 预测：先写下「PWA 与离线能力」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响PWA。

### 任务 3：迁移到自己的数据

换一个 ServiceWorker 场景重做一次，确认结论不是只对示例数据成立。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「Service Worker 注册的前置条件是？」的判断依据。
- [ ] 不看解析，能说出「静态资源（JS、CSS、字体）适合哪种缓存策略？」的判断依据。
- [ ] 不看解析，能说出「离线状态下用户提交了一个订单，正确做法是？」的判断依据。
- [ ] 不看解析，能说出「为什么要在 activate 阶段清理旧缓存？」的判断依据。
- [ ] 不看解析，能说出「发版后用户仍加载旧版 JS，最可能的原因是？」的判断依据。
- [ ] 至少运行一次 SHELL_ASSETS 的示例，记录输入、输出和 PWA 的边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

---

## 术语速查

把「PWA 与离线能力」里反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 一句话说明 |
| --- | --- |
| `PWA` | 用 Service Worker、清单和缓存增强网页，使其具备安装与离线能力。 |
| `ServiceWorker` | 浏览器在页面之外运行的后台脚本，用于缓存、离线与推送。 |
| `离线` | 关键关系：先分清「PWA」与「ServiceWorker」的职责，再理解「离线」的适用边界。 |
| `缓存策略` | 规定写入、过期、淘汰和失效方式，在命中率与一致性之间取舍。 |
| `IndexedDB` | 浏览器内置的异步事务型对象数据库，适合保存大量离线结构化数据。 |
| `BackgroundSync` | 浏览器在恢复网络后由 Service Worker 重试后台同步任务。 |

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
- 适用环境：现代浏览器（Chrome/Firefox/Safari）；本课聚焦 PWA。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：PWA、ServiceWorker、离线、缓存策略、IndexedDB、BackgroundSync
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-08-17
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [MDN HTTP](https://developer.mozilla.org/docs/Web/HTTP) | HTTP 语义与缓存 |
| [W3C Web 标准](https://www.w3.org/TR/) | HTML、CSS 与 Web 标准 |
| [MDN JavaScript](https://developer.mozilla.org/docs/Web/JavaScript) | 浏览器脚本语言 |

> 「PWA 与离线能力」的链接用于离线阅读后的延伸核对；App 不会自动联网。

<!-- p1-deep-dive:start -->
