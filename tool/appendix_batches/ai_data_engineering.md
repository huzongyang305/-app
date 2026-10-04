## 数据流程速查

| 阶段 | 关键动作 | 常见问题 |
| --- | --- | --- |
| 采集 | 埋点、日志、业务库导出 | 字段缺失、时区不一致 |
| 清洗 | 去重、去噪、格式化 | 正则误伤、编码混乱 |
| 标注 | 人工或半自动打标 | 标准不一致、歧义样本 |
| 质检 | 抽检、一致性校验 | 抽样偏差 |
| 版本化 | 数据集快照与变更记录 | 无法复现旧实验 |
| 切分 | 训练、验证、测试隔离 | 数据泄漏 |
| 发布 | 打包与元数据登记 | 血缘缺失 |

## 标注质量速查

| 指标 | 说明 | 目标 |
| --- | --- | --- |
| 标注一致性（Kappa） | 多人标注的一致程度 | 大于 0.8 |
| 抽检准确率 | 抽样复核的正确比例 | 大于 95% |
| 歧义率 | 无法唯一判定的比例 | 越低越好，需修标准 |
| 覆盖度 | 各类别与边界样本覆盖 | 覆盖全部关键类别 |
| 返回率 | 打回重标的比例 | 用于监控标注方质量 |

质量控制手段：**标注手册 + 试标校准 + 双标交叉 + 抽检复核 + 定期对齐会**。

```python
import hashlib
from dataclasses import dataclass, field

def normalize(text: str) -> str:
    """标准化：去空白、统一大小写，用于近似去重与比对。"""
    return " ".join(text.strip().lower().split())


def content_hash(text: str) -> str:
    """精确去重指纹。"""
    return hashlib.sha256(normalize(text).encode("utf-8")).hexdigest()[:16]


def jaccard(a: set, b: set) -> float:
    """近似去重：按词集合计算 Jaccard 相似度。"""
    if not a or not b:
        return 0.0
    return len(a & b) / len(a | b)


@dataclass
class DataQualityReport:
    total: int
    duplicates: int = 0
    empty: int = 0
    too_long: int = 0
    pii_hits: int = 0
    label_distribution: dict = field(default_factory=dict)

    def pass_gate(self, max_duplicate_rate: float = 0.02) -> bool:
        """质量门禁：重复率、空样本与 PII 命中都要达标。"""
        duplicate_rate = self.duplicates / self.total if self.total else 0.0
        return (
            duplicate_rate <= max_duplicate_rate
            and self.empty == 0
            and self.pii_hits == 0
        )

    def summary(self) -> str:
        return (
            f"样本 {self.total}，重复 {self.duplicates}，空 {self.empty}，"
            f"超长 {self.too_long}，PII {self.pii_hits}"
        )


def mask_pii(text: str, patterns: dict) -> str:
    """PII 脱敏：按正则替换手机号、邮箱、身份证等。"""
    import re

    masked = text
    for name, pattern in patterns.items():
        masked = re.sub(pattern, f"[{name}]", masked)
    return masked


PII_PATTERNS = {
    "PHONE": r"1[3-9]\d{9}",
    "EMAIL": r"[\w.+-]+@[\w-]+\.[\w.]+",
    "ID": r"\d{17}[\dXx]",
}

print(content_hash("Hello   World"))
print(mask_pii("联系 13812345678 或 a@b.com", PII_PATTERNS))
print(DataQualityReport(total=1000, duplicates=10, pii_hits=0).pass_gate())
```

## 数据血缘速查

| 记录内容 | 用途 |
| --- | --- |
| 数据来源 | 追溯到原始系统与采集时间 |
| 处理链路 | 中间步骤与代码版本 |
| 输出去向 | 影响分析与通知下游 |
| 责任人 | 出问题找谁 |
| 质量指标 | 每步的校验结果 |
| 版本 | 支持复现与回滚 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 不做去重 | 模型记忆化、评测虚高 | 精确 + 近似去重 |
| 标注无手册 | 一致性差 | 先写手册并试标校准 |
| 只用单人标注 | 主观偏差 | 双标交叉 + 仲裁 |
| 抽检样本太少 | 质量结论不稳 | 按分层抽样并保证样本量 |
| 不脱敏直接入训练 | 合规风险 | PII 检测与脱敏 |
| 数据处理不进版本管理 | 实验无法复现 | 数据快照 + 代码版本 |
| 训练测试集泄漏 | 指标虚高 | 按实体与时间隔离 |
| 不做数据血缘 | 影响分析困难 | 记录来源、处理与去向 |
| 合成数据不做过滤 | 噪声与幻觉被放大 | 过滤低质合成样本并人工抽检 |
| 数据变更不通知下游 | 模型突然退化 | 变更登记与影响评估 |

## 自测清单

- [ ] 数据流程含采集、清洗、标注、质检、版本与切分。
- [ ] 标注有一致性指标与双标仲裁机制。
- [ ] 训练数据做精确与近似去重，并检测 PII。
- [ ] 数据快照与代码版本可复现实验。
- [ ] 血缘信息完整，变更能评估影响面。
