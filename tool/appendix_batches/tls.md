## 加密套件与握手速查

| 阶段 | 明文 / 加密 | 内容 |
| --- | --- | --- |
| ClientHello | 明文 | 支持的版本、密码套件、随机数、SNI |
| ServerHello + 证书 | 明文 | 选定套件、服务端随机数、证书链 |
| 密钥协商 | 非对称 / ECDHE | 双方计算共享密钥，支持前向保密 |
| Finished | 加密 | 校验握手完整性 |
| 应用数据 | 对称加密（AES-GCM / ChaCha20） | 真正传输业务数据 |

| 版本 | 特点 |
| --- | --- |
| TLS 1.2 | 支持广泛，握手 2-RTT，可配置 RSA 或 ECDHE |
| TLS 1.3 | 强制前向保密，握手 1-RTT，0-RTT 会话恢复，移除弱算法 |
| SSL 3.0 / TLS 1.0 / 1.1 | 已废弃，禁止在生产使用 |

证书要点：

| 项 | 说明 |
| --- | --- |
| 证书链 | 服务器应下发「中间证书 + 站点证书」，根证书预置在系统 |
| SNI | 一个 IP 部署多个 HTTPS 站点时靠 SNI 区分证书 |
| 通配符 | `*.example.com` 只匹配一级子域 |
| 有效期 | 越来越短，需自动续期（如 ACME） |
| 吊销 | CRL / OCSP，移动端兼容性差，通常靠短有效期 |

## 排查命令速查

| 目的 | 命令 |
| --- | --- |
| 查看证书与协议 | `openssl s_client -connect example.com:443 -servername example.com` |
| 查看有效期 | `openssl s_client -connect h:443 </dev/null 2>/dev/null \| openssl x509 -noout -dates` |
| 查看 SAN | `openssl x509 -noout -text \| grep -A1 "Subject Alternative Name"` |
| 测 TLS 版本支持 | `nmap --script ssl-enum-ciphers -p 443 host` |
| curl 详细握手 | `curl -vI https://example.com` |
| 检查链路与耗时 | `curl -w "%{time_connect} %{time_appconnect} %{time_total}\n" -o /dev/null -s https://example.com` |

## 常见错误对照表

| 现象 | 常见原因 | 处理方式 |
| --- | --- | --- |
| `certificate has expired` | 证书过期 | 配置自动续期并加到期告警 |
| `unable to get local issuer certificate` | 中间证书缺失或客户端信任库过旧 | 服务端下发完整链，客户端更新根证书 |
| 域名不匹配 | 证书 SAN 未包含访问域名 | 用正确的域名或补全 SAN |
| 只在部分客户端失败 | 客户端不支持所选套件或版本 | 兼容 TLS 1.2，检查加密套件顺序 |
| 抓包能看到明文 URL | TLS 只加密内容，域名与 SNI 仍可见 | 敏感信息不要放路径与查询串，或用 ECH |
| 混合内容告警 | HTTPS 页面加载 HTTP 资源 | 全部资源改用 HTTPS 或协议相对地址 |
| 证书私钥泄露 | 无法真正吊销 | 立即换证书与密钥，启用前向保密减少影响 |
| 自签证书用于生产 | 用户看到安全警告 | 使用受信任 CA，内网用私有 CA 并分发根证书 |
| 强制 HTTPS 后接口 502 | 回源仍走 HTTP 或端口不对 | 检查反向代理与回源配置 |

## 自测清单

- [ ] 能画出 TLS 1.3 的握手流程并说明 1-RTT 的含义。
- [ ] 知道对称加密保护数据、非对称用于密钥协商与身份验证。
- [ ] 会用 `openssl s_client` 检查证书链与有效期。
- [ ] 服务器下发完整证书链，并配置自动续期。
- [ ] 明白前向保密的价值与实现方式（ECDHE）。
