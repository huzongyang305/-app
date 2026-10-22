## 数据划分速查

| 集合 | 用途 | 典型比例 |
| --- | --- | --- |
| 训练集 | 学习参数 | 60% 到 80% |
| 验证集 | 调参、早停、选模型 | 10% 到 20% |
| 测试集 | 最终评估（只用一次） | 10% 到 20% |

| 划分方式 | 适用 |
| --- | --- |
| 随机划分 | 样本独立同分布 |
| 时间划分 | 时序预测（用过去预测未来） |
| 分组划分 | 同一用户或设备的数据不能跨集合 |
| 分层划分 | 类别不平衡时保持比例 |
| K 折交叉验证 | 小数据集 |

## 评估指标速查

| 任务 | 常用指标 | 注意 |
| --- | --- | --- |
| 二分类 | 准确率、精确率、召回率、F1、AUC | 不平衡时准确率会误导 |
| 多分类 | 宏平均、微平均、混淆矩阵 | 关注少数类表现 |
| 回归 | MAE、RMSE、R² | RMSE 对大误差更敏感 |
| 排序 | NDCG、MRR、Recall@K | 关注前 K 位质量 |
| 生成 | 人工评分、BLEU/ROUGE、LLM 评审 | 自动指标与人类偏好常不一致 |

```python
def confusion_metrics(tp: int, fp: int, fn: int, tn: int) -> dict:
    """从混淆矩阵计算精确率、召回率与 F1。"""
    precision = tp / (tp + fp) if tp + fp else 0.0
    recall = tp / (tp + fn) if tp + fn else 0.0
    f1 = 2 * precision * recall / (precision + recall) if precision + recall else 0.0
    accuracy = (tp + tn) / (tp + fp + fn + tn)
    return {
        "precision": round(precision, 4),
        "recall": round(recall, 4),
        "f1": round(f1, 4),
        "accuracy": round(accuracy, 4),
    }


def time_split(records, time_key, ratio: float = 0.8):
    """按时间划分：过去训练、未来验证，避免时间穿越。"""
    ordered = sorted(records, key=lambda r: r[time_key])
    cut = int(len(ordered) * ratio)
    return ordered[:cut], ordered[cut:]


def check_leakage(train_ids: set, test_ids: set) -> set:
    """检查数据泄漏：同一实体同时出现在训练与测试集。"""
    return train_ids & test_ids


print(confusion_metrics(tp=80, fp=20, fn=10, tn=890))
print(check_leakage({"u1", "u2"}, {"u2", "u3"}))
```

## 过拟合与欠拟合速查

| 现象 | 训练集表现 | 验证集表现 | 对策 |
| --- | --- | --- | --- |
| 欠拟合 | 差 | 差 | 增大模型、加特征、训练更久 |
| 过拟合 | 好 | 差 | 加数据、正则化、早停、简化模型、数据增强 |
| 数据泄漏 | 异常好 | 线上骤降 | 检查特征是否含未来信息 |
| 分布漂移 | 训练好 | 线上逐渐变差 | 监控特征分布并定期重训 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用测试集反复调参 | 线上效果远低于预期 | 测试集只用一次，调参看验证集 |
| 类别不平衡只看准确率 | 指标虚高 | 看精确率、召回率、F1 与 AUC |
| 随机划分时序数据 | 指标虚高 | 按时间划分 |
| 同一用户跨训练与测试 | 数据泄漏 | 按用户分组划分 |
| 特征里含未来信息 | 线上暴跌 | 审查特征生成时间点 |
| 不做数据分布监控 | 漂移无人发现 | 监控特征与预测分布 |
| 只报告平均值 | 掩盖细分问题 | 按关键切片（地区、版本）分别看 |
| 忽略置信区间 | 小样本结论不稳 | 报告样本量与区间 |
| 样本量极少就下结论 | 结论随机 | 交叉验证并扩大样本 |
| 训练与推理特征处理不一致 | 线上效果差 | 复用同一特征管道 |

## 自测清单

- [ ] 训练、验证、测试集职责分明，测试集只用一次。
- [ ] 时序与分组数据使用对应划分方式。
- [ ] 类别不平衡时看精确率、召回率与 F1。
- [ ] 有数据泄漏检查与分布监控。
- [ ] 结论报告样本量、切片与不确定性。
