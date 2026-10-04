## 常用模式速查

| 模式 | 解决问题 | 适用信号 |
| --- | --- | --- |
| 工厂方法 | 创建逻辑集中 | 构造函数分支变多 |
| 抽象工厂 | 一族相关对象的创建 | 多套实现需整体替换 |
| 建造者 | 复杂对象的组装 | 构造参数过多 |
| 单例 | 全局唯一实例 | 慎用，优先依赖注入 |
| 适配器 | 接口不兼容 | 对接第三方或遗留系统 |
| 装饰器 | 动态叠加能力 | 日志、缓存、鉴权等横切 |
| 代理 | 控制访问 | 懒加载、远程调用、权限 |
| 策略 | 算法可替换 | 大量 `if/else` 分支 |
| 观察者 | 状态变化通知 | 事件驱动、UI 更新 |
| 模板方法 | 固定流程、可变步骤 | 流程骨架复用 |
| 责任链 | 依次处理请求 | 中间件、审批流 |
| 状态机 | 状态与转移显式化 | 订单、工单流转 |

## SOLID 速查

| 原则 | 一句话 | 违反信号 |
| --- | --- | --- |
| 单一职责 | 一个类只有一个变化原因 | 一个类被多个需求频繁改动 |
| 开闭原则 | 对扩展开放、对修改关闭 | 新增类型要改大量分支 |
| 里氏替换 | 子类可替换父类且行为一致 | 子类抛异常或改变语义 |
| 接口隔离 | 接口小而专一 | 实现类被迫写空方法 |
| 依赖倒置 | 依赖抽象而非实现 | 高层直接 new 具体实现 |

```python
from abc import ABC, abstractmethod
from dataclasses import dataclass

# 策略模式：把分支判断换成可替换对象
class DiscountStrategy(ABC):
    @abstractmethod
    def apply(self, amount: float) -> float: ...

class NoDiscount(DiscountStrategy):
    def apply(self, amount: float) -> float:
        return amount

class VipDiscount(DiscountStrategy):
    def apply(self, amount: float) -> float:
        return round(amount * 0.8, 2)

class CouponDiscount(DiscountStrategy):
    def __init__(self, value: float):
        self.value = value

    def apply(self, amount: float) -> float:
        return max(0.0, amount - self.value)

@dataclass
class Order:
    amount: float
    strategy: DiscountStrategy

    def payable(self) -> float:
        return self.strategy.apply(self.amount)

# 依赖倒置：高层依赖抽象的通知接口
class Notifier(ABC):
    @abstractmethod
    def send(self, message: str) -> None: ...

class EmailNotifier(Notifier):
    def __init__(self):
        self.sent = []

    def send(self, message: str) -> None:
        self.sent.append(message)

class OrderService:
    def __init__(self, notifier: Notifier):
        self.notifier = notifier            # 注入而非内部 new

    def place(self, order: Order) -> float:
        total = order.payable()
        self.notifier.send(f"订单已创建，应付 {total}")
        return total

notifier = EmailNotifier()
service = OrderService(notifier)
print(service.place(Order(200, VipDiscount())), len(notifier.sent))
```

## 常见反模式速查

| 反模式 | 表现 | 后果 |
| --- | --- | --- |
| 上帝类 | 一个类几千行、职责混杂 | 难测试、易冲突 |
| 过度设计 | 为假想需求加抽象层 | 复杂度上升、交付变慢 |
| 撒手不管的单例 | 到处全局可变状态 | 测试困难、隐式耦合 |
| 复制粘贴 | 相似逻辑散落多处 | 改一处漏一处 |
| 贫血模型 | 只有 getter/setter | 业务逻辑散落服务层 |
| 隐式依赖 | 方法内部 new 具体实现 | 无法替换与测试 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 一开始就套用大量模式 | 代码晦涩、改动变慢 | 先写清晰实现，出现变化点再重构 |
| 用模式名当注释 | 看不出真实意图 | 命名体现业务语义 |
| 单例到处用 | 无法测试、状态互相影响 | 依赖注入替代 |
| 为复用强加继承 | 层级僵化 | 优先组合 |
| 接口膨胀 | 实现类写空方法 | 拆小接口 |
| 抽象层只为转发 | 无价值间接层 | 合并或延后抽象 |
| 忽略并发安全 | 单例下出现竞态 | 明确线程安全或改为无状态 |
| 模式滥用导致循环依赖 | 启动报错 | 明确依赖方向 |
| 不做单元测试 | 重构无安全网 | 行为测试先行 |
| 只追求设计模式数量 | 复杂度上升、收益不明 | 以可读性与可测试性为准 |

## 自测清单

- [ ] 能列出五个以上模式及适用信号。
- [ ] 能用策略模式替代大量条件分支。
- [ ] 依赖抽象、构造器注入，避免内部 new。
- [ ] 知道常见反模式及其后果。
- [ ] 抽象只在出现真实变化点时引入。
