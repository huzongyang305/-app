# 网络、数据与文件

![HarmonyOS NEXT 网络请求、本地存储与后台任务的能力分层](images/diagram_harmonyos_network_data.webp)

> 内容更新时间：2026-10-06 · 学习阶段：移动 · 预计用时：55 分钟

## 本节知识框架

**课程定位**：所属分类 `harmonyos`（鸿蒙 HarmonyOS NEXT），课程主题 `网络、数据与文件`，学习阶段 移动，建议用时 55 分钟。

本课主线：按「数据在哪里」把能力切成四块来讲——远端用 `@kit.NetworkKit` 的 http 与 WebSocket，进程间用 `@ohos.rpc` 的 IPC 模型，结构化本地数据用关系型数据库 `relationalStore` 与轻量首选项 `preferences`，非结构化文件用 `@ohos.file.fs` 的沙箱目录体系；最后补上 `backgroundTaskManager` 说明退到后台之后这些操作还能不能继续跑，以及各自的约束条件。

**学完本课应当能够**

- 为一类数据选对存储载体，说清关系型数据库、首选项与文件三者的容量、事务与查询能力边界。
- 写出带超时、重试与错误码分支的网络请求，并解释为什么明文 HTTP 与证书校验在 NEXT 上必须显式声明。
- 用预置语句与条件构造器完成增删改查，杜绝字符串拼接 SQL。
- 判断一项后台工作该走短时任务、延迟任务还是周期任务，并说明系统的配额与省电约束。

### 复习清单

- [ ] 能不看正文画出应用沙箱的三类目录及各自的生命周期与清理策略。
- [ ] 能说出四种存储载体在容量、事务、查询、跨端四个维度上的差别。
- [ ] 能完成一次自测，把错题对照易错点表定位是能力选型还是约束条件记错。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| http 模块 | 应用侧 HTTP 客户端，提供 request 与在途请求管理，支持超时、代理与证书配置。 | 易错：忘记设超时，弱网下 Promise 长时间挂起。 |
| WebSocket | 全双工长连接通道，用于消息推送与实时状态同步。 | 易错：断线后不重连也不心跳，连接早已被中间设备回收。 |
| RPC / IPC | 跨进程远程调用，服务端继承 `RPCObject` 暴露接口，客户端经 `rpc.Proxy` 调用。 | 易错：把带复杂行为的对象直接当参数传，序列化后只剩数据。 |
| relationalStore | 基于 SQLite 的关系型数据库封装，提供建表、事务、条件构造器与加密配置。 | 易错：安全级别与密钥写死在代码里，跨版本迁移会打不开库。 |
| preferences | 键值型首选项存储，内存有缓存、落盘异步，适合配置类小数据。 | 易错：不 flush 就退出，最后一批写入丢失。 |
| 应用沙箱 | 每个应用私有的文件视图，含文件目录、缓存目录与临时目录三类。 | 易错：把长期数据放缓存目录，系统空间紧张时被清理。 |
| 后台任务 | 短时任务、延迟任务与周期任务三类，由系统按电量和网络条件调度。 | 易错：以为申请到短时任务就能长期运行，配额到期即被冻结。 |
| 条件构造器 | 用链式 API 生成查询条件与占位参数，替代手写 SQL 片段。 | 易错：混用拼接与构造器，绕过了参数化带来的保护。 |

## 原理与运行机制

### 机制总览：一次请求与一次落库各自走过哪些层

网络与存储看似两件事，实际上共享同一条设计原则：把耗时与不确定性关进可观测的边界。请求侧的边界是超时、重试与取消；存储侧的边界是事务、安全级别与目录生命周期。任何一个功能上线前都应当能回答两个问题：请求失败时用户看到什么，进程被杀时数据停在哪一步。

**教材衔接：四种数据载体的选型**

| 载体 | 数据形态 | 容量量级 | 事务 | 典型用途 |
| --- | --- | --- | --- | --- |
| preferences | 键值 | KB 级 | 无跨键事务 | 开关、上次页签、草稿 |
| relationalStore | 表与关系 | MB 到 GB | 有 | 收藏、离线队列、消息表 |
| file fs | 字节流 | 受磁盘限制 | 无 | 图片、导出文件、下载缓存 |
| AppStorage | 内存对象 | 受内存限制 | 无 | 运行期共享状态，不跨启动 |

