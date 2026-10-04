## 使用流程速查

| 阶段 | 做法 | 目的 |
| --- | --- | --- |
| 明确任务 | 写清输入、输出与验收标准 | 减少来回澄清 |
| 提供上下文 | 相关文件、约定、报错原文 | 降低幻觉与猜测 |
| 小步生成 | 一次只改一小块 | 便于审查与回滚 |
| 立刻验证 | 编译、测试、静态检查 | 让机器证明正确性 |
| 人工审查 | 看边界条件、安全与风格 | 补足机器盲区 |
| 提交记录 | 说明改动与理由 | 便于追溯 |

## 上下文工程速查

| 内容 | 说明 |
| --- | --- |
| 项目约定 | 用 `AGENTS.md` 之类文件写明构建、测试、风格约束 |
| 相关代码 | 只给必要文件，避免整仓库塞入 |
| 接口契约 | 类型定义、Schema、示例请求响应 |
| 失败信息 | 完整报错与堆栈，而不是转述 |
| 约束 | 禁止改动哪些文件、必须保持哪些行为 |
| 输出要求 | 只给 diff、给完整文件，或给补丁说明 |

```python
import subprocess
from dataclasses import dataclass, field

@dataclass
class VerificationPipeline:
    """AI 生成代码的验证门禁：任一步失败即拒绝合入。"""

    steps: list = field(default_factory=list)
    results: list = field(default_factory=list)

    def add(self, name: str, command: list) -> "VerificationPipeline":
        self.steps.append((name, command))
        return self

    def run(self, cwd: str = ".") -> dict:
        for name, command in self.steps:
            proc = subprocess.run(command, cwd=cwd, capture_output=True, text=True)
            self.results.append({
                "name": name,
                "ok": proc.returncode == 0,
                "tail": (proc.stdout + proc.stderr).strip().splitlines()[-3:],
            })
            if proc.returncode != 0:
                break
        return {
            "passed": all(item["ok"] for item in self.results),
            "ran": len(self.results),
            "results": self.results,
        }


pipeline = (
    VerificationPipeline()
    .add("format", ["python", "-m", "ruff", "format", "--check", "."])
    .add("lint", ["python", "-m", "ruff", "check", "."])
    .add("types", ["python", "-m", "mypy", "."])
    .add("tests", ["python", "-m", "pytest", "-q"])
)
print(pipeline.run()["passed"])
```

## 常见风险速查

| 风险 | 现象 | 防护 |
| --- | --- | --- |
| 幻觉 API | 调用了不存在的函数或参数 | 编译 + 类型检查 + 文档核对 |
| 边界遗漏 | 空值、越界、并发未处理 | 补边界测试用例 |
| 安全问题 | 拼接 SQL、命令注入、密钥硬编码 | 安全审查与 SAST |
| 过度重构 | 顺带改动无关代码 | 限定改动范围并分次提交 |
| 许可证问题 | 复制了来源不明的代码 | 依赖与代码来源审查 |
| 测试造假 | 断言被改成永远通过 | 审查测试改动，禁止弱化断言 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 只看代码「像对的」 | 上线后运行时报错 | 必须编译并跑测试 |
| 让助手一次改很多文件 | 无法审查、难以回滚 | 小步提交，单次聚焦一个目标 |
| 不提供项目约定 | 风格与架构不符 | 写清 `AGENTS.md` 与既有模式 |
| 只贴报错摘要 | 助手猜错原因 | 给完整堆栈与复现步骤 |
| 允许助手改测试以通过 | 掩盖真实缺陷 | 测试改动需人工重点审查 |
| 直接让助手写生产密钥或配置 | 泄漏风险 | 密钥走密钥管理，禁止硬编码 |
| 不做安全检查 | 注入与越权进入代码 | 接入 SAST 与依赖扫描 |
| 不记录提示与产出 | 无法复盘 | 关键改动保留对话与 diff |
| 无脑接受大范围重构 | 引入回归 | 重构与功能改动分开提交 |
| 依赖单一助手结论 | 盲区无人发现 | 关键逻辑人工复核或交叉验证 |

## 自测清单

- [ ] 每次使用都提供明确验收标准与相关上下文。
- [ ] 生成代码必须过编译、lint、类型检查与测试。
- [ ] 测试改动会被重点审查，不允许弱化断言。
- [ ] 改动范围可控，可回滚，可分次提交。
- [ ] 接入安全检查，密钥永不进入代码。
