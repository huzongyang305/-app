# Kubernetes 基础

![Kubernetes 从集群到容器的对象层次](images/diagram_k8s_objects.webp)

![Kubernetes 基础](images/category_kubernetes.webp)

> 内容更新时间：2026-10-06 · 学习阶段：高级 · 预计用时：55 分钟

## 本节知识框架

**课程定位**：所属分类 `toolchain`（工具链），课程主题 `Kubernetes 基础`，学习阶段 高级，建议用时 45 分钟。

本课主线：声明式对象模型、Deployment/Service、探针与发布策略。

**学完本课应当能够**
- 说清 `requests` 与 `探针` 的含义与区别，并各举一个正例和一个反例。
- 用本课示例验证 `资源请求与限制` 的行为，记录输入、输出与失败条件。
- 遇到「Pod 一直 Pending」这类问题时，能说出触发条件与修复顺序。

### 从概念到验证的学习链条

1. `requests`：先掌握 `requests` 影响调度，`limits` 影响超限行为；**探针配错会导致容器反复重启**——readiness 失败只是摘流量，liveness 失败会重启容器，再用它解释 `探针` 为什么会出现。
2. `探针`：先掌握 liveness、readiness、startup 三种健康检查，配置不当会误杀容器或过早导入流量，再用它解释 `资源请求与限制` 为什么会出现。
3. `资源请求与限制`：先掌握 requests 决定调度时的预留量，limits 决定运行时的上限，两者共同决定 Pod 的服务质量等级，再用它解释 `调度` 为什么会出现。
4. `调度`：先掌握 kube-scheduler 按资源、污点与亲和性把 Pod 放到合适的节点上，Pending 多半卡在这一步，再用它解释 `Pod` 为什么会出现。
5. `Pod`：先掌握 Kubernetes 最小调度单元，包含一个或多个共享网络与存储的容器，再用它解释 本课示例的观察结果 为什么会出现。

**先修与衔接**：本课是「工具链」分类的第 11 课。先修内容：《CI/CD 与 GitHub Actions》。《CI/CD 与 GitHub Actions》里的 `npm ci`、`CD` 是本课的前提。相关或后续课程：《可观测性：日志、指标与链路》、《图解 Kubernetes 调度与探针》。

### 完成判据

- **定义关**：不看正文也能说明 `requests` 是 `requests` 影响调度，`limits` 影响超限行为，**探针配错会导致容器反复重启**——readiness 失败只是摘流量，liveness 失败会重启容器，并指出一个反例。
- **机制关**：能按“输入 → 转换 → 输出 → 验证”复述 `Kubernetes 基础`，而不是只背结论。
- **示例关**：能运行或推演 `Kubernetes 基础` 的 `text` 示例，并说明一个真实出现的标识符或字面量。
- **证据关**：能指出 `Kubernetes 基础` 示例里的 出现字面量 `100m`，并说明它支持或反驳了本课的哪一条结论。
- **排错关**：能复现 Pod 一直 Pending，记录现象并按 资源不足、节点选择器/污点不匹配、PVC 未绑定 修复。
- **迁移关**：能把 `Kubernetes`、`Pod`、`Deployment`、`Service` 放进一个与 `Kubernetes 基础` 不同的项目场景，并保持输入与验证条件可追踪。
- **复盘关**：学完 `Kubernetes 基础` 后，用一句话写下仍然不确定的结论，并列出下一次验证需要的输入、环境和成功判据。

### 复习清单

- [ ] 能不看正文复述本课核心术语，并指出一个边界或反例。
- [ ] 能运行或推演本课示例，记录输入、输出与失败现象。
- [ ] 能完成一次自测，并把错题对照错误表定位原因。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| requests | requests 影响调度，limits 影响超限行为；**探针配错会导致容器反复重启**——readiness 失败只是摘流量，liveness 失败会重启容器。 | 易错：只设置了 limits 没设 requests；正确做法是必须同时设置 requests。 |
| 探针 | liveness、readiness、startup 三种健康检查，配置不当会误杀容器或过早导入流量。 | 易错：`kubectl logs --previous`；正确做法是应用启动失败、配置缺失、探针过严。 |
| 资源请求与限制 | requests 决定调度时的预留量，limits 决定运行时的上限，两者共同决定 Pod 的服务质量等级。 | 只在「requests 决定调度时的预留量，limits 决定运行时的上限，两者共同决定 Pod 的服务质量等级」这一前提下成立，换输入或换环境要重新验证。 |
| 调度 | kube-scheduler 按资源、污点与亲和性把 Pod 放到合适的节点上，Pending 多半卡在这一步。 | 只在「kube-scheduler 按资源、污点与亲和性把 Pod 放到合适的节点上，Pending 多半卡在这一步」这一前提下成立，换输入或换环境要重新验证。 |
| Pod | Kubernetes 最小调度单元，包含一个或多个共享网络与存储的容器 | 易错：`kubectl describe pod` 看 Events；正确做法是资源不足、节点选择器/污点不匹配、PVC 未绑定。 |
| Pod | 最小调度单位，包含一个或多个容器 | 易错：`kubectl describe pod` 看 Events；正确做法是资源不足、节点选择器/污点不匹配、PVC 未绑定。 |
| Deployment | 管理 Pod 副本数、滚动更新与回滚 | 易错：重建后改动丢失；正确做法是改 Deployment 等控制器资源。 |
| Service | 为一组 Pod 提供稳定访问入口与负载均衡 | 易错：`kubectl get endpoints web`；正确做法是selector 与 labels 不匹配，或 Pod 未 Ready。 |
| Ingress | 七层入口，按域名/路径路由 | 易错：`kubectl describe ingress`；正确做法是path/host 规则不匹配、ingressClassName 错误。 |
| ConfigMap / Secret | 注入配置与密钥 | 权限与密钥策略变化会让结论失效，按最小权限并用真实凭据流程复验。 |
| StatefulSet | 有状态服务（数据库），Pod 有稳定标识与存储 | 索引命中与数据分布决定实际开销，判断前先看执行计划而不是只看结果是否正确。 |
| Job / CronJob | 一次性任务与定时任务 | 只在「一次性任务与定时任务」这一前提下成立，换输入或换环境要重新验证。 |
| HPA | 按 CPU/自定义指标自动扩缩容 | 只在「按 CPU/自定义指标自动扩缩容」这一前提下成立，换输入或换环境要重新验证。 |

