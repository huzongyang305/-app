## 需求类型速查

| 类型 | 例子 | 特点 |
| --- | --- | --- |
| 功能需求 | 用户可以下单 | 描述行为 |
| 非功能需求 | P95 延迟低于 200 毫秒 | 常决定架构 |
| 约束 | 必须使用现有数据库 | 限制实现选择 |
| 假设 | 用户量不会超过 10 万 | 需标注并验证 |

非功能需求维度：性能、可用性、安全、可维护性、成本、合规。

## 建模工具速查

| 图 | 表达什么 | 什么时候用 |
| --- | --- | --- |
| 用例图 | 角色与系统功能关系 | 对齐范围 |
| 类图 | 领域对象与关系 | 领域建模 |
| 时序图 | 一次调用的消息顺序 | 交互设计 |
| 活动图 | 业务流程分支 | 复杂流程 |
| 状态图 | 状态与迁移 | 订单、审批 |
| ER 图 | 数据实体与关系 | 数据库设计 |
| C4 图 | 系统与容器上下文 | 架构沟通 |

```python
from dataclasses import dataclass, field

@dataclass
class AcceptanceCriterion:
    given: str
    when: str
    then: str

    def text(self) -> str:
        return f"假如 {self.given}，当 {self.when}，那么 {self.then}"

@dataclass
class UserStory:
    role: str
    goal: str
    value: str
    criteria: list = field(default_factory=list)
    non_functional: list = field(default_factory=list)

    def statement(self) -> str:
        return f"作为{self.role}，我想要{self.goal}，以便{self.value}"

    def is_ready(self) -> tuple[bool, str]:
        """就绪检查：验收标准、非功能需求与规模是否明确。"""
        if not self.criteria:
            return False, "缺少验收标准"
        if not self.non_functional:
            return False, "缺少非功能需求（性能、安全等）"
        return True, "就绪"

@dataclass
class DecisionRecord:
    """ADR：记录决策背景与后果，避免反复推翻。"""

    title: str
    context: str
    decision: str
    consequences: list
    status: str = "accepted"

    def render(self) -> str:
        items = "\n".join(f"- {item}" for item in self.consequences)
        return (
            f"# {self.title}\n\n状态：{self.status}\n\n"
            f"背景：{self.context}\n\n决策：{self.decision}\n\n后果：\n{items}"
        )

story = UserStory(
    role="学习者",
    goal="离线查看教程",
    value="在地铁上也能学习",
    criteria=[AcceptanceCriterion("无网络", "打开教程", "内容正常显示")],
    non_functional=["首屏加载小于 1 秒"],
)
print(story.statement(), story.is_ready())
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 只有功能需求 | 上线后性能不达标 | 同步定义非功能需求与验收阈值 |
| 验收标准模糊 | 完成标准争议 | 用可断言的条件描述 |
| 一次写超长需求文档 | 没人阅读 | 小步迭代 + 图表 + ADR |
| 不记录假设 | 假设失效无人发现 | 显式列出并定期验证 |
| 不记录决策记录 | 反复推翻同一决策 | 写 ADR 并纳入版本管理 |
| 跳过建模直接编码 | 返工多 | 复杂逻辑先画时序或状态图 |
| 需求与测试脱节 | 漏测关键场景 | 验收标准直接转为测试用例 |
| 不做干系人对齐 | 上线后需求变化 | 关键角色评审确认 |
| 忽略合规与隐私 | 上线被拦 | 需求阶段纳入合规检查 |
| 文档写完不维护 | 与实际不符 | 与代码同仓更新 |

## 自测清单

- [ ] 用户故事有明确角色、目标、价值与验收标准。
- [ ] 非功能需求有可度量的阈值。
- [ ] 复杂逻辑用图表达（时序、状态、流程）。
- [ ] 关键决策有 ADR 记录背景与后果。
- [ ] 需求文档与代码同仓维护。