**教材衔接：网络请求的分层与错误模型**

http 模块返回的错误码来自底层传输与协议两层，业务代码要区分「可重试」（连接超时、DNS 失败）与「不可重试」（证书校验失败、参数非法）。所有请求都应在 `inflow` 上限内并发，超出后框架排队；把长轮询写成 `while` 递归会迅速耗尽句柄。需要上传大文件时优先用带进度回调的上传能力，而不是自己把文件读进内存再发。

```typescript
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';

interface LessonDto {
  id: string;
  title: string;
}

export async function fetchLessons(base: string, token: string): Promise<LessonDto[]> {
  const client = http.createHttp();
  try {
    const resp = await client.request(`${base}/lessons`, {
      method: http.RequestMethod.GET,
      header: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: 8000,
      readTimeout: 12000,
      usingProtocol: http.HttpProtocol.HTTP1_1
    });
    if (resp.responseCode !== http.ResponseCode.OK) {
      throw new Error(`http ${resp.responseCode}`);
    }
    return JSON.parse(resp.result as string) as LessonDto[];
  } catch (err) {
    const e = err as BusinessError;
    console.error(`fetch failed code=${e.code} msg=${e.message}`);
    return [];
  } finally {
    client.destroy();
  }
}
```

**教材衔接：关系型数据库的正确打开方式**

创建 `RdbStore` 需要安全级别与配置，安全级别一旦选定就不应与后续版本混用，否则老库无法打开。写操作要放进事务，尤其是「先查后插」这类幂等场景；批量写入时预编译一条语句反复绑定，比每条都执行一次 SQL 快一个数量级。查询用条件构造器生成 `WHERE` 与参数数组，值永远不进 SQL 文本。

```typescript
import { relationalStore } from '@kit.ArkData';

const SQL_CREATE = 'CREATE TABLE IF NOT EXISTS note (id INTEGER PRIMARY KEY AUTOINCREMENT, '
  + 'title TEXT NOT NULL, updated INTEGER NOT NULL)';

async function openStore(ctx: Context): Promise<relationalStore.RdbStore> {
  const config: relationalStore.StoreConfig = {
    name: 'notes.db',
    securityLevel: relationalStore.SecurityLevel.S1
  };
  const store = await relationalStore.getRdbStore(ctx, config);
  await store.executeSql(SQL_CREATE);
  return store;
}

async function insertNote(store: relationalStore.RdbStore, title: string): Promise<number> {
  const row: relationalStore.ValuesBucket = { title, updated: Date.now() };
  return store.insert('note', row);
}
```

**教材衔接：文件沙箱与访问边界**

应用看到的是一个受限文件系统。三类目录职责清晰：文件目录随应用生命周期存在，是业务数据的默认归宿；缓存目录可被系统在空间不足时清理，只放可再生产物；临时目录在应用退出后可能被回收。跨应用共享文件不能直接交换路径，必须通过 Uri 与授权（ picker 选择、拖拽、安全控件），把沙箱内路径原样发给另一个应用一定失败。

**教材衔接：后台任务的三档约束**

短时任务给正在执行的关键动作一小段窗口（例如提交未完成订单），需要声明合理的连续任务名与原因，超时后进程被冻结；延迟任务与周期任务交给系统在充电、连接 Wi-Fi、闲置时批量执行，适合同步、清理与预取；长时任务只对音频、导航、通话等白名单场景开放，且必须有可见通知。所有档位都不允许「为了保活而保活」，审核也会核查申请理由与实际行为是否一致。

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 离线优先的课程列表 | 弱网、需要展示上次缓存 | 网络拉取入库加本地读，失败时回退缓存并提示时效 |
| 学习记录批量上报 | 本地积累数百条埋点 | 事务写入队列，退到后台用短时任务补发或改周期任务 |
| 导出学习笔记为文件 | 内容为长文本与图片 | 写入应用文件目录，通过分享能力交给其他应用 |

- 典型现象：请求偶发卡住不返回。正确做法：显式设置连接与读取超时，并在页面消失时取消在途请求。
- 典型现象：应用被杀后首选项最后一条设置丢了。正确做法：写入后 flush，或改成同步刷盘的时机。
- 典型现象：换机或清除数据后数据库打不开。正确做法：安全级别与库名保持稳定，升级用建表语句与版本迁移而不是删库。

