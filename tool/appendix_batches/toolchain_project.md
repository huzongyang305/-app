## 流水线阶段速查

| 阶段 | 目标 | 典型耗时 | 失败处理 |
| --- | --- | --- | --- |
| 静态检查 | 快速发现问题 | 秒级 | 阻断合并 |
| 单元测试 | 验证逻辑 | 分钟级 | 阻断合并 |
| 构建 | 产出不可变制品 | 分钟级 | 阻断 |
| 集成测试 | 验证组件协作 | 分钟级 | 阻断 |
| 安全扫描 | 依赖与密钥 | 分钟级 | 高危阻断 |
| 部署预发 | 环境验证 | 分钟级 | 阻断 |
| 灰度发布 | 小流量验证 | 分钟级到小时 | 自动回滚 |
| 全量发布 | 正式上线 | 分钟级 | 回滚 |

## 制品与配置速查

| 主题 | 做法 |
| --- | --- |
| 一次构建 | 各环境复用同一制品，避免重建引入差异 |
| 制品标识 | 使用提交 SHA 或语义化版本，可追溯 |
| 配置分离 | 环境差异通过配置注入，不重建 |
| 密钥 | 密钥管理服务注入，禁止写入制品与日志 |
| 依赖锁定 | 提交 lock 文件并用 `ci` 类安装命令 |
| 缓存 | 缓存键包含 lock 文件哈希 |
| 制品保留 | 明确保留策略与清理规则 |

```python
from dataclasses import dataclass, field
from enum import Enum

class Stage(Enum):
    LINT = "lint"
    TEST = "test"
    BUILD = "build"
    SECURITY = "security"
    DEPLOY_CANARY = "deploy_canary"
    DEPLOY_FULL = "deploy_full"

@dataclass
class StageResult:
    stage: Stage
    ok: bool
    duration_s: float
    detail: str = ""

@dataclass
class Pipeline:
    results: list = field(default_factory=list)

    def run_stage(self, stage: Stage, checker, **kwargs) -> StageResult:
        started = __import__("time").monotonic()
        try:
            ok, detail = checker(**kwargs)
        except Exception as exc:                  # 任何异常都视为失败
            ok, detail = False, str(exc)
        result = StageResult(stage, ok, round(__import__("time").monotonic() - started, 3), detail)
        self.results.append(result)
        return result

    def gate(self) -> tuple[bool, str]:
        """门禁：任一步失败即阻止继续。"""
        for result in self.results:
            if not result.ok:
                return False, f"{result.stage.value} 失败：{result.detail}"
        return True, "全部通过"

    def report(self) -> dict:
        return {
            "stages": [r.stage.value for r in self.results],
            "failed": [r.stage.value for r in self.results if not r.ok],
            "total_seconds": round(sum(r.duration_s for r in self.results), 3),
        }

def lint() -> tuple[bool, str]:
    return True, "无告警"

def high_severity_vulns() -> tuple[bool, str]:
    return False, "发现 1 个高危依赖漏洞"

pipeline = Pipeline()
pipeline.run_stage(Stage.LINT, lint)
pipeline.run_stage(Stage.SECURITY, high_severity_vulns)
print(pipeline.gate(), pipeline.report())
```

## 灰度与回滚速查

| 观察项 | 阈值示例 | 触发动作 |
| --- | --- | --- |
| 错误率 | 超过基线 0.5% | 立即回滚 |
| P95 延迟 | 超过基线 20% | 暂停放量 |
| 业务指标 | 转化率下降 5% | 暂停并人工确认 |
| 资源使用 | CPU 或内存接近上限 | 停止放量 |
| 日志异常 | 新增异常类型 | 告警并排查 |

回滚原则：**回滚要能一键完成、分钟级生效，并且回滚路径本身经过演练。**

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 每个环境重新构建 | 行为不一致 | 一次构建，多环境复用 |
| 缓存键不含 lock 哈希 | 用到过期依赖 | key 包含 lock 文件哈希 |
| CI 用 `install` 而非 `ci` | 依赖版本漂移 | 用锁文件严格安装 |
| 密钥打印到日志 | 泄漏 | 用密钥管理并遮蔽输出 |
| 安全扫描告警不阻断 | 漏洞上线 | 高危阻断、中低记录 |
| 无灰度直接全量 | 故障影响全站 | 灰度 + 自动回滚 |
| 回滚从未演练 | 真需要时失败 | 定期演练回滚 |
| 流水线过长 | 反馈慢、开发抵触 | 并行化 + 缓存 + 分层测试 |
| 制品无版本标识 | 无法追溯 | 用 SHA 或语义版本 |
| 制品不清理 | 存储成本上升 | 保留策略 + 定期清理 |

## 自测清单

- [ ] 流水线覆盖静态检查、测试、构建、安全与部署。
- [ ] 一次构建、多环境复用，制品可追溯。
- [ ] 密钥不落盘，缓存键含依赖锁哈希。
- [ ] 灰度有明确观察指标与自动回滚条件。
- [ ] 回滚路径定期演练。