## 原理与运行机制

### 机制总览

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | requests | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | 探针 | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | 资源请求与限制 | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

**教材衔接：什么时候不需要 K8s**

1. 只有一两个服务、单机 Docker 足够时。
2. 团队没有运维能力，托管容器平台（Cloud Run、App Runner）更省心。
3. 需要极简部署的静态站点或小工具。

K8s 的复杂度是真实成本：集群、网络、存储、证书、监控都要有人负责。

**失败路径（来自本课错误表）**
- Pod 一直 Pending → `kubectl describe pod` 看 Events → 资源不足、节点选择器/污点不匹配、PVC 未绑定。
- ImagePullBackOff → `describe` 看拉取错误 → 镜像名/tag 写错、私有仓库缺 imagePullSecret。
- CrashLoopBackOff → `kubectl logs --previous` → 应用启动失败、配置缺失、探针过严。
- Service 访问 503 → `kubectl get endpoints web` → selector 与 labels 不匹配，或 Pod 未 Ready。
### 机制拆解：每一步的输入、动作与输出

#### 1. `requests`
- 输入：`Kubernetes`；本步把 `requests` 影响调度，`limits` 影响超限行为；**探针配错会导致容器反复重启**——readiness 失败只是摘流量，liveness 失败会重启容器 当作判断规则。
- 动作：围绕 `requests` 保留中间状态，并记录它与 `探针` 的对应关系。
- 输出：`探针`，它可以被下一段代码、测试或记录继续使用。
- `requests` 的失败条件：当资源使用率不高但扩容了时，会出现只设置了 limits 没设 requests。

#### 2. `探针`
- 输入：`requests`；本步把 liveness、readiness、startup 三种健康检查，配置不当会误杀容器或过早导入流量 当作判断规则。
- 动作：围绕 `探针` 保留中间状态，并记录它与 `资源请求与限制` 的对应关系。
- 输出：`资源请求与限制`，它可以被下一段代码、测试或记录继续使用。
- `探针` 的失败条件：当CrashLoopBackOff时，会出现`kubectl logs --previous`。

#### 3. `资源请求与限制`
- 输入：`探针`；本步把 requests 决定调度时的预留量，limits 决定运行时的上限，两者共同决定 Pod 的服务质量等级 当作判断规则。
- 动作：围绕 `资源请求与限制` 保留中间状态，并记录它与 `调度` 的对应关系。
- 输出：`调度`，它可以被下一段代码、测试或记录继续使用。
- `资源请求与限制` 的失败条件：只在「requests 决定调度时的预留量，limits 决定运行时的上限，两者共同决定 Pod 的服务质量等级」这一前提下成立，换输入或换环境要重新验证。

#### 4. `调度`
- 输入：`资源请求与限制`；本步把 kube-scheduler 按资源、污点与亲和性把 Pod 放到合适的节点上，Pending 多半卡在这一步 当作判断规则。
- 动作：围绕 `调度` 保留中间状态，并记录它与 `Pod` 的对应关系。
- 输出：`Pod`，它可以被下一段代码、测试或记录继续使用。
- `调度` 的失败条件：只在「kube-scheduler 按资源、污点与亲和性把 Pod 放到合适的节点上，Pending 多半卡在这一步」这一前提下成立，换输入或换环境要重新验证。

#### 5. `Pod`
- 输入：`调度`；本步把 Kubernetes 最小调度单元，包含一个或多个共享网络与存储的容器 当作判断规则。
- 动作：围绕 `Pod` 保留中间状态，并记录它与 `100m` 的对应关系。
- 输出：`100m`，它可以被下一段代码、测试或记录继续使用。
- `Pod` 的失败条件：当Pod 一直 Pending时，会出现`kubectl describe pod` 看 Events。

### 示例中的可观察事实

1. 出现字面量 `100m`；它对应的课程主题是 `Kubernetes 基础`。
2. 出现字面量 `128Mi`；它对应的课程主题是 `Kubernetes 基础`。
3. 出现字面量 `500m`；它对应的课程主题是 `Kubernetes 基础`。
4. 出现字面量 `512Mi`；它对应的课程主题是 `Kubernetes 基础`。

### 复现实验记录

