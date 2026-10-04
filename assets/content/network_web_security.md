# Web 安全攻防

![Web 安全攻防](images/remaining_web_security.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：16 分钟

## 学习目标

- 能用自己的话解释「Web 安全攻防」解决了什么问题，而不是只背术语。
- 能说清 「Web 安全」、「XSS」、「CSRF」、「SQL 注入」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「网络」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：XSS/CSRF/SQL 注入/SSRF、会话安全与供应链。

## 前置知识

- 先完成上一课《Socket 编程实战》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：Web 安全、XSS、CSRF。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## OWASP 常见风险与防护

| 漏洞 | 原理 | 防护 |
| --- | --- | --- |
| XSS | 把脚本注入页面执行 | 输出转义、CSP、避免 innerHTML、HttpOnly Cookie |
| CSRF | 借用已登录身份发起请求 | SameSite Cookie、CSRF Token、校验 Origin |
| SQL 注入 | 拼接用户输入进 SQL | 参数化查询、最小权限、ORM 白名单 |
| SSRF | 诱导服务端请求内网地址 | 出站白名单、禁跳转、屏蔽元数据地址 |
| 越权 | 未校验资源归属 | 每次请求服务端鉴权、ID 不可枚举 |
| 文件上传 | 上传可执行脚本 | 类型白名单、重命名、存储与执行分离 |
| 反序列化 | 恶意数据触发对象构造 | 避免不可信数据反序列化、签名校验 |

## XSS 的三种形态

存储型（恶意内容入库，所有访问者中招）、反射型（通过链接参数回显）、DOM 型（前端 JS 直接把不可信数据写入 DOM）。防御核心是「**永不信任输入，按上下文转义输出**」，并配合 CSP 限制脚本来源。

## 认证与会话

1. 口令用 Argon2/bcrypt 加盐存储，禁止明文与可逆加密。
2. 会话 Cookie 设置 HttpOnly + Secure + SameSite。
3. 登录失败要限速与告警，支持多因素认证。
4. Token（JWT）要校验签名、过期与受众，不要放敏感数据在载荷里。
5. 注销与改密后要失效旧会话。

## 安全响应头

`Content-Security-Policy`（限制脚本来源）、`Strict-Transport-Security`（强制 HTTPS）、`X-Content-Type-Options: nosniff`、`Referrer-Policy`、`Permissions-Policy`。它们成本低、收益高，应作为基线配置。

## 供应链与依赖

第三方依赖是主要风险面：锁定版本与哈希、开启 SCA 扫描（Dependabot/Snyk）、审查新增依赖的维护活跃度、构建产物做签名与 SBOM 清单。

## 安全开发流程

威胁建模（识别资产与攻击面）→ 安全编码规范 → 代码审计与 SAST → DAST/渗透测试 → 上线前检查 → 运行时监控与应急响应。把安全左移，比出事后再补便宜得多。

## 本课小结
Web 安全的三条主线：**输入不可信（转义与参数化）、权限最小化（服务端逐次鉴权）、纵深防御（CSP + 头 + 扫描 + 监控）**。

<!-- appendix:v1 -->

## 漏洞与防护速查

| 漏洞 | 成因 | 防护 |
| --- | --- | --- |
| SQL 注入 | 拼接 SQL | 参数化查询、最小权限账号 |
| XSS | 未转义地插入用户输入 | 输出编码、CSP、`textContent` |
| CSRF | 浏览器自动携带凭证 | CSRF Token、SameSite Cookie、校验 Origin |
| SSRF | 服务端按用户输入请求地址 | 白名单、禁止访问内网段与元数据地址 |
| 越权（IDOR） | 只校验登录不校验归属 | 每次访问校验资源归属与角色 |
| 命令注入 | 拼接系统命令 | 避免 shell，用参数数组与白名单 |
| 路径穿越 | 拼接文件路径 | 规范化路径并校验前缀 |
| 反序列化 | 反序列化不可信数据 | 避免不可信数据反序列化，或严格白名单 |
| 文件上传 | 未校验类型与内容 | 白名单后缀、内容检测、重命名、隔离存储 |
| 敏感信息泄漏 | 日志与响应包含隐私 | 脱敏、最小返回字段 |

## 浏览器安全头速查

| 头部 | 作用 |
| --- | --- |
| `Content-Security-Policy` | 限制脚本与资源来源，缓解 XSS |
| `Strict-Transport-Security` | 强制后续使用 HTTPS |
| `X-Content-Type-Options: nosniff` | 禁止 MIME 嗅探 |
| `Referrer-Policy` | 控制 Referer 泄漏 |
| `Permissions-Policy` | 限制摄像头、定位等能力 |
| `X-Frame-Options` / `frame-ancestors` | 防点击劫持 |
| `Cross-Origin-Opener-Policy` | 隔离窗口上下文 |

Cookie 安全属性：

| 属性 | 作用 |
| --- | --- |
| `HttpOnly` | 禁止 JS 读取，缓解 XSS 窃取 |
| `Secure` | 仅通过 HTTPS 传输 |
| `SameSite=Lax` | 默认值，跨站 POST 不带 Cookie |
| `SameSite=Strict` | 最严格，跨站导航也不带 |
| `Path` / `Domain` | 限定作用范围，尽量收窄 |
| `Max-Age` / `Expires` | 控制有效期 |

```python
import html
import re
from urllib.parse import urlparse

ALLOWED_HOSTS = {"cdn.example.com", "api.example.com"}
PRIVATE_PREFIXES = ("10.", "192.168.", "172.16.", "127.", "169.254.")

def safe_html(user_input: str) -> str:
    """输出编码：把用户输入插入 HTML 前先转义。"""
    return html.escape(user_input, quote=True)


def safe_redirect_target(url: str) -> bool:
    """防开放重定向：只允许白名单域名。"""
    parsed = urlparse(url)
    return parsed.scheme in {"https"} and parsed.hostname in ALLOWED_HOSTS


def is_internal_address(url: str) -> bool:
    """SSRF 防护：识别是否指向内网或元数据地址。"""
    host = urlparse(url).hostname or ""
    if host in {"localhost", "metadata.google.internal"}:
        return True
    return host.startswith(PRIVATE_PREFIXES)


def sanitize_filename(name: str) -> str:
    """防路径穿越：只保留安全字符，去掉任何目录成分。"""
    cleaned = re.sub(r"[^A-Za-z0-9._-]", "_", name)
    cleaned = cleaned.lstrip(".") or "file"
    return cleaned[:100]


print(safe_html('<script>alert(1)</script>'))
print(safe_redirect_target("https://cdn.example.com/a.js"))
print(is_internal_address("http://169.254.169.254/latest/meta-data"))
print(sanitize_filename("../../etc/passwd"))
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用黑名单过滤输入 | 总有绕过方式 | 采用白名单 + 输出编码 |
| 只在客户端校验 | 直接调接口即可绕过 | 服务端必须独立校验 |
| 用 `innerHTML` 插值 | XSS | 用 `textContent` 或转义 |
| 同源策略当作授权 | 越权漏洞 | 每次请求校验资源归属 |
| Cookie 不带 `HttpOnly` | XSS 可窃取会话 | 会话 Cookie 加 `HttpOnly` + `Secure` + `SameSite` |
| CORS 设为 `*` 且带凭证 | 浏览器会拒绝或造成风险 | 明确来源白名单，避免通配加凭证 |
| 直接把用户 URL 拿去请求 | SSRF | 白名单 + 禁止内网地址 |
| 上传文件用原名存储 | 路径穿越或覆盖 | 重命名并隔离目录，禁止执行权限 |
| 错误信息返回堆栈 | 泄漏内部实现 | 生产只返回通用错误与追踪 ID |
| 无 CSP | XSS 影响扩大 | 配置 CSP 并逐步收紧 |

## 自测清单

- [ ] 后端对所有输入做白名单校验并对输出编码。
- [ ] 会话 Cookie 具备 `HttpOnly`、`Secure`、`SameSite`。
- [ ] 所有资源访问都校验归属权限（防越权）。
- [ ] 出站请求做 SSRF 防护（禁内网与元数据地址）。
- [ ] 配置了 CSP、HSTS 等安全响应头。

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「Web 安全、XSS、CSRF」完成复述、实验和交付，每个结果都要能被别人检查。

先抓一次真实请求或画出协议交互，再注入延迟或丢包，最后解释每层变化。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「Web 安全攻防」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「XSS」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

画出一张报文或时序图，标出每一跳的地址、协议、状态和可能失败点。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「Web 安全」和「XSS」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Web Security

**Summary:** XSS, CSRF, injection, sessions and supply chain.

**Category:** Networking  
**Level:** 进阶  
**Key terms:** Web 安全, XSS, CSRF, SQL 注入, CSP

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：TCP/IP、HTTP/2、HTTP/3 与现代网络栈
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Web 安全、XSS、CSRF、SQL 注入、CSP
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

<!-- top50-rewrite:v1 -->

## 课程专属精读：Web 安全攻防

### 一、知识地图

- **OWASP 常见风险与防护**：理解它的定义、输入、输出和失败边界。
- **XSS 的三种形态**：存储型（恶意内容入库，所有访问者中招）、反射型（通过链接参数回显）、DOM 型（前端 JS 直接把不可信数据写入 DOM）。防御核心是「**永不信任输入，按上下文转义输出**」，并配合 CSP 限制脚本来源。
- **认证与会话**：1. 口令用 Argon2/bcrypt 加盐存储，禁止明文与可逆加密。
- **安全响应头**：`Content-Security-Policy`（限制脚本来源）、`Strict-Transport-Security`（强制 HTTPS）、`X-Content-Type-Options: nosniff`、`Referrer-Policy`、`Permissions-Policy`。它们成本低、收益高，应作为基线配置。
- **供应链与依赖**：第三方依赖是主要风险面：锁定版本与哈希、开启 SCA 扫描（Dependabot/Snyk）、审查新增依赖的维护活跃度、构建产物做签名与 SBOM 清单。
- **安全开发流程**：威胁建模（识别资产与攻击面）→ 安全编码规范 → 代码审计与 SAST → DAST/渗透测试 → 上线前检查 → 运行时监控与应急响应。把安全左移，比出事后再补便宜得多。
- **漏洞与防护速查**：理解它的定义、输入、输出和失败边界。
- **浏览器安全头速查**：理解它的定义、输入、输出和失败边界。

### 二、机制与验证

| 主题 | 需要回答的问题 | 验证方式 |
| --- | --- | --- |
| OWASP 常见风险与防护 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| XSS 的三种形态 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 认证与会话 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 安全响应头 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 供应链与依赖 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 安全开发流程 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 漏洞与防护速查 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 浏览器安全头速查 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |

### 三、专属检查问题

1. OWASP 常见风险与防护 与相邻主题的边界是什么？
2. XSS 的三种形态 与相邻主题的边界是什么？
3. 认证与会话 与相邻主题的边界是什么？
4. 安全响应头 与相邻主题的边界是什么？
5. 供应链与依赖 与相邻主题的边界是什么？
6. 安全开发流程 与相邻主题的边界是什么？
7. 漏洞与防护速查 与相邻主题的边界是什么？
8. 浏览器安全头速查 与相邻主题的边界是什么？

### 四、故障排查

1. 固定输入和环境，确认问题能复现。
2. 找到第一个异常状态，不从最终错误倒猜。
3. 只改变一个变量，记录预测和真实结果。
4. 修复后补边界、失败和重复执行测试。

<!-- p2-references:v1 -->

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [RFC Editor](https://www.rfc-editor.org/) | 互联网协议标准 |
| [MDN HTTP](https://developer.mozilla.org/docs/Web/HTTP) | HTTP 语义与浏览器行为 |

> 本课主题：XSS/CSRF/SQL 注入/SSRF、会话安全与供应链。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

