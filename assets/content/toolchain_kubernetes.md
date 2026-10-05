# Kubernetes 基础

![Kubernetes 基础](images/category_kubernetes.webp)

> 内容更新时间：2026-10-03 · 学习阶段：高级 · 预计用时：17 分钟

## 学习目标

- 能用自己的话解释「Kubernetes 基础」解决了什么问题，而不是只背术语。
- 能说清 「Kubernetes」、「Pod」、「Deployment」、「Service」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「工具链」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：声明式对象模型、Deployment/Service、探针与发布策略。

## 前置知识

- 先完成上一课《CI/CD 与 GitHub Actions》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：高级。建议具备同一方向的完整基础，能阅读较长的代码、配置或系统设计说明。
- 开始前先复习：Kubernetes、Pod、Deployment。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 它解决什么问题

Docker 解决了「怎么打包与运行单个容器」，Kubernetes（K8s）解决**集群级别的编排**：调度、扩缩容、自愈、滚动发布、服务发现与配置管理。

```text
期望状态（YAML 声明） -> 控制器持续对比实际状态 -> 不一致就自动纠正
```

这就是「声明式 API + 控制循环」：你描述想要什么，而不是一步步命令怎么做。

## 核心对象

| 对象 | 作用 |
| --- | --- |
| Pod | 最小调度单位，包含一个或多个容器 |
| Deployment | 管理 Pod 副本数、滚动更新与回滚 |
| Service | 为一组 Pod 提供稳定访问入口与负载均衡 |
| Ingress | 七层入口，按域名/路径路由 |
| ConfigMap / Secret | 注入配置与密钥 |
| StatefulSet | 有状态服务（数据库），Pod 有稳定标识与存储 |
| Job / CronJob | 一次性任务与定时任务 |
| HPA | 按 CPU/自定义指标自动扩缩容 |

## 一个最小 Deployment

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

## 常用命令

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

## 发布与流量

```text
滚动更新 RollingUpdate：逐批替换，最常用，要求服务可同时跑多版本
蓝绿发布：新旧两套环境，切流量秒级回滚
金丝雀 Canary：先放 5% 流量观察指标，再逐步放大
```

配合 Service 的标签选择器与 Ingress 权重，就能用原生能力实现灰度。

## 什么时候不需要 K8s

1. 只有一两个服务、单机 Docker 足够时。
2. 团队没有运维能力，托管容器平台（Cloud Run、App Runner）更省心。
3. 需要极简部署的静态站点或小工具。

K8s 的复杂度是真实成本：集群、网络、存储、证书、监控都要有人负责。

## Service 与 Ingress 完整示例

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

## 五类常见故障与排错

| 现象 | 排查命令 | 常见原因 |
| --- | --- | --- |
| Pod 一直 Pending | `kubectl describe pod` 看 Events | 资源不足、节点选择器/污点不匹配、PVC 未绑定 |
| ImagePullBackOff | `describe` 看拉取错误 | 镜像名/tag 写错、私有仓库缺 imagePullSecret |
| CrashLoopBackOff | `kubectl logs --previous` | 应用启动失败、配置缺失、探针过严 |
| Service 访问 503 | `kubectl get endpoints web` | selector 与 labels 不匹配，或 Pod 未 Ready |
| Ingress 404 | `kubectl describe ingress` | path/host 规则不匹配、ingressClassName 错误 |

排错的黄金顺序：`get`（状态）→ `describe`（事件）→ `logs`（应用）→ `exec`（进容器验证）。

## 本课小结
K8s 的关键是**声明式 + 控制循环**：Pod 是最小单位，Deployment 管副本，Service 管访问，探针管健康，HPA 管弹性。先用好这五个，再扩展到存储与网络策略。


## kubectl 常用命令速查

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

## 核心资源速查

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

## 常见错误对照表

| 现象 | 常见原因 | 处理方式 |
| --- | --- | --- |
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

## 自测清单

- [ ] 会用 `get`、`describe`、`logs`、`exec` 四件套排查问题。
- [ ] 知道 readiness 与 liveness 探针的区别，并会设 `startupProbe`。
- [ ] 所有容器都设置了 requests 与 limits。
- [ ] 发布使用 `rollout status` 观察，必要时 `rollout undo` 回滚。
- [ ] 配置与密钥分离管理，敏感信息放 Secret。

## 动手练习


> 本课练习重点：围绕「Kubernetes、Pod、Deployment」完成复述、实验和交付，每个结果都要能被别人检查。

先在临时环境执行完整命令链，再模拟失败，最后验证回滚和清理。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「Kubernetes 基础」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「Pod」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

在一个临时目录或本地仓库执行完整命令链，并记录失败时的回滚办法。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「Kubernetes」和「Pod」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。


## 考点精讲：把测验题还原成判断过程

本课有 6 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：Kubernetes 的核心工作方式是？

