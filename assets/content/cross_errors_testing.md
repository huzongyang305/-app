# 错误处理与测试：九种语言横向对照

![错误处理与测试：九种语言横向对照](images/category_cross_errors_testing.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：20 分钟

## 学习目标

- 能用自己的话解释「错误处理与测试：九种语言横向对照」解决了什么问题，而不是只背术语。
- 能说清 「错误处理」、「异常」、「Result」、「测试」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「跨语言对照」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：异常、返回值、Promise 三大流派，以及各语言主流测试框架。

## 前置知识

- 先完成上一课《并发写法：九种语言横向对照》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：错误处理、异常、Result。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 一句话目标

错误处理回答「出错时怎么表达」，测试回答「怎么证明它是对的」。
这两件事最能看出一门语言是否适合长期维护。

## 错误处理的三大流派

| 流派 | 代表语言 | 表达方式 | 特点 |
| --- | --- | --- | --- |
| 异常 | Python、Java、C#、C++ | `try / catch` 或 `except` | 代码干净，但容易漏捕获 |
| 返回值 | Go、Rust | 显式返回 `error` 或 `Result` | 不遗漏，但代码更啰嗦 |
| 回调与拒约 | JavaScript、TypeScript | `throw` + Promise 拒绝 | 异步容易漏处理 |
| 退出码 | Shell | `$?` 与 `set -e` | 只能表达成功或失败 |

## 一段代码看清差异

```python
def parse_age(text: str) -> int:
    value = int(text)              # 失败抛 ValueError
    if value < 0:
        raise ValueError("年龄不能为负")
    return value

try:
    print(parse_age("abc"))
except ValueError as err:
    print("出错：", err)
```

```javascript
function parseAge(text) {
  const value = Number(text);
  if (!Number.isInteger(value) || value < 0) {
    throw new Error(`年龄不合法：${text}`);
  }
  return value;
}

try {
  console.log(parseAge("abc"));
} catch (error) {
  console.error("出错：", error.message);
}

// 异步场景
await fetch(url).catch((e) => console.error(e));
```

```typescript
class ValidationError extends Error {
  constructor(readonly field: string, message: string) {
    super(message);
    this.name = "ValidationError";
  }
}

function parseAge(text: string): number {
  const value = Number(text);
  if (!Number.isInteger(value) || value < 0) {
    throw new ValidationError("age", `年龄不合法：${text}`);
  }
  return value;
}
```

```java
public static int parseAge(String text) {
    int value;
    try {
        value = Integer.parseInt(text.trim());
    } catch (NumberFormatException e) {
        throw new IllegalArgumentException("不是合法数字：" + text, e);   // 保留原因链
    }
    if (value < 0) throw new IllegalArgumentException("年龄不能为负");
    return value;
}
```

```csharp
public static bool TryParseAge(string text, out int age)
{
    age = 0;
    if (!int.TryParse(text, out var value) || value < 0) return false;
    age = value;
    return true;
}
```

```cpp
#include <optional>
#include <string>

std::optional<int> parseAge(const std::string& text) {
    try {
        int value = std::stoi(text);
        if (value < 0) return std::nullopt;
        return value;
    } catch (const std::exception&) {
        return std::nullopt;         // 用 optional 表达「没有有效值」
    }
}
```

```go
var ErrNegative = errors.New("年龄不能为负")

func ParseAge(text string) (int, error) {
    value, err := strconv.Atoi(strings.TrimSpace(text))
    if err != nil {
        return 0, fmt.Errorf("解析年龄 %q: %w", text, err)
    }
    if value < 0 {
        return 0, ErrNegative
    }
    return value, nil
}

// 调用方
age, err := ParseAge("abc")
if errors.Is(err, ErrNegative) { /* 按类型处理 */ }
```

```rust
#[derive(Debug)]
enum AgeError {
    NotANumber,
    Negative,
}

fn parse_age(text: &str) -> Result<u8, AgeError> {
    let value: i32 = text.trim().parse().map_err(|_| AgeError::NotANumber)?;
    if value < 0 {
        return Err(AgeError::Negative);
    }
    Ok(value as u8)
}
```

```bash
#!/usr/bin/env bash
set -euo pipefail

if ! [[ "$1" =~ ^[0-9]+$ ]]; then
  echo "年龄必须是数字：$1" >&2
  exit 1
fi
age="$1"
```

## 测试写法对照

| 语言 | 主流框架 | 最小测试写法 |
| --- | --- | --- |
| Python | pytest | `def test_x(): assert f() == 1` |
| JavaScript | Vitest / Jest | `it("x", () => expect(f()).toBe(1))` |
| TypeScript | Vitest | 同 JavaScript，另加类型断言 |
| Java | JUnit 5 | `@Test void x() { assertEquals(1, f()); }` |
| C# | xUnit | `[Fact] public void X() => Assert.Equal(1, F());` |
| C++ | Catch2 / GoogleTest | `TEST_CASE("x") { CHECK(f() == 1); }` |
| Go | 标准库 testing | `func TestX(t *testing.T) { ... }` |
| Rust | 内置 `#[test]` | `#[test] fn x() { assert_eq!(f(), 1); }` |
| Shell | bats | `@test "x" { [ "$(f)" = 1 ]; }` |

## 四类测试的共同分层

| 层级 | 目的 | 数量 |
| --- | --- | --- |
| 单元测试 | 验证纯函数与规则 | 最多 |
| 集成测试 | 验证模块与数据库配合 | 中等 |
| 端到端测试 | 验证关键用户流程 | 最少 |
| 性能测试 | 验证延迟与吞吐 | 按需 |

**跨语言通用的三条纪律**：用例相互独立、不依赖时间与网络、断言具体值而不是「不为空」。

## 新手最容易踩的八个坑

| 坑 | 出现语言 | 正确做法 |
| --- | --- | --- |
| 空 catch 什么都不做 | Java、C#、C++、Python | 至少记录或重新抛出 |
| 丢弃原始错误 | Java、Go、Python | 保留原因链（`%w`、`cause`） |
| 用字符串比较错误 | 全部 | 用错误类型或错误码 |
| 忽略 Promise 拒绝 | JavaScript、TypeScript | 加 `catch` 或 `try/catch` |
| 到处 `unwrap()` | Rust | 用 `?` 或 `unwrap_or` |
| 用异常做流程控制 | 全部 | 能用判断就用判断 |
| 测试依赖执行顺序 | 全部 | 每个用例自带准备与清理 |
| 只测成功路径 | 全部 | 补异常与边界用例 |

## 本课小结
- **异常流派**写起来最简洁，但要求开发者主动记得处理。
- **返回值流派**（Go、Rust）把「必须处理」写进语法，代价是代码更长。
- 无论哪种语言，**保留错误原因、用类型而不是文案判断、测试覆盖失败路径**这三条都成立。

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「错误处理、异常、Result」完成复述、实验和交付，每个结果都要能被别人检查。

用两种语言实现同一行为，再对比语法、错误、性能和生态差异。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「错误处理与测试：九种语言横向对照」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「异常」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

选两种语言实现同一行为，列出语法、错误处理、性能和生态差异。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「错误处理」和「异常」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Errors and Testing Across Languages

**Summary:** Exception, return-value and Promise styles plus testing frameworks.

**Category:** Cross-Language Comparison  
**Level:** 进阶  
**Key terms:** 错误处理, 异常, Result, 测试, 断言

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：九种主流语言生态横向对照
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：错误处理、异常、Result、测试、断言
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

<!-- top50-rewrite:v1 -->

## 课程专属精读：错误处理与测试：九种语言横向对照

### 一、知识地图

| 主题 | 核心要点 | 验证方式 |
| --- | --- | --- |
| 一句话目标 | 错误处理回答「出错时怎么表达」，测试回答「怎么证明它是对的」。 | 复述要点 + 举一个反例 |
| 错误处理的三大流派 | 流派：异常；代表语言：Python、Java、C#、C++；表达方式：try / catch 或 except | 复述要点 + 举一个反例 |
| 一段代码看清差异 | def parseage(text: str) -> int: value = int(text) # 失败抛 ValueError if value < 0: raise V… | 运行示例 + 换一个边界输入 |
| 测试写法对照 | 语言：Python；主流框架：pytest；最小测试写法：def testx(): assert f() == 1 | 复述要点 + 举一个反例 |
| 四类测试的共同分层 | 跨语言通用的三条纪律：用例相互独立、不依赖时间与网络、断言具体值而不是「不为空」。 | 复述要点 + 举一个反例 |
| 新手最容易踩的八个坑 | 坑：空 catch 什么都不做；出现语言：Java、C#、C++、Python；正确做法：至少记录或重新抛出 | 复述要点 + 举一个反例 |

### 二、机制与验证

1. **一句话目标**：错误处理回答「出错时怎么表达」，测试回答「怎么证明它是对的」。 验证方式：先复述要点，再举一个反例说明边界。
2. **错误处理的三大流派**：流派：异常；代表语言：Python、Java、C#、C++；表达方式：try / catch 或 except 验证方式：先复述要点，再举一个反例说明边界。
3. **一段代码看清差异**：def parseage(text: str) -> int: value = int(text) # 失败抛 ValueError if value < 0: raise V… 验证方式：先原样运行示例，再把输入换成边界值，对照输出差异。
4. **测试写法对照**：语言：Python；主流框架：pytest；最小测试写法：def testx(): assert f() == 1 验证方式：先复述要点，再举一个反例说明边界。
5. **四类测试的共同分层**：跨语言通用的三条纪律：用例相互独立、不依赖时间与网络、断言具体值而不是「不为空」。 验证方式：先复述要点，再举一个反例说明边界。
6. **新手最容易踩的八个坑**：坑：空 catch 什么都不做；出现语言：Java、C#、C++、Python；正确做法：至少记录或重新抛出 验证方式：先复述要点，再举一个反例说明边界。

### 三、专属检查问题

1. 「一句话目标」要解决什么问题？请用一句话说明，并给出一个具体例子。
2. 「错误处理的三大流派」的输入和输出分别是什么？
3. 「一段代码看清差异」最常见的失败方式是什么？如何定位？
4. 「测试写法对照」的适用边界在哪里？什么情况下不该使用？
5. 「四类测试的共同分层」和相邻主题相比，最关键的差别是什么？
6. 「新手最容易踩的八个坑」如何验证自己真的掌握了？写出一个可执行的检查步骤。

### 四、故障排查

1. 固定输入和环境，确认问题能稳定复现。
2. 找到第一个异常状态，不从最终错误倒推。
3. 每次只改一个变量，记录预测和真实结果。
4. 修复后补边界、失败与重复执行三类测试。

## 专属复习题库

**问：一句话目标的核心要点是什么？**

答：错误处理回答「出错时怎么表达」，测试回答「怎么证明它是对的」。

**问：错误处理的三大流派的核心要点是什么？**

答：流派：异常；代表语言：Python、Java、C#、C++；表达方式：try / catch 或 except

**问：一段代码看清差异的核心要点是什么？**

答：def parseage(text: str) -> int: value = int(text) # 失败抛 ValueError if value < 0: raise V…

**问：测试写法对照的核心要点是什么？**

答：语言：Python；主流框架：pytest；最小测试写法：def testx(): assert f() == 1

**问：四类测试的共同分层的核心要点是什么？**

答：跨语言通用的三条纪律：用例相互独立、不依赖时间与网络、断言具体值而不是「不为空」。

**问：新手最容易踩的八个坑的核心要点是什么？**

答：坑：空 catch 什么都不做；出现语言：Java、C#、C++、Python；正确做法：至少记录或重新抛出

## 逐步练习：错误处理与测试：九种语言横向对照

### 练习 1：一句话目标

1. 不看原文，用自己的话复述：错误处理回答「出错时怎么表达」，测试回答「怎么证明它是对的」。
2. 举一个正例和一个反例，说明边界在哪里。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 2：错误处理的三大流派

1. 不看原文，用自己的话复述：流派：异常；代表语言：Python、Java、C#、C++；表达方式：try / catch 或 except
2. 举一个正例和一个反例，说明边界在哪里。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 3：一段代码看清差异

1. 不看原文，用自己的话复述：def parseage(text: str) -> int: value = int(text) # 失败抛 ValueError if value < 0: raise V…
2. 跑通本课示例，再把其中一个输入换成边界值，记录输出差异。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 4：测试写法对照

1. 不看原文，用自己的话复述：语言：Python；主流框架：pytest；最小测试写法：def testx(): assert f() == 1
2. 举一个正例和一个反例，说明边界在哪里。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 5：四类测试的共同分层

1. 不看原文，用自己的话复述：跨语言通用的三条纪律：用例相互独立、不依赖时间与网络、断言具体值而不是「不为空」。
2. 举一个正例和一个反例，说明边界在哪里。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 6：新手最容易踩的八个坑

1. 不看原文，用自己的话复述：坑：空 catch 什么都不做；出现语言：Java、C#、C++、Python；正确做法：至少记录或重新抛出
2. 举一个正例和一个反例，说明边界在哪里。
3. 把结论写成两行笔记：一行结论，一行验证方式。

## 故障排查手册：错误处理与测试：九种语言横向对照

| 现象 | 优先检查 | 修复动作 |
| --- | --- | --- |
| 「一句话目标」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「错误处理的三大流派」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「一段代码看清差异」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「测试写法对照」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「四类测试的共同分层」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「新手最容易踩的八个坑」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |

## 自测与面试：错误处理与测试：九种语言横向对照

1. 「一句话目标」的输入和输出分别是什么？
2. 「错误处理的三大流派」最常见的失败方式是什么？如何定位？
3. 「一段代码看清差异」的适用边界在哪里？什么情况下不该使用？
4. 「测试写法对照」和相邻主题相比，最关键的差别是什么？
5. 「四类测试的共同分层」如何验证自己真的掌握了？写出一个可执行的检查步骤。
6. 「新手最容易踩的八个坑」要解决什么问题？请用一句话说明，并给出一个具体例子。

## 专属进阶任务 5：错误处理与测试：九种语言横向对照

把本课 6 个主题串成一个小练习：选其中一个主题做出可运行的例子，再为另外两个主题各写一条边界用例，最后用一句话说明你的验证结论。

### 验收标准

- 例子可以独立运行，输出与预期一致。
- 两条边界用例都说清了输入、预期与实际结果。
- 验证结论用一句话写清，不依赖“感觉正确”。

<!-- p2-references:v1 -->
## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [DevDocs](https://devdocs.io/) | 多语言 API 快速检索 |
| [官方语言文档](https://developer.mozilla.org/docs/Web) | 跨语言语义对照 |

> 本课主题：异常、返回值、Promise 三大流派，以及各语言主流测试框架。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