- 环境：`Kubernetes 基础` 使用 `text` 示例，固定 `Kubernetes`、`Pod`、`Deployment`、`Service` 作为第一组条件。
- 首轮输入：先确认 出现字面量 `100m`，预测 `requests` 会怎样变化。
- 基线观察：记录命令、输入、输出和错误原文，不用截图代替可复制的文本。
- 单变量修改：只改变 `Kubernetes`，观察 `Pod` 是否仍满足定义。
- 失败注入：复现 Pod 一直 Pending，确认现象是 `kubectl describe pod` 看 Events。
- 记录结论：把“修改前、修改后、预期变化、实际变化”写成四列表，这样复盘 `Kubernetes 基础` 时才能区分概念错误与实现错误。

## 典型应用场景

- **Pod 一直 Pending**：典型现象是`kubectl describe pod` 看 Events；正确做法是资源不足、节点选择器/污点不匹配、PVC 未绑定。
- **ImagePullBackOff**：典型现象是`describe` 看拉取错误；正确做法是镜像名/tag 写错、私有仓库缺 imagePullSecret。
- **CrashLoopBackOff**：典型现象是`kubectl logs --previous`；正确做法是应用启动失败、配置缺失、探针过严。
- **Service 访问 503**：典型现象是`kubectl get endpoints web`；正确做法是selector 与 labels 不匹配，或 Pod 未 Ready。

### 最小验证场景

- 准备：保留 `text` 示例的原始输入，先记录 `Kubernetes 基础` 的基线输出和完整运行命令。
- 观察：先核对 出现字面量 `100m`，再改变一个与 `requests` 相关的条件。
- 判定：新结果与 `Kubernetes 基础` 的基线不同不等于错误；只有当差异破坏了 `requests` 的定义或错误表中的约束，才判定为失败。

### 选择与边界

- 使用 `requests` 时，先满足它的定义：`requests` 影响调度，`limits` 影响超限行为；**探针配错会导致容器反复重启**——readiness 失败只是摘流量，liveness 失败会重启容器；易错：只设置了 limits 没设 requests；正确做法是必须同时设置 requests。
- 使用 `探针` 时，先满足它的定义：liveness、readiness、startup 三种健康检查，配置不当会误杀容器或过早导入流量；易错：`kubectl logs --previous`；正确做法是应用启动失败、配置缺失、探针过严。
- 使用 `资源请求与限制` 时，先满足它的定义：requests 决定调度时的预留量，limits 决定运行时的上限，两者共同决定 Pod 的服务质量等级；只在「requests 决定调度时的预留量，limits 决定运行时的上限，两者共同决定 Pod 的服务质量等级」这一前提下成立，换输入或换环境要重新验证。
- 使用 `调度` 时，先满足它的定义：kube-scheduler 按资源、污点与亲和性把 Pod 放到合适的节点上，Pending 多半卡在这一步；只在「kube-scheduler 按资源、污点与亲和性把 Pod 放到合适的节点上，Pending 多半卡在这一步」这一前提下成立，换输入或换环境要重新验证。
- 使用 `Pod` 时，先满足它的定义：Kubernetes 最小调度单元，包含一个或多个共享网络与存储的容器；易错：`kubectl describe pod` 看 Events；正确做法是资源不足、节点选择器/污点不匹配、PVC 未绑定。

## 代码/协议/SQL 示例

**教材衔接：它解决什么问题**

Docker 解决了「怎么打包与运行单个容器」，Kubernetes（K8s）解决**集群级别的编排**：调度、扩缩容、自愈、滚动发布、服务发现与配置管理。

```text
期望状态（YAML 声明） -> 控制器持续对比实际状态 -> 不一致就自动纠正
```

这就是「声明式 API + 控制循环」：你描述想要什么，而不是一步步命令怎么做。

**教材衔接：一个最小 Deployment**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 3
  selector:
    matchLabels: { app: web }
  template:
    metadata:
      labels: { app: web }
    spec:
      containers:
        - name: web
          image: registry.example.com/web:1.2.0
          ports: [{ containerPort: 8080 }]
          envFrom:
            - configMapRef: { name: web-config }
          resources:
            requests: { cpu: "100m", memory: "128Mi" }
            limits: { cpu: "500m", memory: "512Mi" }
          readinessProbe:
            httpGet: { path: /healthz, port: 8080 }
          livenessProbe:
            httpGet: { path: /healthz, port: 8080 }
```

`requests` 影响调度，`limits` 影响超限行为；**探针配错会导致容器反复重启**——readiness 失败只是摘流量，liveness 失败会重启容器。

**教材衔接：常用命令**

```bash
kubectl apply -f deployment.yaml        # 声明式应用配置
kubectl get pods -o wide                 # 查看 Pod 与所在节点
kubectl describe pod web-xxx             # 排查调度/镜像/探针问题
kubectl logs -f web-xxx                  # 查看日志
kubectl exec -it web-xxx -- sh           # 进入容器
kubectl rollout status deploy/web        # 观察滚动更新
kubectl rollout undo deploy/web          # 回滚上一版本
kubectl scale deploy/web --replicas=5    # 手动扩缩容
kubectl port-forward svc/web 8080:80     # 本地调试
```

排查顺序：`get`（状态）→ `describe`（事件）→ `logs`（应用日志）。

**教材衔接：发布与流量**

```text
滚动更新 RollingUpdate：逐批替换，最常用，要求服务可同时跑多版本
蓝绿发布：新旧两套环境，切流量秒级回滚
金丝雀 Canary：先放 5% 流量观察指标，再逐步放大
```

配合 Service 的标签选择器与 Ingress 权重，就能用原生能力实现灰度。

**教材衔接：Service 与 Ingress 完整示例**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  selector: { app: web }        # 靠标签选中 Pod
  ports:
    - port: 80                  # Service 对外端口
      targetPort: 8080          # 容器实际监听端口
  type: ClusterIP               # 集群内访问；对外用 Ingress
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web
                port: { number: 80 }
```