- **正确判断**：声明期望状态
- **判断依据**：正确答案是「声明期望状态」，本课在「它解决什么问题」中说明：Docker 解决了「怎么打包与运行单个容器」，Kubernetes（K8s）解决集群级别的编排：调度、扩缩容、自愈、滚动发布、服务发现与配置管理。声明式 API + 控制循环是 K8s 的设计核心。本课还在「它解决什么问题」中说明：这就是「声明式 API + 控制循环」：你描述想要什么，而不是一步步命令怎么做。本课还在「一个最小 Deployment」中说明：探针配错会导致容器反复重启——readiness 失败只是摘流量，liveness 失败会重启容器。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 2：K8s 中最小的调度单位是？

- **正确判断**：Pod
- **判断依据**：Pod 可包含一个或多个共享网络与存储的容器。其他选项：Deployment 是工作负载控制器，Node 是运行机器，容器是最小运行单元但不是调度单位。针对「K8s 中最小的调度单位是，」，本课在「本课小结」中说明：K8s 的关键是声明式 + 控制循环：Pod 是最小单位，Deployment 管副本，Service 管访问，探针管健康，HPA 管弹性。本课还在「Service 与 Ingress 完整示例」中说明：三层关系：Pod 提供能力 → Service 提供稳定入口 → Ingress 提供域名与路径路由。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 3：readinessProbe 与 livenessProbe 的区别是？

- **正确判断**：readiness 失败摘除流量
- **判断依据**：正确答案是「readiness 失败摘除流量」，本课在「一个最小 Deployment」中说明：探针配错会导致容器反复重启——readiness 失败只是摘流量，liveness 失败会重启容器。配错探针会导致流量异常或容器反复重启，是常见故障源。本课还在「它解决什么问题」中说明：Docker 解决了「怎么打包与运行单个容器」，Kubernetes（K8s）解决集群级别的编排：调度、扩缩容、自愈、滚动发布、服务发现与配置管理。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 4：Deployment 与 StatefulSet 的区别是？

- **正确判断**：Deployment 的 Pod 可互换
- **判断依据**：正确答案是「Deployment 的 Pod 可互换」，本课在「什么时候不需要 K8s」中说明：K8s 的复杂度是真实成本：集群、网络、存储、证书、监控都要有人负责。数据库、消息队列等有状态组件通常用 StatefulSet 加 PVC。本课还在「Service 与 Ingress 完整示例」中说明：Service 的 selector 必须与 Pod 的 labels 完全匹配，否则 endpoints 为空（表现为 503）。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 5：Kubernetes 中 Service 的作用是？

- **正确判断**：为一组 Pod 提供稳定的虚拟 IP 与负载均衡，屏蔽 Pod 重建带来的地址变化
- **判断依据**：正确答案是「为一组 Pod 提供稳定的虚拟 IP 与负载均衡，屏蔽 Pod 重建带来的地址变化」，本课在「Service 与 Ingress 完整示例」中说明：三层关系：Pod 提供能力 → Service 提供稳定入口 → Ingress 提供域名与路径路由。ClusterIP、NodePort、LoadBalancer 与 Headless 是常见的几种 Service 形态。本课还在「五类常见故障与排错」中说明：排错的黄金顺序：get（状态）→ describe（事件）→ logs（应用）→ exec（进容器验证）。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 6：补全代码：「Kubernetes 基础」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `____: nginx`

- **正确判断**：ingressClassName / ingressclassname
- **判断依据**：正确答案是「ingressClassName」，这道题在问补全代码：Kubernetes基础示例中，下面这行代…请填入____，`____:nginx`，判断时要把题干限定的输入、边界与目标逐项对齐。本课示例中还能看到 `ingressClassName: nginx` 这样的用法，说明该关键字在本课代码中承担实际功能。
- **迁移检查**：如果填成相近的另一个函数或关键字，程序会在哪一步出错？

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「Kubernetes 的核心工作方式是？」的判断依据。
- [ ] 不看解析，能说出「K8s 中最小的调度单位是？」的判断依据。
- [ ] 不看解析，能说出「readinessProbe 与 livenessProbe 的区别是？」的判断依据。
- [ ] 不看解析，能说出「Deployment 与 StatefulSet 的区别是？」的判断依据。
- [ ] 不看解析，能说出「Kubernetes 中 Service 的作用是？」的判断依据。
- [ ] 不看解析，能说出「补全代码：「Kubernetes 基础」示例中，下面这行代码缺少哪个关键字或函数…」的判断依据。
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
| `requests` | `requests` 影响调度，`limits` 影响超限行为；**探针配错会导致容器反复重启**——readiness 失败只是摘流量，liveness 失败会重启容器。 |
| `limits` | `requests` 影响调度，`limits` 影响超限行为；**探针配错会导致容器反复重启**——readiness 失败只是摘流量，liveness 失败会重启容器。 |
| `get` | 排查顺序：`get`（状态）→ `describe`（事件）→ `logs`（应用日志）。 |
| `describe` | 排查顺序：`get`（状态）→ `describe`（事件）→ `logs`（应用日志）。 |
| `logs` | 排查顺序：`get`（状态）→ `describe`（事件）→ `logs`（应用日志）。 |
| `kubectl describe pod` | \| Pod 一直 Pending \| `kubectl describe pod` 看 Events \| 资源不足、节点选择器/污点不匹配、PVC 未绑定 \| |
| `kubectl logs --previous` | \| CrashLoopBackOff \| `kubectl logs --previous` \| 应用启动失败、配置缺失、探针过严 \| |
| `kubectl get endpoints web` | \| Service 访问 503 \| `kubectl get endpoints web` \| selector 与 labels 不匹配，或 Pod 未 Ready \| |
| `kubectl describe ingress` | \| Ingress 404 \| `kubectl describe ingress` \| path/host 规则不匹配、ingressClassName 错误 \| |
| `exec` | 排错的黄金顺序：`get`（状态）→ `describe`（事件）→ `logs`（应用）→ `exec`（进容器验证）。 |
| `kubectl get pods -n prod -o wide` | \| 查看资源列表 \| `kubectl get pods -n prod -o wide` \| |
| `kubectl get pods -w` | \| 持续观察变化 \| `kubectl get pods -w` \| |