### 最小验证场景

- 准备：一个页面做网络拉取、一条数据写库、一个开关写首选项、一个下载任务写缓存目录。
- 观察：分别在正常网络、飞行模式、应用退后台三种条件下执行同一组操作，记录每条数据的最终落点与错误提示。
- 判定：断网时有可读兜底、退后台后没有仍在偷偷轮询的定时器、缓存目录内容被清空后功能仍可恢复，三项成立才算闭环。

## 代码/协议/SQL 示例

**教材衔接：带索引的建表与条件查询**

高频过滤字段要建索引，否则随数据量增长查询退化为全表扫描。条件用构造器表达，参数值不进入 SQL 文本。

```typescript
import { relationalStore } from '@kit.ArkData';

async function recentNotes(store: relationalStore.RdbStore, since: number) {
  await store.executeSql(
    'CREATE INDEX IF NOT EXISTS idx_note_updated ON note(updated DESC)');
  const ts: relationalStore.RdbPredicates =
    new relationalStore.RdbPredicates('note');
  ts.greaterThan('updated', since).orderByDesc('updated').limitAs(50);
  const result = await store.query(ts, ['id', 'title', 'updated']);
  const rows: string[] = [];
  while (result.goToNextRow()) {
    rows.push(result.getString(result.getColumnIndex('title')));
  }
  result.close();
  return rows;
}
```

**教材衔接：首选项与文件写入的落盘时机**

首选项写内存后异步落盘，重要配置要在合适时机 flush；文件写入必须显式关闭或走工具类，否则缓冲区数据可能还没落到磁盘。

```typescript
import { preferences } from '@kit.ArkData';
import { fileIo } from '@kit.CoreFileKit';

async function saveTheme(ctx: Context, value: string): Promise<void> {
  const store = await preferences.getPreferences(ctx, 'settings');
  await store.put('theme', value);
  await store.flush();
}

function writeExport(path: string, text: string): void {
  const file = fileIo.openSync(path, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
  try {
    fileIo.writeSync(file.fd, text);
  } finally {
    fileIo.closeSync(file);
  }
}
```

错误表现：把用户输入直接拼进 SQL，一条包含引号的标题就让语句报错，同时留下注入面。

```typescript
await store.executeSql(`DELETE FROM note WHERE title = '${title}'`);
```

正确写法：让值走参数占位或条件构造器，由数据库自己处理转义与类型。

```typescript
const ts = new relationalStore.RdbPredicates('note');
ts.equalTo('title', title);
await store.delete(ts);
```

## 时间/空间复杂度或性能分析

| 操作 | 复杂度或成本 | 失控表现 | 优化手段 |
| --- | --- | --- | --- |
| 单次 HTTP | 网络往返为主 | 串行请求叠加延迟 | 合并接口、受控并发 |
| 无索引查询 | 全表线性扫描 | 万行后明显卡顿 | 给过滤与排序字段建索引 |
| 逐条插入 | 每次一个事务 | 批量导入耗时数倍 | 事务包裹加预编译语句 |
| 大结果集 | 与行数线性 | 内存峰值与游标滞留 | limit 分页、及时 close |
| 文件读写 | 与字节数线性 | 主线程读写造成掉帧 | 分块、异步接口、缓存目录 |

数据库侧最常见的性能事故是「在 UI 线程循环插入」。SQLite 每次自动提交都要走一次日志落盘，逐条插入的成本近似条数乘单次落盘时延；把整批包进一个事务并复用同一条预编译语句，通常能把耗时压到原来的十分之一以内。查询侧的原则是「只取需要的列与行」：游标会持有底层页，读完必须关闭，否则并发写会被阻塞。

网络侧的成本模型是并发而不是算力。把二十个请求排在 `for` 循环里 await，总时延等于二十次往返之和；受控并发（例如同时四到六个）能把总耗时压到批次数量级。同时要记住应用同时存在的连接数有上限，长连接与轮询叠加会挤占普通请求的额度，实时数据优先合并成一条 WebSocket 通道。

数据层是最容易累积隐性成本的一环。启动耗时上，把建表、迁移或全量读取放进能力初始化会直接压进首帧之前，正确顺序是先渲染骨架再补数据。帧率方面，在滚动回调里同步读写本地存储会让主线程等待磁盘，表现为列表越滑越卡。渲染上数据本身不占绘制预算，但一次不加限制的查询可能带出大批对象，间接抬高内存水位并触发回收抖动。包体角度数据不进产物，真正的影响来自随包附带的预置库与静态资源，应当与限定目录一并裁剪。