三层关系：**Pod 提供能力 → Service 提供稳定入口 → Ingress 提供域名与路径路由**。Service 的 selector 必须与 Pod 的 labels 完全匹配，否则 endpoints 为空（表现为 503）。

**教材衔接：kubectl 常用命令速查**

| 目的 | 命令 |
| --- | --- |
| 查看资源列表 | `kubectl get pods -n prod -o wide` |
| 持续观察变化 | `kubectl get pods -w` |
| 查看详情与事件 | `kubectl describe pod <name>` |
| 查看日志 | `kubectl logs -f <pod> -c <container> --tail=200` |
| 查看上一次崩溃日志 | `kubectl logs <pod> --previous` |
| 进入容器 | `kubectl exec -it <pod> -- sh` |
| 端口转发 | `kubectl port-forward svc/api 8080:80` |
| 查看资源定义 | `kubectl get deploy api -o yaml` |
| 应用变更 | `kubectl apply -f deploy.yaml` |
| 删除资源 | `kubectl delete -f deploy.yaml` |
| 滚动重启 | `kubectl rollout restart deploy/api` |
| 查看发布状态 | `kubectl rollout status deploy/api` |
| 回滚 | `kubectl rollout undo deploy/api --to-revision=3` |
| 查看历史版本 | `kubectl rollout history deploy/api` |
| 查看资源占用 | `kubectl top pod` / `kubectl top node` |
| 查看事件（按时间） | `kubectl get events --sort-by=.lastTimestamp` |
| 查看节点标签 | `kubectl get nodes --show-labels` |
| 临时调试 | `kubectl run debug --rm -it --image=nicolaka/netshoot -- sh` |

**教材衔接：核心资源速查**

| 资源 | 作用 | 关键点 |
| --- | --- | --- |
| Pod | 最小调度单位 | 一般不直接创建，由控制器管理 |
| Deployment | 无状态应用 | 副本数、滚动更新、回滚 |
| StatefulSet | 有状态应用 | 稳定标识、顺序部署、配合 PVC |
| DaemonSet | 每节点一个 | 日志采集、监控代理 |
| Job / CronJob | 一次性 / 定时任务 | 注意并发策略与历史保留数 |
| Service | 稳定访问入口 | ClusterIP、NodePort、LoadBalancer、Headless |
| Ingress | 七层入口 | 域名与路径路由、TLS |
| ConfigMap / Secret | 配置与密钥 | 变更后需重启或滚动更新才生效 |
| PVC / StorageClass | 持久化存储 | 注意访问模式与回收策略 |
| HPA | 自动扩缩容 | 依赖资源 requests 与指标服务 |
| Namespace / RBAC | 隔离与权限 | 最小权限原则 |

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 3
  strategy:
    rollingUpdate: { maxSurge: 1, maxUnavailable: 0 }   # 先起新副本再停旧副本
  selector:
    matchLabels: { app: api }
  template:
    metadata:
      labels: { app: api }
    spec:
      containers:
        - name: api
          image: registry/api:1.0.3
          ports: [{ containerPort: 8080 }]
          resources:
            requests: { cpu: 200m, memory: 256Mi }      # 调度依据，必须设置
            limits: { cpu: "1", memory: 512Mi }
          readinessProbe:                                # 未就绪不接流量
            httpGet: { path: /healthz, port: 8080 }
            initialDelaySeconds: 5
          livenessProbe:                                 # 失败则重启容器
            httpGet: { path: /livez, port: 8080 }
            periodSeconds: 10
