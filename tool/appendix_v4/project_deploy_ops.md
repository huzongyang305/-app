## 补充：发布与回滚的落地细节

### 蓝绿与金丝雀的具体配置

```yaml
# 金丝雀：先给新版本 5% 流量
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "5"
spec:
  rules:
    - host: example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: app-canary
                port: { number: 80 }
```

```text
放量节奏建议
  5%  → 观察 10 分钟（错误率、P95、业务指标）
  25% → 观察 10 分钟
  50% → 观察 15 分钟
  100% → 观察 30 分钟
任何一步指标越界：立即把权重归零（比回滚镜像更快）
```

### 数据库变更的三种安全模式

| 模式 | 做法 | 适用 |
| --- | --- | --- |
| 扩展 | 先加新字段，双写，读旧字段 | 字段改名 |
| 收缩 | 停止写入旧字段，观察后再删除 | 清理历史字段 |
| 影子表 | 写入新表，后台比对，切换读 | 大表结构重构 |

```sql
-- 扩展阶段示例：新增字段并回填
ALTER TABLE orders ADD COLUMN status_v2 text;
UPDATE orders SET status_v2 = status WHERE status_v2 IS NULL;
-- 代码同时写两个字段，读仍走旧字段；确认无异常后再切读、最后删旧列
```

**原则：任何一次发布，数据库变更都要能在不丢数据的前提下回退。**

### 回滚演练：定期做，而不是等出事

```bash
#!/usr/bin/env bash
set -euo pipefail
# 回滚脚本骨架：切回上一个稳定镜像标签
readonly APP="myapp"
readonly PREVIOUS="$(cat /deploy/${APP}/previous_sha)"

echo "回滚 $APP → $PREVIOUS"
kubectl set image deployment/$APP app=registry.example.com/$APP:$PREVIOUS
kubectl rollout status deployment/$APP --timeout=120s
echo "回滚完成，请核对错误率与延迟"
```

| 演练项 | 目标 |
| --- | --- |
| 回滚耗时 | ≤ 1 分钟（应用层） |
| 回滚后指标 | 5 分钟内恢复基线 |
| 数据一致性 | 无丢单、无重复扣款 |
| 演练频率 | 每季度至少一次 |

### SLO 与错误预算

```text
先定 SLI（可测量）：请求成功率 = 2xx+3xx / 总请求
再定 SLO（目标）：30 天窗口内成功率 ≥ 99.9%
错误预算 = 1 - 99.9% = 0.1%

换算成可接受量：
  · 每月 100 万请求 → 可失败 1000 次
  · 预算未用完 → 可以继续快速发布
  · 预算用尽 → 冻结新功能，优先修复稳定性
```

| 用户可感知程度 | 建议 SLO |
| --- | --- |
| 核心交易链路 | 99.95% 以上 |
| 一般业务接口 | 99.9% |
| 内部工具 | 99.5% |

### 上线检查清单（命令级）

```text
发布前
□ 制品已打标签：docker images | grep <sha>
□ 数据库变更已评审并准备回滚脚本
□ 新配置项已在密钥服务中补齐
□ 新增接口已接入监控与告警

发布中
□ kubectl rollout status 无阻塞
□ 灰度 5% 观察 10 分钟
□ 关键业务指标无异常波动

发布后
□ 30 分钟观察窗结束
□ 记录变更内容、影响范围与回滚点
```

### 自查清单

- [ ] 每个服务都能在 1 分钟内回滚
- [ ] 数据库变更与代码发布分开进行
- [ ] 灰度期间固定观察错误率与 P95/P99
- [ ] SLO 有明确口径与统计窗口
- [ ] 每季度做过一次真实回滚演练

