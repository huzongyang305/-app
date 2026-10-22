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