```

### 示例精读：先找证据，再改一个条件

1. 出现字面量 `100m`；它出现在 `Kubernetes 基础` 的示例中，阅读时先确认它前后各发生了什么。
2. 出现字面量 `128Mi`；它出现在 `Kubernetes 基础` 的示例中，阅读时先确认它前后各发生了什么。
3. 出现字面量 `500m`；它出现在 `Kubernetes 基础` 的示例中，阅读时先确认它前后各发生了什么。
4. 出现字面量 `512Mi`；它出现在 `Kubernetes 基础` 的示例中，阅读时先确认它前后各发生了什么。
- 在 `Kubernetes 基础` 中与 `requests` 对照：示例必须能支持 `requests` 影响调度，`limits` 影响超限行为；**探针配错会导致容器反复重启**——readiness 失败只是摘流量，liveness 失败会重启容器，否则说明这一段还缺少实现或验证步骤。
- 在 `Kubernetes 基础` 中与 `探针` 对照：示例必须能支持 liveness、readiness、startup 三种健康检查，配置不当会误杀容器或过早导入流量，否则说明这一段还缺少实现或验证步骤。
- 在 `Kubernetes 基础` 中与 `资源请求与限制` 对照：示例必须能支持 requests 决定调度时的预留量，limits 决定运行时的上限，两者共同决定 Pod 的服务质量等级，否则说明这一段还缺少实现或验证步骤。
- 在 `Kubernetes 基础` 中与 `调度` 对照：示例必须能支持 kube-scheduler 按资源、污点与亲和性把 Pod 放到合适的节点上，Pending 多半卡在这一步，否则说明这一段还缺少实现或验证步骤。

## 时间/空间复杂度或性能分析

**性能关注点（Kubernetes 基础）**：构建与流水线看总时长：记录构建耗时、缓存命中率与失败重试次数。

**本课特有开销（Kubernetes 基础 · Kubernetes）**：重试与超时会成倍放大尾延迟，记录 P99 而不是平均值。

**测量方法**：以 `Kubernetes 基础` 的 `Kubernetes` 场景为对象，固定输入跑一遍记录基线，再把规模或并发度提高一个数量级复测；两次结果的差值与波动范围才是结论依据。

### 需要控制的变量与记录项

- `Kubernetes 基础` 的 `Kubernetes`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Kubernetes 基础` 的 `Pod`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Kubernetes 基础` 的 `Deployment`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Kubernetes 基础` 的 `Service`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Kubernetes 基础` 的 `探针`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Kubernetes 基础` 中 `requests` 的边界：易错：只设置了 limits 没设 requests；正确做法是必须同时设置 requests。达到边界时不要外推，必须重新测量。
- `Kubernetes 基础` 中 `探针` 的边界：易错：`kubectl logs --previous`；正确做法是应用启动失败、配置缺失、探针过严。达到边界时不要外推，必须重新测量。
- `Kubernetes 基础` 中 `资源请求与限制` 的边界：只在「requests 决定调度时的预留量，limits 决定运行时的上限，两者共同决定 Pod 的服务质量等级」这一前提下成立，换输入或换环境要重新验证。达到边界时不要外推，必须重新测量。
- `Kubernetes 基础` 中 `调度` 的边界：只在「kube-scheduler 按资源、污点与亲和性把 Pod 放到合适的节点上，Pending 多半卡在这一步」这一前提下成立，换输入或换环境要重新验证。达到边界时不要外推，必须重新测量。
- `Kubernetes 基础` 中 `Pod` 的边界：易错：`kubectl describe pod` 看 Events；正确做法是资源不足、节点选择器/污点不匹配、PVC 未绑定。达到边界时不要外推，必须重新测量。
- `Kubernetes 基础` 的代码证据：先验证 出现字面量 `100m`，再记录该路径的输入规模与耗时；只看代码行数不能推出复杂度。

## 常见误区与易错点

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| Pod 一直 Pending | `kubectl describe pod` 看 Events | 资源不足、节点选择器/污点不匹配、PVC 未绑定 |
| ImagePullBackOff | `describe` 看拉取错误 | 镜像名/tag 写错、私有仓库缺 imagePullSecret |
| CrashLoopBackOff | `kubectl logs --previous` | 应用启动失败、配置缺失、探针过严 |
| Service 访问 503 | `kubectl get endpoints web` | selector 与 labels 不匹配，或 Pod 未 Ready |
| Ingress 404 | `kubectl describe ingress` | path/host 规则不匹配、ingressClassName 错误 |
| Pod 一直 `Pending` | 资源不足、节点选择器不匹配、PVC 未绑定 | `kubectl describe pod` 看事件 |
| Pod 反复 `CrashLoopBackOff` | 启动即崩溃、配置缺失、依赖不可用 | 看 `logs --previous` 与退出码 |
| Pod 一直 `ContainerCreating` | 镜像拉取慢、挂载失败 | `describe` 查看具体事件 |
| `ImagePullBackOff` | 镜像名错、私有仓库无凭据 | 检查名称与 `imagePullSecrets` |
| 服务 502 / 503 | 就绪探针失败、端口配置错误 | 检查 `readinessProbe` 与 Service 的 `targetPort` |
| `OOMKilled` | 内存超限 | 提高 limit 或修内存泄漏 |
| 资源使用率不高但扩容了 | 只设置了 limits 没设 requests | 必须同时设置 requests |
| 配置更新后没生效 | 环境变量只在启动时注入 | 重启 Pod（`rollout restart`） |
| 探针导致频繁重启 | 初始化慢而 liveness 过严 | 加 `startupProbe` 或放宽阈值 |
| 直接改 Pod | 重建后改动丢失 | 改 Deployment 等控制器资源 |
| 节点磁盘压力驱逐 Pod | 日志未轮转、镜像堆积 | 配置日志轮转与镜像清理 |
| Pod 反复 CrashLoopBackOff | 启动即崩溃、配置缺失、依赖不可用。 | 看 logs --previous 与退出码。 |
| Pod 一直 ContainerCreating | 镜像拉取慢、挂载失败。 | describe 查看具体事件。 |

### 现场 1：Pod 一直 Pending

**症状**：`kubectl describe pod` 看 Events。

**根因与修复**：资源不足、节点选择器/污点不匹配、PVC 未绑定。

**自检**：在本课示例里复现「Pod 一直 Pending」，改成资源不足、节点选择器/污点不匹配、PVC 未绑定后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 2：ImagePullBackOff

**症状**：`describe` 看拉取错误。

**根因与修复**：镜像名/tag 写错、私有仓库缺 imagePullSecret。

**自检**：在本课示例里复现「ImagePullBackOff」，改成镜像名/tag 写错、私有仓库缺 imagePullSecret后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 3：CrashLoopBackOff

**症状**：`kubectl logs --previous`。

**根因与修复**：应用启动失败、配置缺失、探针过严。

**自检**：在本课示例里复现「CrashLoopBackOff」，改成应用启动失败、配置缺失、探针过严后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 4：Service 访问 503

**症状**：`kubectl get endpoints web`。

**根因与修复**：selector 与 labels 不匹配，或 Pod 未 Ready。

