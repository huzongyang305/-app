# 图解 Kubernetes 调度与探针

![图解 Kubernetes 调度与探针](images/visual_k8s_scheduling.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：20 分钟

## 学习目标

- 能用自己的话解释「图解 Kubernetes 调度与探针」解决了什么问题，而不是只背术语。
- 能说清 「Kubernetes」、「调度」、「探针」、「滚动更新」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「图解专题」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：Pod 一生、调度两步决策、三种探针分工与优雅下线。

## 前置知识

- 先完成上一课《图解 HTTPS 证书链与 TLS 握手》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：Kubernetes、调度、探针。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 一句话说清

Kubernetes 的核心是**声明期望状态 + 控制循环纠正**。
一个 Pod 从被创建到能接流量，要经过**调度、启动、探针检查、注册端点**四步。

## 一张图看懂 Pod 的一生

```text
① 你提交 Deployment（期望副本数 3）
        │
        ▼
② Deployment → ReplicaSet → 创建 3 个 Pod 对象（Pending）
        │
        ▼
③ 调度器 kube-scheduler 选节点
   · 过滤：资源够不够、污点能否容忍、亲和性是否满足
   · 打分：资源均衡、尽量分散、镜像已缓存
        │
        ▼
④ kubelet 拉起容器
   · 拉镜像 → 创建容器 → 执行 startupProbe
        │
        ▼
⑤ 探针通过
   · readinessProbe 通过 → 加入 Service Endpoints（开始接流量）
   · livenessProbe 失败 → 重启容器
        │
        ▼
⑥ 对外提供服务（Running）
```

## 调度器的两步决策

```text
第一步：过滤（Filter）—— 排除不合适的节点
  ┌──────────────┐
  │ 节点 A 内存不足 │ ✗ 排除
  │ 节点 B 有污点    │ ✗ 排除
  │ 节点 C 满足条件  │ ✓ 保留
  │ 节点 D 满足条件  │ ✓ 保留
  └──────────────┘

第二步：打分（Score）—— 在合格节点里选最优
  节点 C：资源均衡 70 分
  节点 D：资源均衡 85 分，且镜像已缓存 +10
  → 选择节点 D
```

| 约束类型 | 例子 | 作用 |
| --- | --- | --- |
| 资源请求 | `requests.cpu: 500m` | 调度依据（不是 limit） |
| 节点选择器 | `nodeSelector: disktype=ssd` | 只调度到特定节点 |
| 亲和性 | `nodeAffinity` / `podAntiAffinity` | 靠拢或分散 |
| 污点与容忍 | `taints` / `tolerations` | 独占节点或隔离 |

```yaml
resources:
  requests: { cpu: 500m, memory: 512Mi }   # 调度按这个预留
  limits:   { cpu: "1",  memory: 1Gi }     # 上限，超了会被限制或杀掉

topologySpreadConstraints:                 # 让副本分散到不同节点
  - maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: ScheduleAnyway
    labelSelector:
      matchLabels: { app: web }
```

**只写 limits 不写 requests 是常见错误**：调度器会按 0 请求处理，导致节点超卖。

## 三种探针的分工与顺序

```text
容器启动
   │
   ├─ startupProbe（启动慢的服务用）
   │     失败 → 重启容器；通过后不再执行
   │
   ├─ readinessProbe（能否接流量）
   │     失败 → 从 Endpoints 摘除，不重启
   │
   └─ livenessProbe（是否还活着）
         失败 → 重启容器
```

| 探针 | 检查什么 | 失败后果 | 典型配置 |
| --- | --- | --- | --- |
| startupProbe | 是否完成初始化 | 重启 | `failureThreshold: 30`，间隔 2s |
| readinessProbe | 能否处理请求 | 摘流量 | 依赖检查放这里 |
| livenessProbe | 进程是否卡死 | 重启 | 不要检查外部依赖 |

```yaml
readinessProbe:
  httpGet: { path: /healthz/ready, port: 8080 }
  initialDelaySeconds: 3
  periodSeconds: 5
  failureThreshold: 3

livenessProbe:
  httpGet: { path: /healthz/live, port: 8080 }
  periodSeconds: 10
  failureThreshold: 3

startupProbe:                # 启动慢时用它保护 liveness
  httpGet: { path: /healthz/live, port: 8080 }
  failureThreshold: 30
  periodSeconds: 2
```

## 发布期间 Pod 的流转

```text
滚动更新（maxSurge=1, maxUnavailable=0）

旧版本 [A1][A2][A3]
  ① 新建 B1 → ready 后加入 Endpoints      [A1][A2][A3][B1]
  ② 摘除 A1 → 等待在途请求结束              [A2][A3][B1]
  ③ 新建 B2 → ready 后加入                 [A2][A3][B1][B2]
  ④ 摘除 A2 …依此类推，直到全部替换为 B

全程可用副本数不低于 3，因此不中断服务
```

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1              # 最多多出 1 个
    maxUnavailable: 0        # 保证可用副本不减少
terminationGracePeriodSeconds: 30
```

## 优雅下线的四步

```text
1. Pod 变为 Terminating，从 Endpoints 摘除（停止新流量）
2. preStop 钩子执行（例如 sleep 5 秒，等负载均衡刷新）
3. 发送 SIGTERM 给容器主进程
4. 应用停止接收新请求、处理完在途请求后退出
   （超时未退出则 SIGKILL）
```

```yaml
lifecycle:
  preStop:
    exec:
      command: ["/bin/sh", "-c", "sleep 5"]
```

## 常见异常状态对照

| 状态 | 含义 | 排查方向 |
| --- | --- | --- |
| `Pending` | 没有合适节点 | 资源不足、污点、PVC 未绑定 |
| `ContainerCreating` | 正在拉镜像或挂卷 | 镜像仓库、密钥、存储 |
| `CrashLoopBackOff` | 容器反复退出 | 看 `logs --previous` 与探针配置 |
| `ImagePullBackOff` | 拉不到镜像 | 镜像名、镜像仓库凭据 |
| `Running` 但不接流量 | 就绪探针未通过 | 检查 readiness 路径与依赖 |
| `OOMKilled` | 超过内存 limit | 调大 limit 或修内存泄漏 |

```bash
kubectl get pods -o wide                        # 状态与所在节点
kubectl describe pod <pod>                      # 事件是排查关键
kubectl logs <pod> --previous                   # 崩溃前的日志
kubectl get events --sort-by=.lastTimestamp     # 集群事件时间线
kubectl top pod <pod>                           # 实际资源用量
```

## 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 只写 limits 不写 requests | 节点超卖、Pod 被驱逐 | 两者都写 |
| liveness 检查外部依赖 | 依赖抖动引发重启风暴 | 依赖检查放 readiness |
| 探针超时设置过短 | 频繁误判 | 结合真实启动时间设置 |
| 没有 startupProbe | 启动慢被 liveness 杀掉 | 加 startupProbe 保护 |
| 没有 preStop | 发布期间偶发 502 | 加 preStop 等待摘流 |
| 副本全挤在同一节点 | 节点故障全挂 | 用反亲和或分散约束 |
| 镜像标签用 latest | 版本不可控 | 用 commit SHA |
| 不看 describe 只看 logs | 找不到调度或拉镜像问题 | 先看事件再看日志 |

## 本课小结
- Pod 的一生：**调度 → 启动 → 探针 → 接流量**，每一环都有对应的排查命令。
- 三种探针职责不同：**startup 保护启动、readiness 控制流量、liveness 负责重启**。
- 调度只认 `requests`，`limits` 决定上限，两者都要写。

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「Kubernetes、调度、探针」完成复述、实验和交付，每个结果都要能被别人检查。

先不看原图手绘流程，再标出状态变化，最后用自己的话解释关键一步。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「图解 Kubernetes 调度与探针」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「调度」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

不看原图手绘一遍流程，再用自己的话指出图中的关键状态变化。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「Kubernetes」和「调度」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Kubernetes Scheduling Illustrated

**Summary:** Pod lifecycle, scheduling, probes and graceful shutdown.

**Category:** Visual Guide  
**Level:** 进阶  
**Key terms:** Kubernetes, 调度, 探针, 滚动更新, 优雅下线

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：通用图解与系统原理
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Kubernetes、调度、探针、滚动更新、优雅下线
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

<!-- top50-rewrite:v1 -->

## 课程专属精读：图解 Kubernetes 调度与探针

### 一、知识地图

- **一句话说清**：Kubernetes 的核心是**声明期望状态 + 控制循环纠正**。
- **一张图看懂 Pod 的一生**：① 你提交 Deployment（期望副本数 3）
- **调度器的两步决策**：第一步：过滤（Filter）—— 排除不合适的节点
- **三种探针的分工与顺序**：容器启动
- **发布期间 Pod 的流转**：滚动更新（maxSurge=1, maxUnavailable=0）
- **优雅下线的四步**：1. Pod 变为 Terminating，从 Endpoints 摘除（停止新流量）
- **常见异常状态对照**：理解它的定义、输入、输出和失败边界。
- **新手最容易踩的八个坑**：理解它的定义、输入、输出和失败边界。

### 二、机制与验证

| 主题 | 需要回答的问题 | 验证方式 |
| --- | --- | --- |
| 一句话说清 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 一张图看懂 Pod 的一生 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 调度器的两步决策 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 三种探针的分工与顺序 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 发布期间 Pod 的流转 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 优雅下线的四步 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 常见异常状态对照 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 新手最容易踩的八个坑 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |

### 三、专属检查问题

1. 一句话说清 与相邻主题的边界是什么？
2. 一张图看懂 Pod 的一生 与相邻主题的边界是什么？
3. 调度器的两步决策 与相邻主题的边界是什么？
4. 三种探针的分工与顺序 与相邻主题的边界是什么？
5. 发布期间 Pod 的流转 与相邻主题的边界是什么？
6. 优雅下线的四步 与相邻主题的边界是什么？
7. 常见异常状态对照 与相邻主题的边界是什么？
8. 新手最容易踩的八个坑 与相邻主题的边界是什么？

### 四、故障排查

1. 固定输入和环境，确认问题能复现。
2. 找到第一个异常状态，不从最终错误倒猜。
3. 只改变一个变量，记录预测和真实结果。
4. 修复后补边界、失败和重复执行测试。

<!-- p2-references:v1 -->

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [RFC Editor](https://www.rfc-editor.org/) | 协议与状态机 |
| [MDN Web Docs](https://developer.mozilla.org/) | 浏览器与网络流程 |

> 本课主题：Pod 一生、调度两步决策、三种探针分工与优雅下线。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

