## 算法选型速查

| 用途 | 推荐算法 | 说明 |
| --- | --- | --- |
| 对称加密 | AES-256-GCM、ChaCha20-Poly1305 | 带认证（AEAD），首选 |
| 非对称加密 | RSA-OAEP、ECDH、X25519 | 一般只用于协商密钥 |
| 数字签名 | Ed25519、ECDSA P-256、RSA-PSS | 优先 Ed25519 |
| 哈希 | SHA-256、SHA-3、BLAKE3 | 禁止 MD5 与 SHA-1 |
| 口令存储 | Argon2id、scrypt、bcrypt | 必须加盐且慢哈希 |
| 消息认证 | HMAC-SHA256 | 共享密钥场景 |
| 密钥派生 | HKDF、PBKDF2 | 从主密钥派生多把子密钥 |

| 必须避免 | 原因 |
| --- | --- |
| MD5 / SHA-1 | 碰撞已被实际构造 |
| ECB 模式 | 相同明文块产生相同密文块 |
| 固定 IV / nonce | 严重削弱甚至完全破坏保密性 |
| 自创加密算法 | 未经审计，几乎必然有漏洞 |
| 明文存储口令 | 一旦泄漏即全部失守 |
| 用时间比较密钥 | 存在时序侧信道，用恒定时间比较 |

```python
import hashlib
import hmac
import os
from base64 import b64encode

# 口令存储：加盐 + 慢哈希（示例用 PBKDF2，生产优先 Argon2id）
def hash_password(password: str, iterations: int = 600_000) -> str:
    salt = os.urandom(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, iterations)
    return f"pbkdf2_sha256${iterations}${salt.hex()}${digest.hex()}"


def verify_password(password: str, stored: str) -> bool:
    algorithm, iterations, salt_hex, digest_hex = stored.split("$")
    if algorithm != "pbkdf2_sha256":
        raise ValueError("不支持的算法")
    digest = hashlib.pbkdf2_hmac(
        "sha256", password.encode(), bytes.fromhex(salt_hex), int(iterations)
    )
    # 恒定时间比较，避免时序泄漏
    return hmac.compare_digest(digest.hex(), digest_hex)


def encrypt_with_aead(key: bytes, plaintext: bytes, aad: bytes = b""):
    """AES-GCM 示意：随机 nonce + 认证标签（生产用成熟库）。"""
    from cryptography.hazmat.primitives.ciphers.aead import AESGCM

    nonce = os.urandom(12)                   # 每次加密必须唯一
    ciphertext = AESGCM(key).encrypt(nonce, plaintext, aad)
    return b64encode(nonce + ciphertext).decode()


print(hash_password("s3cret")[:32] + "...")
```

## 密钥管理速查

| 要点 | 做法 |
| --- | --- |
| 生成 | 使用密码学安全随机源（`os.urandom`、`secrets`） |
| 存储 | 密钥管理服务（KMS）或硬件模块，不入库不入镜像 |
| 轮换 | 定期轮换并支持新旧密钥并存过渡 |
| 权限 | 最小权限，按服务隔离 |
| 传输 | 通过安全通道，禁止明文粘贴到聊天工具 |
| 备份 | 加密备份并限制访问 |
| 审计 | 记录密钥的读取与使用 |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用 MD5 做口令哈希 | 可被彩虹表与碰撞攻击 | 用 Argon2id + 随机盐 |
| 自创加密算法 | 安全性无保障 | 用标准算法与成熟库 |
| 复用 IV / nonce | 密文可被分析出明文关系 | 每次加密使用唯一随机 nonce |
| 用 ECB 模式 | 相同块产生相同密文 | 用 GCM 或 CBC + HMAC |
| 加密但无完整性校验 | 密文可被篡改 | 用 AEAD（GCM、Poly1305） |
| 用 `==` 比较 MAC | 时序攻击可逐字节猜测 | 用恒定时间比较 |
| 认为哈希是加密 | 无法还原也算「加密」 | 哈希不可逆，用途完全不同 |
| 用 Base64 当加密 | 数据可被任何人解码 | Base64 只是编码 |
| 密钥写进代码或配置库 | 泄漏风险 | 用密钥管理服务与环境注入 |
| 忽略前向保密 | 长期密钥泄漏后历史流量全暴露 | 用 ECDHE 协商会话密钥 |

## 自测清单

- [ ] 口令存储使用加盐慢哈希（Argon2id 优先）。
- [ ] 对称加密使用 AEAD 并保证 nonce 唯一。
- [ ] 完整性校验用恒定时间比较。
- [ ] 密钥来自密钥管理服务且定期轮换。
- [ ] 不使用 MD5 / SHA-1 / ECB / 自创算法。