**自检**：在本课示例里复现「Service 访问 503」，改成selector 与 labels 不匹配，或 Pod 未 Ready后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 5：Ingress 404

**症状**：`kubectl describe ingress`。

**根因与修复**：path/host 规则不匹配、ingressClassName 错误。

**自检**：在本课示例里复现「Ingress 404」，改成path/host 规则不匹配、ingressClassName 错误后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 6：Pod 一直 `Pending`

**症状**：资源不足、节点选择器不匹配、PVC 未绑定。

**根因与修复**：`kubectl describe pod` 看事件。

**自检**：在本课示例里复现「Pod 一直 `Pending`」，改成`kubectl describe pod` 看事件后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 7：Pod 反复 `CrashLoopBackOff`

**症状**：启动即崩溃、配置缺失、依赖不可用。

**根因与修复**：看 `logs --previous` 与退出码。

**自检**：在本课示例里复现「Pod 反复 `CrashLoopBackOff`」，改成看 `logs --previous` 与退出码后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 8：Pod 一直 `ContainerCreating`

**症状**：镜像拉取慢、挂载失败。

**根因与修复**：`describe` 查看具体事件。

**自检**：在本课示例里复现「Pod 一直 `ContainerCreating`」，改成`describe` 查看具体事件后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 9：`ImagePullBackOff`

**症状**：镜像名错、私有仓库无凭据。

**根因与修复**：检查名称与 `imagePullSecrets`。

**自检**：在本课示例里复现「`ImagePullBackOff`」，改成检查名称与 `imagePullSecrets`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

## 与其他知识点的关系

- **先修**：`CI/CD 与 GitHub Actions`。本课默认这些内容已经掌握。
- **相关或后续**：`可观测性：日志、指标与链路`、`图解 Kubernetes 调度与探针`。本课术语会在这些课程里继续使用。
- **术语归属**：`requests`、`探针`、`资源请求与限制` 的定义以本课「核心概念定义」为准，换到其他课程时先确认定义是否被改写。

### 先修与后续术语接口

- `CI/CD 与 GitHub Actions`：两者通过本分类的学习顺序衔接，阅读时重点比较各自的输入与失败条件。
- `可观测性：日志、指标与链路`：两者通过本分类的学习顺序衔接，阅读时重点比较各自的输入与失败条件。
- `图解 Kubernetes 调度与探针`：共享术语 `调度`、`探针`，共同关键词 `Kubernetes`、`探针`、`滚动更新`。

### 容易混淆的相邻概念

- `requests` 与 `探针`：前者强调 `requests` 影响调度，`limits` 影响超限行为；**探针配错会导致容器反复重启**——readiness 失败只是摘流量，liveness 失败会重启容器；后者强调 liveness、readiness、startup 三种健康检查，配置不当会误杀容器或过早导入流量。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `探针` 与 `资源请求与限制`：前者强调 liveness、readiness、startup 三种健康检查，配置不当会误杀容器或过早导入流量；后者强调 requests 决定调度时的预留量，limits 决定运行时的上限，两者共同决定 Pod 的服务质量等级。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `资源请求与限制` 与 `调度`：前者强调 requests 决定调度时的预留量，limits 决定运行时的上限，两者共同决定 Pod 的服务质量等级；后者强调 kube-scheduler 按资源、污点与亲和性把 Pod 放到合适的节点上，Pending 多半卡在这一步。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `调度` 与 `Pod`：前者强调 kube-scheduler 按资源、污点与亲和性把 Pod 放到合适的节点上，Pending 多半卡在这一步；后者强调 Kubernetes 最小调度单元，包含一个或多个共享网络与存储的容器。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。

## 自测题与参考答案

> 先独立作答，再对照参考答案；答案都能在本课正文、术语表或错误表里找到依据。

### 自测 1（概念复述）

不看正文，写出 `requests` 的操作性定义，并说明它与 `探针` 的区别。

**参考答案**：`requests` 影响调度，`limits` 影响超限行为；**探针配错会导致容器反复重启**——readiness 失败只是摘流量，liveness 失败会重启容器。

`探针` 的定位是：liveness、readiness、startup 三种健康检查，配置不当会误杀容器或过早导入流量；两者的差别要从适用对象与失败模式上说明。

### 自测 2（排错）

本课错误表记录了「Pod 一直 Pending」这类做法。请写出它会出现的现象、根因，以及修复顺序。

**参考答案**：现象是`kubectl describe pod` 看 Events；正确做法是资源不足、节点选择器/污点不匹配、PVC 未绑定。修复时先复现现象并保留证据，再改动一处假设重跑，确认现象消失。

### 自测 3（动手验证）

运行本课的 `text` 示例，改动其中一个输入后重新运行，记录输出与错误信息。

**参考答案**：正常输入下 `text` 示例应当复现正文给出的结果；改动输入后，如果结果改变或报错，先核对它是否满足 `Kubernetes 基础` 中`requests` 的适用范围，再检查错误表里是否有同类现象。

### 自测 4（代码阅读）

阅读本课开头的 `text` 示例，说明它体现了`requests` 的哪一条性质，并指出改动哪个输入会让这条性质不再成立。

**参考答案**：`requests` 的定义是 `requests` 影响调度，`limits` 影响超限行为，**探针配错会导致容器反复重启**——readiness 失败只是摘流量，liveness 失败会重启容器，示例正是在实现这条定义。改动与 `requests` 有关的一个输入后，如果结果不再符合 `Kubernetes 基础` 的正文描述，就说明该性质只在当前前提成立。

