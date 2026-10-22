## 认证与授权速查

| 概念 | 含义 |
| --- | --- |
| 认证（AuthN） | 你是谁 |
| 授权（AuthZ） | 你能做什么 |
| 401 Unauthorized | 未认证或凭证失效 |
| 403 Forbidden | 已认证但无权限 |
| 会话 Cookie | 服务端保存状态，浏览器自动携带 |
| Token | 客户端持有凭证，服务端校验签名 |
| JWT | 自包含声明，注意无法主动失效 |

## OAuth 2.0 授权模式速查

| 模式 | 适用 | 说明 |
| --- | --- | --- |
| 授权码 + PKCE | 移动端、SPA、Web | 推荐默认选择 |
| 客户端凭证 | 服务间调用 | 无用户上下文 |
| 设备码 | 电视、CLI | 在另一设备完成授权 |
| 隐式模式 | 已废弃 | 令牌暴露在 URL |
| 密码模式 | 已废弃 | 直接传用户名口令 |

令牌使用速查：

| 令牌 | 生命周期 | 存放位置 |
| --- | --- | --- |
| access_token | 短（分钟级） | 内存，避免长期存储 |
| refresh_token | 长（天到月） | 安全存储，可吊销 |
| id_token | 短 | 前端解析用户信息（校验签名） |

```python
import base64
import hashlib
import hmac
import json
import secrets
import time

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def create_jwt(payload: dict, secret: bytes) -> str:
    """极简 JWT 生成（HS256）：生产请用成熟库。"""
    header = {"alg": "HS256", "typ": "JWT"}
    body = {**payload, "exp": int(time.time()) + 900, "iat": int(time.time())}
    segments = [
        b64url(json.dumps(header, separators=(",", ":")).encode()),
        b64url(json.dumps(body, separators=(",", ":")).encode()),
    ]
    signing_input = ".".join(segments).encode()
    signature = hmac.new(secret, signing_input, hashlib.sha256).digest()
    return ".".join(segments + [b64url(signature)])


def verify_jwt(token: str, secret: bytes, issuer: str) -> dict:
    """校验签名、有效期与签发者，任一不符即拒绝。"""
    try:
        header_b64, payload_b64, signature_b64 = token.split(".")
    except ValueError as exc:
        raise ValueError("令牌格式错误") from exc

    signing_input = f"{header_b64}.{payload_b64}".encode()
    expected = b64url(hmac.new(secret, signing_input, hashlib.sha256).digest())
    if not hmac.compare_digest(expected, signature_b64):
        raise ValueError("签名校验失败")

    payload = json.loads(base64.urlsafe_b64decode(payload_b64 + "=="))
    if payload.get("exp", 0) < time.time():
        raise ValueError("令牌已过期")
    if payload.get("iss") != issuer:
        raise ValueError("签发者不匹配")
    if "aud" not in payload:
        raise ValueError("缺少受众声明")
    return payload


def new_pkce_pair() -> tuple[str, str]:
    """PKCE：客户端生成 code_verifier 与对应的 challenge。"""
    verifier = secrets.token_urlsafe(64)
    challenge = b64url(hashlib.sha256(verifier.encode()).digest())
    return verifier, challenge


secret_key = b"demo-secret"
token = create_jwt({"sub": "user-1", "iss": "https://auth.example.com", "aud": "api"}, secret_key)
print(verify_jwt(token, secret_key, "https://auth.example.com")["sub"])
print(new_pkce_pair()[1][:16])
```

## 权限模型速查

| 模型 | 结构 | 适用 |
| --- | --- | --- |
| RBAC | 用户到角色到权限 | 大多数管理系统 |
| ABAC | 基于属性（部门、时间、地点） | 细粒度策略 |
| ReBAC | 基于关系（Google Zanzibar） | 文档与组织共享 |
| ACL | 每资源一张访问列表 | 简单共享场景 |

越权防护三层：**资源归属校验 + 角色权限校验 + 数据层过滤**（WHERE user_id = 当前用户）。

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 不校验 JWT 的 exp 与 aud | 过期或被错用的令牌有效 | 校验签名、exp、iss、aud 全部声明 |
| 用 JWT 存敏感数据 | 信息泄漏 | JWT 只含必要标识，敏感数据放服务端 |
| 只校验登录不校验归属 | 水平越权 | 每次访问校验资源归属 |
| access_token 有效期过长 | 泄漏影响面大 | 短过期 + refresh_token 轮换 |
| refresh_token 不可吊销 | 被盗后长期可用 | 支持吊销与轮换，检测重放 |
| 令牌放 localStorage | XSS 可窃取 | 优先 HttpOnly Cookie 或内存 |
| 到处用隐式模式 | 令牌出现在 URL | 用授权码 + PKCE |
| 密码明文或弱哈希 | 拖库即失守 | Argon2id + 随机盐 |
| 登录后不重置会话 ID | 会话固定攻击 | 登录成功后重新生成会话 |
| 权限判断散落各处 | 容易漏判 | 集中式鉴权中间件 + 数据层过滤 |

## 自测清单

- [ ] 分得清 401 与 403 的使用场景。
- [ ] 令牌校验覆盖签名、exp、iss、aud。
- [ ] 移动端与 SPA 使用授权码 + PKCE。
- [ ] 所有资源访问都校验归属（防水平越权）。
- [ ] 会话登录后重置，令牌可吊销并可轮换。