## 常见误区与易错点

- **不写超时。** 弱网下 Promise 长期挂起，页面永远停在加载态。
- **忘记 destroy 或取消。** 请求与连接累积到上限，之后的请求静默排队。
- **用字符串拼 SQL。** 既有注入风险，又会因引号与类型问题报错，值必须走参数。
- **把首选项当数据库。** 无跨键事务、查询能力弱，写入大量记录会让内存与磁盘都不划算。
- **长期数据放缓存目录。** 系统回收空间时会被清掉，用户数据丢失。
- **写完不 flush 就退出。** 内存里的改动没落盘，表现为「偶发丢一次设置」。
- **打开游标不关闭。** 数据量一上来就出现内存增长与写阻塞。
- **安全级别换来换去。** 数据库文件与密钥不匹配，老用户升级后打不开库。
- **把后台当常态。** 短时有配额、延迟看条件、长时需白名单，任何档位都可能被冻结。
- **跨应用传沙箱路径。** 对端没有读取权限，必须换成受控的 Uri 与授权流程。

## 与其他知识点的关系

**教材衔接：与相邻课程的接口**

数据层课程决定「东西存在哪、什么时候读写」，状态管理课决定「读出来之后交给谁持有」，权限课决定「哪些数据允许读」。三者最容易出错的地方是边界：把网络重试逻辑写进组件、把游标对象塞进全局状态、在没有权限时直接查询敏感数据，都会在后续维护中反噬。

- 向上承接 `harmonyos_state_management`：远端数据入库后转成可观察模型再交给界面。
- 与 `harmonyos_system_capabilities` 交界：联网、定位与通知都受权限与省电策略约束。
- 与 `harmonyos_multimedia` 协同：图片与音频文件的下载、缓存与沙箱路径共用一套规则。
- 与 `harmonyos_distributed` 呼应：跨端同步要求数据可序列化且有明确的冲突解决策略。
- 平行对照 `database_transaction`：事务边界、隔离级别与索引原理在鸿蒙侧同样适用。

| 关联课程 ID | 关联主题 | 关系说明 |
| --- | --- | --- |
| harmonyos_state_management | 状态管理与数据传递 | 数据层输出模型，状态层决定刷新粒度 |
| harmonyos_system_capabilities | 系统能力与权限 | 网络与文件访问的前置条件是权限与约束声明 |
| harmonyos_multimedia | 多媒体与图形渲染 | 媒体文件的下载缓存与沙箱路径处理复用本课规则 |
| harmonyos_release_optimization | 性能调优与上架 | 请求耗时与数据库慢查询在该课纳入指标与监控 |
| database_transaction | 数据库事务 | 事务边界与索引策略的通用原理来源 |

## 自测题与参考答案

**教材衔接：题号 1** — 应用需要向自家服务端发一次 HTTPS 请求，优先选用的能力是？

**参考答案**：用 NetworkKit 的 http 模块。

本题正确项是「用 NetworkKit 的 http 模块」。它已封装连接池、超时、证书校验与错误码，是官方推荐的应用层入口。自己写底层套接字要重新处理 TLS、代理与并发限制；用界面组件发跨域请求把业务逻辑与渲染耦合在一起；把网络字节流代理到文件读写更是绕开了整套错误与超时模型，三者都不该作为首选。

**教材衔接：题号 2** — 在关系型数据库中避免 SQL 注入的正确做法是？

**参考答案**：用占位符传参而非拼接文本。

本题正确项是「用占位符传参而非拼接文本」。值走绑定参数后由数据库处理转义与类型，用户输入里的引号不会改变语句结构；条件构造器本质上也是同一机制。删掉引号会破坏正常数据，先做一层自定义编码挡不住构造好的恶意片段，限定表名只影响可见范围与注入无关。

**教材衔接：题号 3** — 需要保存少量开关与上次浏览位置这类配置，最合适的载体是？

**参考答案**：首选项 preferences。

本题正确项是「首选项 preferences」。它以键值形式提供内存缓存加异步落盘，读写接口简单，正适合小量配置。用文件手写序列化要自己处理并发与损坏，用关系型数据库为几个字段建表与查询过重，只放 AppStorage 则在进程结束后丢失，不满足重启后仍在的要求。