### 自测 5（迁移）

把 `Kubernetes 基础` 的方法迁移到自己的项目：围绕 `requests` 写出一个与错误表同类的风险点，并说明触发条件和检验方式。

**参考答案**：例如「Pod 一直 ContainerCreating」，它会导致镜像拉取慢、挂载失败；检验方式是按describe 查看具体事件改一处再复现，确认现象消失且没有引入新的失败分支。

### 自测 6（对比）

用一个表格对比 `requests` 与 `探针`：各写一行适用场景、一行失败表现。

**参考答案**：`requests` 的定义是`requests` 影响调度，`limits` 影响超限行为；**探针配错会导致容器反复重启**——readiness 失败只是摘流量，liveness 失败会重启容器；`探针` 的定义是liveness、readiness、startup 三种健康检查，配置不当会误杀容器或过早导入流量。两者的失败表现分别对应本课错误表里与本术语相关的行。

### 自测 7（排错顺序）

面对「Pod 一直 Pending」引发的问题，请把“复现 `kubectl describe pod` 看 Events → 保留证据 → 资源不足、节点选择器/污点不匹配、PVC 未绑定 → 回归验证”四步写成可执行的检查清单。

**参考答案**：第一步按`kubectl describe pod` 看 Events复现；第二步记录输入、版本与完整报错；第三步按资源不足、节点选择器/污点不匹配、PVC 未绑定只改一处；第四步重跑并确认失败路径也按预期变化。

### 自测 8（边界判断）

针对 `Pod`，分别写出“可以使用”的条件和“结论不再成立”的条件。

**参考答案**：易错：`kubectl describe pod` 看 Events；正确做法是资源不足、节点选择器/污点不匹配、PVC 未绑定。 同时要把 `Pod` 的定义 Kubernetes 最小调度单元，包含一个或多个共享网络与存储的容器 与实际输入逐项对照。

### 自测 9（机制重建）

不看正文，按输入、转换、输出、验证四段重建 `requests` → `探针` → `资源请求与限制` → `调度` 的作用链。

**参考答案**：起点是 `requests` 的定义 `requests` 影响调度，`limits` 影响超限行为；**探针配错会导致容器反复重启**——readiness 失败只是摘流量，liveness 失败会重启容器；中间每一步都保留可观察状态；终点由 `Pod` 检查，失败时回到错误表定位第一个偏离定义的步骤。

### 自测 10（综合排错）

在 `Kubernetes 基础` 中，现象是 镜像拉取慢、挂载失败。请围绕 Pod 一直 ContainerCreating 写出最小复现、关键证据、修复动作和回归验证，并说明为什么不能只凭一次运行下结论。

**参考答案**：先复现 Pod 一直 ContainerCreating，记录输入与完整错误；再按 describe 查看具体事件 只改一处。回归时同时跑正常路径和边界路径，只有两次结果都可解释，才把修复视为完成。

### 自测 11（一分钟复述）

用每分钟约 200 字的速度复述 `Kubernetes 基础`：先给主问题，再按顺序说出 `requests`、`探针`、`资源请求与限制`、`调度`，最后给一个失败案例。

**自评标准**：主问题必须对应 声明式对象模型、Deployment/Service、探针与发布策略；每个术语都要能接上一句定义或边界；失败案例必须写成可观察现象，不能用“可能有风险”代替证据。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `requests` | `requests` 影响调度，`limits` 影响超限行为；**探针配错会导致容器反复重启**——readiness 失败只是摘流量，liveness 失败会重启容器。 |
| `探针` | liveness、readiness、startup 三种健康检查，配置不当会误杀容器或过早导入流量。 |
| `资源请求与限制` | requests 决定调度时的预留量，limits 决定运行时的上限，两者共同决定 Pod 的服务质量等级。 |
| `调度` | kube-scheduler 按资源、污点与亲和性把 Pod 放到合适的节点上，Pending 多半卡在这一步。 |
| `Pod` | Kubernetes 最小调度单元，包含一个或多个共享网络与存储的容器。 |

**术语关系**：`requests`（`requests` 影响调度） → `探针`（liveness、readiness、startup 三种健康检查） → `资源请求与限制`（requests 决定调度时的预留量） → `调度`（kube-scheduler 按资源、污点与亲和性把 Pod 放到合适的节点上）。

## 考点精讲

`Kubernetes 基础` 的题库有 6 道题，下面逐题给出题干、正确项与判断依据：先自己作答，再核对正确项，最后回到正文对应小节复核。

### 考点 1：第 1 题

- **题目**：下面这段 `bash` 代码来自 `Kubernetes 基础`。课程主线是声明式对象模型、Deployment/Service、探针与发布策略。代码与 `requests` 有关。哪一项是代码里真实出现的内容？
- **正确项**：出现字面量 `512Mi`
- **判断依据**：这道题落在术语 `requests` 上：`requests` 影响调度，`limits` 影响超限行为，**探针配错会导致容器反复重启**——readiness 失败只是摘流量，liveness 失败会重启容器。复习时把 `requests` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 2：第 2 题

- **题目**：K8s 中最小的调度单位是？
- **正确项**：Pod
- **判断依据**：这道题落在术语 `调度` 上：kube-scheduler 按资源、污点与亲和性把 Pod 放到合适的节点上，Pending 多半卡在这一步。复习时把 `调度` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 3：第 3 题