## 面试问答与自测

下面把本课考点换成面试追问。先口述自己的答案，
再对照参考回答检查是否遗漏了前提、边界或失败路径。

### 追问 1：Kubernetes 的核心工作方式是？

**参考回答**：正确答案是「声明期望状态」，本课在「它解决什么问题」中说明：Docker 解决了「怎么打包与运行单个容器」，Kubernetes（K8s）解决集群级别的编排：调度、扩缩容、自愈、滚动发布、服务发现与配置管理。声明式 API + 控制循环是 K8s 的设计核心。本课还在「它解决什么问题」中说明：这就是「声明式 API + 控制循环」：你描述想要什么，而不是一步步命令怎么做。本课还在「一个最小 Deployment」中说明：探针配错会导致容器反复重启——readiness 失败只是摘流量，liveness 失败会重启容器。

### 追问 2：K8s 中最小的调度单位是？

**参考回答**：Pod 可包含一个或多个共享网络与存储的容器。其他选项：Deployment 是工作负载控制器，Node 是运行机器，容器是最小运行单元但不是调度单位。针对「K8s 中最小的调度单位是，」，本课在「本课小结」中说明：K8s 的关键是声明式 + 控制循环：Pod 是最小单位，Deployment 管副本，Service 管访问，探针管健康，HPA 管弹性。本课还在「Service 与 Ingress 完整示例」中说明：三层关系：Pod 提供能力 → Service 提供稳定入口 → Ingress 提供域名与路径路由。

### 追问 3：readinessProbe 与 livenessProbe 的区别是？

**参考回答**：正确答案是「readiness 失败摘除流量」，本课在「一个最小 Deployment」中说明：探针配错会导致容器反复重启——readiness 失败只是摘流量，liveness 失败会重启容器。配错探针会导致流量异常或容器反复重启，是常见故障源。本课还在「它解决什么问题」中说明：Docker 解决了「怎么打包与运行单个容器」，Kubernetes（K8s）解决集群级别的编排：调度、扩缩容、自愈、滚动发布、服务发现与配置管理。

### 追问 4：Deployment 与 StatefulSet 的区别是？

**参考回答**：正确答案是「Deployment 的 Pod 可互换」，本课在「什么时候不需要 K8s」中说明：K8s 的复杂度是真实成本：集群、网络、存储、证书、监控都要有人负责。数据库、消息队列等有状态组件通常用 StatefulSet 加 PVC。本课还在「Service 与 Ingress 完整示例」中说明：Service 的 selector 必须与 Pod 的 labels 完全匹配，否则 endpoints 为空（表现为 503）。

### 追问 5：Kubernetes 中 Service 的作用是？

**参考回答**：正确答案是「为一组 Pod 提供稳定的虚拟 IP 与负载均衡，屏蔽 Pod 重建带来的地址变化」，本课在「Service 与 Ingress 完整示例」中说明：三层关系：Pod 提供能力 → Service 提供稳定入口 → Ingress 提供域名与路径路由。ClusterIP、NodePort、LoadBalancer 与 Headless 是常见的几种 Service 形态。本课还在「五类常见故障与排错」中说明：排错的黄金顺序：get（状态）→ describe（事件）→ logs（应用）→ exec（进容器验证）。

## English Overview

**Title:** Kubernetes Basics

**Summary:** Declarative objects, workloads, probes and rollouts.

**Category:** Toolchain  
**Level:** 高级  
**Key terms:** Kubernetes, Pod, Deployment, Service, 探针, 滚动更新

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：高级
- 适用环境：Git / Docker / Kubernetes / CI 平台
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Kubernetes、Pod、Deployment、Service、探针、滚动更新
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [Git 文档](https://git-scm.com/doc) | 版本控制与协作 |
| [Docker 文档](https://docs.docker.com/) | 容器与镜像 |
| [Kubernetes 文档](https://kubernetes.io/docs/) | 编排与运维 |

> 本课主题：声明式对象模型、Deployment/Service、探针与发布策略。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。