**教材衔接：题号 4** — 应用退到后台后还要完成一次短暂的订单补发，应选用的机制是？

**参考答案**：申请短时任务窗口。

本题正确项是「申请短时任务窗口」。短时任务给关键动作一小段受控执行时间，超时后进程被冻结，符合「马上要完成但不能长期跑」的语义。用循环或定时器在后台空跑会被省电策略直接终止，把逻辑继续留在主线程等它被挂起则根本执行不完；延迟与周期任务由系统挑时机，不保证立刻执行。

**教材衔接：题号 5** — 最后一次 get 的返回值是？
import { preferences } from '@kit.ArkData';
const store = await preferences.getPreferences(ctx, 'settings');
await store.put('volume', 20);
await store.flush();
await store.delete('volume');
const value = await store.get('volume', 5);

**参考答案**：返回默认值 5。

本题正确项是「返回默认值 5」。键被删除后存储里已不存在该条目，`get` 的第二个参数就是缺失时的兜底值，因此返回 5。flush 只影响是否落盘，不会让删除回滚；ArkTS 的接口在缺键时返回调用方给的默认值而不是抛异常，也不会返回空值，所以拿 20、拿空或等异常三种预期都不成立。

## 考点精讲

**教材衔接：高频考点**

1. 四类数据载体的选型边界，尤其是首选项与数据库的职责差别。
2. 参数化查询与条件构造器，是数据安全类题目的唯一正确答案。
3. 沙箱三类目录的生命周期与清理策略。
4. 后台任务三档能力与各自的约束条件。

**教材衔接：命题规律**

- 选型题给一句很具体的数据特征（条数量级、是否需要查询、是否要跨启动），正确项只匹配其中关键的一条。
- 排错题描述「设置偶发丢失」「列表越用越慢」，答案指向 flush 与索引而非网络带宽。
- 代码题给一小段存储 API 调用序列，问最后一步的返回值或状态。

**教材衔接：常见考点**

问：应用需要向自家服务端发一次 HTTPS 请求，优先选用的能力是？
答：用 NetworkKit 的 http 模块。

问：在关系型数据库中避免 SQL 注入的正确做法是？
答：用占位符传参而非拼接文本。

问：需要保存少量开关与上次浏览位置这类配置，最合适的载体是？
答：首选项 preferences。

问：应用退到后台后还要完成一次短暂的订单补发，应选用的机制是？
答：申请短时任务窗口。

问：最后一次 get 的返回值是？
import { preferences } from '@kit.ArkData';
const store = await preferences.getPreferences(ctx, 'settings');
await store.put('volume', 20);
await store.flush();
await store.delete('volume');
const value = await store.get('volume', 5);
答：返回默认值 5。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| http 模块 | 应用层网络客户端，提供超时、证书与在途请求管理能力。 |
| WebSocket | 全双工长连接通道，适合实时消息与状态同步。 |
| RPCObject | 跨进程服务端的基类，定义可被远端调用的接口对象。 |
| RdbStore | 关系型数据库句柄，负责建表、事务、增删改查。 |
| RdbPredicates | 条件构造器，生成 WHERE 子句与绑定参数。 |
| preferences | 键值型轻量存储，内存缓存加异步落盘。 |
| 应用沙箱 | 应用私有的文件视图，按目录区分生命周期与清理策略。 |
| 短时任务 | 退后台后有限时间窗内继续执行关键动作的机制。 |

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-11-10
- 学习阶段：移动
- 适用环境：DevEco Studio NEXT / HarmonyOS API 12+；真机需 HarmonyOS 4/5 NEXT；构建产物为 HAP/HSP/AppPack
- 内容来源：华为官方文档与工程实践整理
- 相关主题：ArkTS、ArkUI、分布式软总线、上架 AppGallery

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2026-11-10
- [HarmonyOS NEXT 开发者官网](https://developer.huawei.com/consumer/cn/harmonyos-next/)
- [NetworkKit 网络访问开发指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/http-slab-remoting)
- [ArkData 关系型数据库指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/data-persistence-by-rdb-store)
- [首选项 Preferences 使用说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/data-preference-store-config)
- [后台任务开发指导与约束](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/background-task-start)