- **题目**：围绕“Kubernetes 基础”中的 Kubernetes、Pod、Deployment，下列哪两项是本课强调的实践判断？
- **正确项**：学习 Kubernetes 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 Pod 时要固定版本并覆盖边界输入，结论才可复现
- **判断依据**：这道题落在术语 `Pod` 上：Kubernetes 最小调度单元，包含一个或多个共享网络与存储的容器。复习时把 `Pod` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 4：第 4 题

- **题目**：Deployment 与 StatefulSet 的区别是？
- **正确项**：Deployment 的 Pod 可互换
- **判断依据**：这道题落在术语 `Pod` 上：Kubernetes 最小调度单元，包含一个或多个共享网络与存储的容器。复习时把 `Pod` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 5：第 5 题

- **题目**：Kubernetes 中 Service 的作用是？
- **正确项**：为一组 Pod 提供稳定虚拟 IP 与负载均衡
- **判断依据**：这道题落在术语 `Pod` 上：Kubernetes 最小调度单元，包含一个或多个共享网络与存储的容器。复习时把 `Pod` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 6：第 6 题

- **题目**：填空：补齐下面这段术语说明中的空缺。课程 `声明式对象模型、Deployment/Service、探针与发布策略。`，这段说明是：``____`` 影响调度，`limits` 影响超限行为；**探针配错会导致容器反复重启**——readiness 失败只是摘流量，liveness 失败会重启容器。空缺处应填哪个术语？
- **正确项**：requests
- **判断依据**：这道题落在术语 `requests` 上：`requests` 影响调度，`limits` 影响超限行为，**探针配错会导致容器反复重启**——readiness 失败只是摘流量，liveness 失败会重启容器。复习时把 `requests` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 7：`requests`

- **要点**：`requests` 影响调度，`limits` 影响超限行为；**探针配错会导致容器反复重启**——readiness 失败只是摘流量，liveness 失败会重启容器。
- **requests 的边界**：易错：只设置了 limits 没设 requests；正确做法是必须同时设置 requests。

### 考点 8：`探针`

- **要点**：liveness、readiness、startup 三种健康检查，配置不当会误杀容器或过早导入流量。
- **探针 的边界**：易错：`kubectl logs --previous`；正确做法是应用启动失败、配置缺失、探针过严。

### 考点 9：`资源请求与限制`

- **要点**：requests 决定调度时的预留量，limits 决定运行时的上限，两者共同决定 Pod 的服务质量等级。
- **资源请求与限制 的边界**：只在「requests 决定调度时的预留量，limits 决定运行时的上限，两者共同决定 Pod 的服务质量等级」这一前提下成立，换输入或换环境要重新验证。

### 考点 10：`调度`

- **要点**：kube-scheduler 按资源、污点与亲和性把 Pod 放到合适的节点上，Pending 多半卡在这一步。
- **调度 的边界**：只在「kube-scheduler 按资源、污点与亲和性把 Pod 放到合适的节点上，Pending 多半卡在这一步」这一前提下成立，换输入或换环境要重新验证。

### 考点 11：`Pod`

- **要点**：Kubernetes 最小调度单元，包含一个或多个共享网络与存储的容器
- **Pod 的边界**：易错：`kubectl describe pod` 看 Events；正确做法是资源不足、节点选择器/污点不匹配、PVC 未绑定。

### 考点 12：排错——Pod 一直 Pending

- **现象**：`kubectl describe pod` 看 Events。
- **处理**：资源不足、节点选择器/污点不匹配、PVC 未绑定。

### 考点 13：排错——ImagePullBackOff

- **现象**：`describe` 看拉取错误。
- **处理**：镜像名/tag 写错、私有仓库缺 imagePullSecret。

### 考点 14：综合辨析——`requests` 与 `Pod`

- **辨析点**：`requests` 的定义是 `requests` 影响调度，`limits` 影响超限行为；**探针配错会导致容器反复重启**——readiness 失败只是摘流量，liveness 失败会重启容器；`Pod` 的定义是 Kubernetes 最小调度单元，包含一个或多个共享网络与存储的容器。
- **答题要求**：面对 `Kubernetes 基础` 的题目，先判断描述的是 `requests` 还是 `Pod`，再归到对应定义，最后写出一个会让该定义失效的边界输入。

### 考点 15：排错评分点

- **现象分**：能写出 `kubectl describe pod` 看 Events，而不是只写“程序有错”。
- **证据分**：保留触发 Pod 一直 Pending 的输入、版本和错误原文。
- **修复分**：按 资源不足、节点选择器/污点不匹配、PVC 未绑定 只改一处，并同时回归正常路径与边界路径。

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：高级
- 适用环境：Git / Docker / Kubernetes / CI 平台
；本课聚焦 Kubernetes。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Kubernetes、Pod、Deployment、Service、探针、滚动更新
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-08-24
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；本课核对关键词：Kubernetes、Pod、Deployment、Service、探针、滚动更新。

| 参考资料 | 本课用途 |
| --- | --- |
| [Kubernetes 文档](https://kubernetes.io/docs/) | 编排、服务与配置 |
| [CMake 文档](https://cmake.org/documentation/) | 跨平台构建与依赖 |
| [Git 文档](https://git-scm.com/doc) | 版本控制与分支模型 |

| [本课术语索引：Kubernetes 基础](#核心概念定义) | 按本课输入、术语边界和错误表现逐项核对 |
> 「Kubernetes 基础」的链接用于离线阅读后的延伸核对；App 不会自动联网。