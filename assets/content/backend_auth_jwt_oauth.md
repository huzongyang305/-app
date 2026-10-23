# 认证授权（JWT/OAuth2）

![认证授权（JWT/OAuth2）示意：remaining csharp ecosystem](images/remaining_csharp_ecosystem.webp)

## 本章摘要

本章将深入探讨现代Web应用中的身份认证与权限管理机制。你将理解认证（Authentication，验证你是谁）与授权（Authorization，确定你能做什么）的本质区别，掌握JWT（JSON Web Token）的结构、签名原理及最佳实践，学习OAuth2的四种核心授权流程及其适用场景。我们还会对比基于会话（Session）和基于令牌（Token）两种认证方式的优劣，实现基于角色的访问控制（RBAC）模型，并讨论常见的安全陷阱与防御策略。通过实际代码示例，你将能够为自己的应用构建安全可靠的身份管理系统，保护用户数据免受未授权访问。无论是构建简单的博客平台还是复杂的企业级SaaS系统，这些知识都将成为你的安全基石。

---

## 7.1 认证 vs 授权：两个关键概念的区别

### 生活中的类比

想象你去参加一个高端会议：

**认证（Authentication）**就像是在入口处出示身份证和邀请函，保安确认"你确实是张三，并且确实被邀请参加这次会议"。这个过程回答的问题是：**你是谁？**

**授权（Authorization）**则是进入会场后，你的胸牌颜色决定了你能去哪些区域：普通参会者只能进入主会场，VIP可以进入休息室，演讲者可以进入后台准备区。这个过程回答的问题是：**你能做什么？**

### 技术定义

| 概念 | 英文 | 核心问题 | 常见实现 |
|------|------|---------|---------|
| 认证 | Authentication | Who are you? | 用户名密码、短信验证码、生物识别、OAuth登录 |
| 授权 | Authorization | What can you do? | RBAC角色权限、ABAC属性权限、ACL访问控制列表 |

**重要关系**：认证是授权的前提。你必须先证明自己的身份，系统才能决定给你什么权限。但认证成功并不意味着拥有所有权限——你可能只是普通用户而非管理员。

### 认证方式演进

**第一代：用户名+密码**
```javascript
// 最基础的认证方式
const user = await db.query(
  'SELECT * FROM users WHERE username = ? AND password = ?',
  [username, password]
);
```
问题：密码明文存储、容易被暴力破解、无法防止重放攻击。

**第二代：哈希密码+盐值**
```javascript
const bcrypt = require('bcrypt');

// 注册时
const saltRounds = 10;
const hashedPassword = await bcrypt.hash(plainPassword, saltRounds);
await db.insert('users', { username, password_hash: hashedPassword });

// 登录时
const user = await db.query('SELECT * FROM users WHERE username = ?', [username]);
const isValid = await bcrypt.compare(plainPassword, user.password_hash);
```
改进：即使数据库泄露，攻击者也无法直接获取明文密码。

**第三代：多因素认证（MFA）**
```javascript
// 1. 验证密码
const isValidPassword = await verifyPassword(username, password);
if (!isValidPassword) throw new Error('密码错误');

// 2. 发送验证码到手机
const code = generateVerificationCode();
await sendSMS(user.phone, code);
await cache.set(`mfa:${user.id}`, code, 300); // 5分钟过期

// 3. 用户输入验证码后验证
const storedCode = await cache.get(`mfa:${user.id}`);
if (inputCode !== storedCode) throw new Error('验证码错误');

// 4. 认证成功后生成令牌
const token = generateJWT(user);
```
安全性大幅提升：即使密码泄露，攻击者还需要控制用户的手机。

**第四代：无密码登录（Passwordless）**
- 邮箱魔术链接（Magic Link）
- 短信验证码
- WebAuthn（指纹/面部识别）
- 硬件密钥（YubiKey）

---

## 7.2 JWT详解：结构与签名原理

### 什么是JWT？

JWT（JSON Web Token）是一种开放标准（RFC 7519），用于在各方之间安全地传输信息。它特别适合在无状态的HTTP协议中实现认证，因为令牌本身包含了所有必要信息，服务器无需查询数据库即可验证用户身份。

**JWT的三个组成部分**：

```text
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

这个字符串由三部分组成，用`.`分隔：

1. **Header（头部）**：`eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9`
2. **Payload（载荷）**：`eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ`
3. **Signature（签名）**：`SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c`

### Header结构

Header包含两部分信息：令牌类型和签名算法。

```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

然后进行Base64Url编码：
```javascript
const header = { alg: 'HS256', typ: 'JWT' };
const encodedHeader = Buffer.from(JSON.stringify(header)).toString('base64url');
// 结果: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
```

**常用签名算法**：

| 算法 | 名称 | 特点 |
|------|------|------|
| HS256 | HMAC SHA-256 | 对称加密，使用单一密钥，速度快 |
| RS256 | RSA SHA-256 | 非对称加密，公钥验证，私钥签名 |
| ES256 | ECDSA SHA-256 | 椭圆曲线，密钥更短，性能更好 |
| PS256 | RSA-PSS SHA-256 | 更安全的RSA变种，推荐用于新系统 |

### Payload结构

Payload包含声明（Claims），分为三类：

**注册声明（Registered Claims）**：标准字段
```json
{
  "iss": "https://auth.example.com",    // issuer: 签发者
  "sub": "user_12345",                   // subject: 主题（用户ID）
  "aud": "https://api.example.com",      // audience: 受众
  "exp": 1704067200,                     // expiration time: 过期时间（Unix时间戳）
  "nbf": 1704063600,                     // not before: 生效时间
  "iat": 1704063600,                     // issued at: 签发时间
  "jti": "abc123def456"                  // JWT ID: 唯一标识符
}
```

**公共声明（Public Claims）**：自定义字段
```json
{
  "userId": "12345",
  "username": "alice",
  "role": "admin",
  "permissions": ["read", "write", "delete"]
}
```

**私有声明（Private Claims）**：双方约定的字段

**完整Payload示例**：
```json
{
  "sub": "user_12345",
  "username": "alice",
  "role": "editor",
  "permissions": ["post:create", "post:update"],
  "iat": 1704063600,
  "exp": 1704150000
}
```

Base64Url编码后得到第二部分。

### Signature签名

签名确保令牌未被篡改。使用Header中指定的算法对编码后的Header和Payload进行签名。

**HMAC SHA-256签名过程**：
```javascript
const crypto = require('crypto');

const secret = 'your-secret-key'; // 密钥，必须保密！
const encodedHeader = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
const encodedPayload = 'eyJzdWIiOiJ1c2VyXzEyMzQ1IiwidXNlcm5hbWUiOiJhbGljZSJ9';

const data = `${encodedHeader}.${encodedPayload}`;
const signature = crypto
  .createHmac('sha256', secret)
  .update(data)
  .digest('base64url');

console.log(signature); // SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

**验证签名**：
```javascript
// 接收方使用相同的密钥重新计算签名
const receivedSignature = 'SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
const calculatedSignature = crypto
  .createHmac('sha256', secret)
  .update(data)
  .digest('base64url');

if (receivedSignature === calculatedSignature) {
  console.log('✓ 令牌未被篡改');
} else {
  console.log('✗ 令牌已被篡改或密钥错误');
}
```

### JWT完整实现

**安装依赖**：
```bash
npm install jsonwebtoken bcryptjs
```

**生成JWT**：
```javascript
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

const JWT_SECRET = process.env.JWT_SECRET || 'your-super-secret-key-change-in-production';
const JWT_EXPIRES_IN = '24h';

async function login(username, password) {
  // 1. 验证用户凭据
  const user = await db.query('SELECT * FROM users WHERE username = ?', [username]);
  
  if (!user) {
    throw new Error('用户不存在');
  }
  
  const isValidPassword = await bcrypt.compare(password, user.password_hash);
  if (!isValidPassword) {
    throw new Error('密码错误');
  }
  
  // 2. 生成JWT
  const payload = {
    sub: user.id,
    username: user.username,
    role: user.role,
  };
  
  const token = jwt.sign(payload, JWT_SECRET, {
    expiresIn: JWT_EXPIRES_IN,
    issuer: 'https://auth.example.com',
    audience: 'https://api.example.com',
  });
  
  return {
    token,
    user: {
      id: user.id,
      username: user.username,
      role: user.role,
    },
  };
}
```

**验证JWT中间件**：
```javascript
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer <token>
  
  if (!token) {
    return res.status(401).json({ error: '缺少认证令牌' });
  }
  
  jwt.verify(token, JWT_SECRET, (err, decoded) => {
    if (err) {
      if (err.name === 'TokenExpiredError') {
        return res.status(401).json({ error: '令牌已过期' });
      }
      return res.status(403).json({ error: '无效的令牌' });
    }
    
    // 将用户信息附加到请求对象
    req.user = {
      id: decoded.sub,
      username: decoded.username,
      role: decoded.role,
    };
    
    next();
  });
}

// 使用中间件
app.get('/api/profile', authenticateToken, (req, res) => {
  res.json({
    message: `欢迎, ${req.user.username}!`,
    userId: req.user.id,
  });
});
```

**刷新令牌机制**：
```javascript
// 访问令牌（短期，15分钟）
const accessToken = jwt.sign(payload, JWT_SECRET, {
  expiresIn: '15m',
});

// 刷新令牌（长期，7天），存储在HttpOnly Cookie中
const refreshToken = jwt.sign(payload, JWT_REFRESH_SECRET, {
  expiresIn: '7d',
});

res.cookie('refreshToken', refreshToken, {
  httpOnly: true,
  secure: process.env.NODE_ENV === 'production',
  sameSite: 'strict',
  maxAge: 7 * 24 * 60 * 60 * 1000, // 7天
});

// 刷新端点
app.post('/api/auth/refresh', (req, res) => {
  const refreshToken = req.cookies.refreshToken;
  
  if (!refreshToken) {
    return res.status(401).json({ error: '缺少刷新令牌' });
  }
  
  jwt.verify(refreshToken, JWT_REFRESH_SECRET, (err, decoded) => {
    if (err) {
      return res.status(403).json({ error: '无效的刷新令牌' });
    }
    
    // 生成新的访问令牌
    const newAccessToken = jwt.sign(
      { sub: decoded.sub, username: decoded.username, role: decoded.role },
      JWT_SECRET,
      { expiresIn: '15m' }
    );
    
    res.json({ accessToken: newAccessToken });
  });
});
```

### JWT安全最佳实践

| 实践 | 说明 | 原因 |
|------|------|------|
| 使用强密钥 | 至少32字符的随机字符串 | 防止暴力破解 |
| 设置合理过期时间 | 访问令牌15-60分钟，刷新令牌7-30天 | 限制令牌泄露的影响窗口 |
| 不要存储敏感信息 | JWT不加密，仅Base64编码 | 任何人解码都能看到内容 |
| 使用HTTPS | 传输层加密 | 防止中间人攻击窃取令牌 |
| HttpOnly Cookie | 存储刷新令牌 | 防止XSS攻击读取Cookie |
| 令牌黑名单 | 登出时将令牌加入黑名单 | 实现主动失效机制 |
| 旋转密钥 | 定期更换签名密钥 | 降低密钥泄露风险 |

---

## 7.3 OAuth2授权流程详解

### 什么是OAuth2？

OAuth2是一个授权框架，允许第三方应用在用户授权的情况下访问受保护的资源，而无需获取用户的密码。

**生活类比**：OAuth2就像酒店的万能钥匙卡系统。你（资源所有者）告诉前台（授权服务器）："允许清洁工（客户端应用）进入我的房间（资源）打扫卫生（特定权限）"。清洁工拿到的是有时效、有权限限制的钥匙卡（访问令牌），而不是你的房卡密码（凭证）。

### OAuth2核心角色

1. **资源所有者（Resource Owner）**：用户本人
2. **客户端（Client）**：第三方应用（如微信登录的小程序）
3. **授权服务器（Authorization Server）**：颁发令牌的服务器（如Google、GitHub）
4. **资源服务器（Resource Server）**：存储用户数据的服务器（如Google API）

### OAuth2四种授权流程

#### 1. 授权码模式（Authorization Code）

**适用场景**：服务端应用（Confidential Client），最安全的流程

**流程图**：
```text
用户浏览器          客户端应用         授权服务器         资源服务器
    |                  |                  |                  |
    |--- 1.请求授权 --->|                  |                  |
    |                  |-- 2.重定向到授权 -->|                  |
    |<-- 3.显示登录页面 --|                  |                  |
    |--- 4.用户登录并授权 ---------------->|                  |
    |<-- 5.返回授权码 --------------------|                  |
    |                  |-- 6.用授权码换令牌 ->|                  |
    |                  |<-- 7.返回访问令牌 ---|                  |
    |                  |-- 8.用令牌请求数据 ------------------>|
    |                  |<-- 9.返回用户数据 --------------------|
```

**代码实现**：
```javascript
const axios = require('axios');
const crypto = require('crypto');

// 配置
const OAUTH_CONFIG = {
  clientId: process.env.GITHUB_CLIENT_ID,
  clientSecret: process.env.GITHUB_CLIENT_SECRET,
  authorizationUrl: 'https://github.com/login/oauth/authorize',
  tokenUrl: 'https://github.com/login/oauth/access_token',
  redirectUri: 'https://myapp.com/callback',
};

// 步骤1：生成授权URL
function getAuthorizationUrl() {
  const state = crypto.randomBytes(16).toString('hex'); // 防止CSRF
  const scope = 'user:email read:user';
  
  const params = new URLSearchParams({
    client_id: OAUTH_CONFIG.clientId,
    redirect_uri: OAUTH_CONFIG.redirectUri,
    scope: scope,
    state: state,
  });
  
  return `${OAUTH_CONFIG.authorizationUrl}?${params.toString()}`;
}

// 步骤2：处理回调，用授权码换取令牌
async function handleCallback(code, state) {
  // 验证state参数
  const storedState = getStateFromSession(state);
  if (state !== storedState) {
    throw new Error('Invalid state parameter');
  }
  
  // 交换授权码
  const response = await axios.post(OAUTH_CONFIG.tokenUrl, {
    client_id: OAUTH_CONFIG.clientId,
    client_secret: OAUTH_CONFIG.clientSecret,
    code: code,
    redirect_uri: OAUTH_CONFIG.redirectUri,
  }, {
    headers: {
      'Accept': 'application/json',
    },
  });
  
  const { access_token, token_type, expires_in, refresh_token } = response.data;
  
  // 使用访问令牌获取用户信息
  const userInfo = await axios.get('https://api.github.com/user', {
    headers: {
      'Authorization': `${token_type} ${access_token}`,
    },
  });
  
  return {
    accessToken: access_token,
    refreshToken: refresh_token,
    userInfo: userInfo.data,
  };
}

// Express路由
app.get('/auth/github', (req, res) => {
  const authUrl = getAuthorizationUrl();
  res.redirect(authUrl);
});

app.get('/auth/github/callback', async (req, res) => {
  try {
    const { code, state } = req.query;
    const result = await handleCallback(code, state);
    
    // 创建或更新本地用户
    const user = await findOrCreateUser(result.userInfo);
    
    // 生成本地JWT
    const localToken = jwt.sign(
      { sub: user.id, username: user.username },
      JWT_SECRET,
      { expiresIn: '24h' }
    );
    
    res.json({ token: localToken, user: result.userInfo });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});
```

#### 2. 客户端凭证模式（Client Credentials）

**适用场景**：机器对机器通信（M2M），无用户参与

```javascript
async function getClientCredentialsToken() {
  const response = await axios.post('https://auth.example.com/oauth/token', {
    grant_type: 'client_credentials',
    client_id: process.env.CLIENT_ID,
    client_secret: process.env.CLIENT_SECRET,
    scope: 'api:read api:write',
  });
  
  return response.data.access_token;
}

// 使用令牌调用API
const token = await getClientCredentialsToken();
const data = await axios.get('https://api.example.com/data', {
  headers: {
    'Authorization': `Bearer ${token}`,
  },
});
```

#### 3. 密码模式（Resource Owner Password Credentials）

**适用场景**：高度信任的第一方应用（已逐渐被淘汰，推荐使用授权码模式+PKCE）

```javascript
async function loginWithPassword(username, password) {
  const response = await axios.post('https://auth.example.com/oauth/token', {
    grant_type: 'password',
    username: username,
    password: password,
    client_id: process.env.CLIENT_ID,
    client_secret: process.env.CLIENT_SECRET,
  });
  
  return response.data;
}
```

#### 4. 隐式模式（Implicit）

**适用场景**：纯前端应用（已废弃，推荐使用授权码模式+PKCE）

由于安全性问题，OAuth 2.1已弃用此模式。现代SPA应使用授权码模式配合PKCE（Proof Key for Code Exchange）。

### PKCE增强安全性

PKCE用于保护授权码模式，防止授权码拦截攻击。

```javascript
// 生成code_verifier和code_challenge
function generatePKCE() {
  const codeVerifier = crypto.randomBytes(32).toString('base64url');
  
  const codeChallenge = crypto
    .createHash('sha256')
    .update(codeVerifier)
    .digest('base64url');
  
  return { codeVerifier, codeChallenge };
}

// 授权请求带上code_challenge
const { codeVerifier, codeChallenge } = generatePKCE();
storeCodeVerifierInSession(codeVerifier);

const authUrl = `${authorizationUrl}?${new URLSearchParams({
  client_id: clientId,
  redirect_uri: redirectUri,
  response_type: 'code',
  scope: scope,
  code_challenge: codeChallenge,
  code_challenge_method: 'S256',
})}`;

// 交换令牌时带上code_verifier
const tokenResponse = await axios.post(tokenUrl, {
  grant_type: 'authorization_code',
  code: authorizationCode,
  redirect_uri: redirectUri,
  client_id: clientId,
  code_verifier: codeVerifier, // 验证通过后才能换取令牌
});
```

---

## 7.4 Session-based vs Token-based认证

### 基于会话的认证（Session-based）

**工作原理**：
1. 用户登录后，服务器创建会话并存储在服务端（内存、Redis、数据库）
2. 服务器返回sessionId给客户端，通常存储在Cookie中
3. 后续请求自动携带Cookie，服务器通过sessionId查找会话数据

**Node.js + Express实现**：
```javascript
const session = require('express-session');
const RedisStore = require('connect-redis').default;
const Redis = require('ioredis');

const redisClient = new Redis();

app.use(session({
  store: new RedisStore({ client: redisClient }),
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: process.env.NODE_ENV === 'production',
    httpOnly: true,
    maxAge: 24 * 60 * 60 * 1000, // 24小时
  },
}));

// 登录
app.post('/login', async (req, res) => {
  const user = await validateCredentials(req.body.username, req.body.password);
  
  if (user) {
    req.session.userId = user.id;
    req.session.username = user.username;
    req.session.role = user.role;
    
    res.json({ message: '登录成功' });
  } else {
    res.status(401).json({ error: '凭据无效' });
  }
});

// 受保护的路由
app.get('/profile', (req, res) => {
  if (!req.session.userId) {
    return res.status(401).json({ error: '未登录' });
  }
  
  res.json({
    userId: req.session.userId,
    username: req.session.username,
  });
});

// 登出
app.post('/logout', (req, res) => {
  req.session.destroy((err) => {
    if (err) {
      return res.status(500).json({ error: '登出失败' });
    }
    res.clearCookie('connect.sid');
    res.json({ message: '已登出' });
  });
});
```

**优点**：
- 服务器可主动使会话失效（强制登出）
- 会话数据存储在服务器，客户端无法篡改
- 实现简单，成熟稳定

**缺点**：
- 需要维护会话存储（扩展性挑战）
- CSRF攻击风险（需额外防护）
- 不适合微服务架构（会话共享复杂）

### 基于令牌的认证（Token-based）

**工作原理**：
1. 用户登录后，服务器生成JWT并返回给客户端
2. 客户端存储令牌（LocalStorage、SessionStorage、Cookie）
3. 后续请求在Authorization头中携带令牌
4. 服务器验证令牌签名，无需查询数据库

**优点**：
- 无状态，易于水平扩展
- 跨域友好，适合微服务
- 客户端可选择存储方式

**缺点**：
- 令牌一旦签发，无法主动撤销（需黑名单机制）
- 令牌体积较大（相比sessionId）
- XSS攻击可能窃取令牌

### 对比总结

| 特性 | Session-based | Token-based (JWT) |
|------|--------------|-------------------|
| 存储位置 | 服务器端 | 客户端 |
| 扩展性 | 需要会话共享（Redis） | 天然无状态，易扩展 |
| 主动失效 | 简单（删除会话） | 复杂（需黑名单） |
| CSRF防护 | 需要额外措施 | 不受影响 |
| XSS风险 | 较低（HttpOnly Cookie） | 较高（若存LocalStorage） |
| 跨域支持 | 复杂（需CORS配置） | 简单（Authorization头） |
| 适用场景 | 单体应用、传统Web | SPA、移动App、微服务 |

### 混合方案：最佳实践

现代应用常采用混合方案：
- **访问令牌（JWT）**：短期有效，存储在内存中，用于API认证
- **刷新令牌**：长期有效，存储在HttpOnly Cookie中，用于获取新访问令牌
- **会话ID**：可选，用于服务端追踪用户活动

```javascript
// 登录响应
{
  "accessToken": "eyJhbGci...", // JWT，15分钟，存在内存
  "refreshToken": "httponly_cookie" // 7天，HttpOnly Cookie
}
```

---

## 7.5 基于角色的访问控制（RBAC）

### RBAC核心概念

RBAC（Role-Based Access Control）通过角色来管理权限，而非直接分配给用户。

**三层模型**：
1. **用户（User）**：系统的使用者
2. **角色（Role）**：权限的集合（如Admin、Editor、Viewer）
3. **权限（Permission）**：具体操作（如post:create、user:delete）

**关系**：用户 → 分配角色 → 角色包含权限

### 数据库设计

```sql
-- 角色表
CREATE TABLE roles (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) UNIQUE NOT NULL,
  description TEXT
);

-- 权限表
CREATE TABLE permissions (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL,
  description TEXT
);

-- 角色-权限关联表
CREATE TABLE role_permissions (
  role_id INTEGER REFERENCES roles(id) ON DELETE CASCADE,
  permission_id INTEGER REFERENCES permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);

-- 用户-角色关联表
CREATE TABLE user_roles (
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  role_id INTEGER REFERENCES roles(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, role_id)
);

-- 初始化数据
INSERT INTO roles (name, description) VALUES
  ('admin', '系统管理员，拥有所有权限'),
  ('editor', '编辑者，可以创建和修改内容'),
  ('viewer', '查看者，只能读取内容');

INSERT INTO permissions (name, description) VALUES
  ('post:create', '创建文章'),
  ('post:update', '更新文章'),
  ('post:delete', '删除文章'),
  ('post:publish', '发布文章'),
  ('user:read', '查看用户信息'),
  ('user:update', '更新用户信息'),
  ('user:delete', '删除用户');

-- 为角色分配权限
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'admin'; -- 管理员拥有所有权限

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'editor' 
  AND p.name IN ('post:create', 'post:update', 'post:publish');
```

### Node.js实现RBAC中间件

```javascript
class RBAC {
  constructor() {
    this.rolePermissions = new Map();
  }
  
  // 加载角色权限映射
  async loadPermissions() {
    const result = await db.query(`
      SELECT r.name as role, p.name as permission
      FROM roles r
      JOIN role_permissions rp ON r.id = rp.role_id
      JOIN permissions p ON rp.permission_id = p.id
    `);
    
    result.rows.forEach(row => {
      if (!this.rolePermissions.has(row.role)) {
        this.rolePermissions.set(row.role, new Set());
      }
      this.rolePermissions.get(row.role).add(row.permission);
    });
  }
  
  // 检查角色是否有权限
  hasPermission(role, permission) {
    const permissions = this.rolePermissions.get(role);
    return permissions ? permissions.has(permission) : false;
  }
  
  // 检查用户是否有权限
  async userHasPermission(userId, permission) {
    const roles = await db.query(`
      SELECT r.name FROM roles r
      JOIN user_roles ur ON r.id = ur.role_id
      WHERE ur.user_id = $1
    `, [userId]);
    
    return roles.rows.some(row => 
      this.hasPermission(row.name, permission)
    );
  }
}

const rbac = new RBAC();
await rbac.loadPermissions();

// 权限检查中间件
function requirePermission(permission) {
  return async (req, res, next) => {
    const userId = req.user.id;
    
    const hasPerm = await rbac.userHasPermission(userId, permission);
    
    if (!hasPerm) {
      return res.status(403).json({
        error: '权限不足',
        required: permission,
      });
    }
    
    next();
  };
}

// 使用示例
app.post('/api/posts', authenticateToken, requirePermission('post:create'), async (req, res) => {
  // 只有拥有post:create权限的用户才能执行
  const post = await createPost(req.body);
  res.status(201).json(post);
});

app.delete('/api/posts/:id', authenticateToken, requirePermission('post:delete'), async (req, res) => {
  await deletePost(req.params.id);
  res.json({ message: '文章已删除' });
});
```

### 动态权限检查

```javascript
// 基于资源的权限检查
async function canUserEditPost(userId, postId) {
  const post = await db.query('SELECT author_id FROM posts WHERE id = $1', [postId]);
  
  if (!post.rows.length) {
    return false;
  }
  
  // 作者本人或管理员可以编辑
  if (post.rows[0].author_id === userId) {
    return true;
  }
  
  return await rbac.userHasPermission(userId, 'post:update:any');
}

// 使用
app.put('/api/posts/:id', authenticateToken, async (req, res) => {
  const canEdit = await canUserEditPost(req.user.id, req.params.id);
  
  if (!canEdit) {
    return res.status(403).json({ error: '无权编辑此文章' });
  }
  
  const updated = await updatePost(req.params.id, req.body);
  res.json(updated);
});
```

---

## 7.6 安全最佳实践与常见攻击防御

### 常见安全陷阱对照表

| 陷阱 | 描述 | 后果 | 解决方案 |
|------|------|------|----------|
| JWT密钥泄露 | 硬编码密钥或使用弱密钥 | 攻击者可伪造任意令牌 | 使用环境变量，至少32字符随机密钥 |
| 令牌永不过期 | 未设置exp声明 | 令牌泄露后永久有效 | 设置合理过期时间，实现刷新机制 |
| 敏感信息存入JWT | 在payload中存储密码等 | Base64可轻松解码 | JWT只存非敏感标识，敏感数据查数据库 |
| 缺少CSRF防护 | Session认证未防护CSRF | 攻击者冒充用户执行操作 | 使用SameSite Cookie，添加CSRF Token |
| XSS窃取令牌 | 令牌存LocalStorage且无XSS防护 | 恶意脚本读取令牌 | 使用HttpOnly Cookie，实施CSP策略 |
| SQL注入 | 拼接用户输入到SQL | 数据泄露、提权 | 使用参数化查询或ORM |
| 暴力破解 | 无限次尝试登录 | 账户被攻破 | 限制登录频率，实施账户锁定 |
| 令牌重放 | 未绑定令牌到特定设备/IP | 令牌被盗后可重用 | 绑定设备指纹，使用一次性nonce |
| 过度权限 | 用户拥有不必要的高权限 | 内部威胁，误操作风险 | 遵循最小权限原则，定期审计 |
| 日志泄露令牌 | 记录中包含完整JWT | 日志泄露导致令牌暴露 | 脱敏日志，不记录Authorization头 |

### 防御策略

**1. 速率限制（Rate Limiting）**：
```javascript
const rateLimit = require('express-rate-limit');

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15分钟
  max: 5, // 最多5次尝试
  message: { error: '登录尝试次数过多，请稍后再试' },
  standardHeaders: true,
});

app.post('/login', loginLimiter, async (req, res) => {
  // 登录逻辑
});
```

**2. 密码策略**：
```javascript
function validatePassword(password) {
  const errors = [];
  
  if (password.length < 8) {
    errors.push('密码至少8个字符');
  }
  if (!/[A-Z]/.test(password)) {
    errors.push('密码必须包含大写字母');
  }
  if (!/[a-z]/.test(password)) {
    errors.push('密码必须包含小写字母');
  }
  if (!/[0-9]/.test(password)) {
    errors.push('密码必须包含数字');
  }
  if (!/[!@#$%^&*]/.test(password)) {
    errors.push('密码必须包含特殊字符');
  }
  
  return {
    valid: errors.length === 0,
    errors,
  };
}
```

**3. Content Security Policy（CSP）**：
```javascript
app.use((req, res, next) => {
  res.setHeader(
    'Content-Security-Policy',
    "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'"
  );
  next();
});
```

**4. 安全响应头**：
```javascript
const helmet = require('helmet');
app.use(helmet()); // 自动设置多种安全头
```

---

## 自我测试

### 问题1

关于JWT的结构，以下哪项描述是正确的？

A. JWT由四部分组成：Header、Payload、Signature和Salt  
B. JWT的Payload部分是加密的，只有持有密钥的人才能查看  
C. JWT的Signature部分用于验证令牌完整性，防止篡改  
D. JWT过期后会自动从客户端删除  

**正确答案：C**

**详细解释：** JWT的Signature（签名）是通过对Header和Payload进行哈希运算生成的，用于验证令牌在传输过程中是否被篡改。如果任何部分被修改，签名验证将失败。选项A错误，JWT只有三部分；选项B错误，Payload只是Base64编码而非加密，任何人都可以解码查看；选项D错误，JWT本身没有自动删除机制，需要客户端自行管理。

### 问题2

OAuth2授权码模式（Authorization Code）最适合哪种应用场景？

A. 纯前端JavaScript单页应用（SPA）  
B. 移动端原生应用  
C. 具有后端服务器的Web应用  
D. 命令行工具  

**正确答案：C**

**详细解释：** 授权码模式要求客户端能够安全地存储client_secret，因此最适合具有后端服务器的Web应用（Confidential Client）。纯前端应用无法安全存储密钥，应使用授权码模式+PKCE。移动端应用也推荐使用PKCE增强版本。命令行工具通常使用客户端凭证模式或设备授权流程。

### 问题3

在RBAC模型中，以下哪种做法违反了最小权限原则？

A. 给所有内容编辑者分配Admin角色，方便他们管理文章  
B. 为新员工分配Viewer角色，仅能查看内容  
C. 创建专门的Moderator角色，仅包含审核评论的权限  
D. 定期审计用户权限，移除不再需要的权限  

**正确答案：A**

**详细解释：** 最小权限原则要求用户只拥有完成工作所需的最小权限集合。给编辑者分配Admin角色会赋予他们不必要的权限（如删除用户、修改系统配置），增加了安全风险。正确做法是创建Editor角色，仅包含文章相关权限。其他选项都符合最小权限原则。

### 问题4

关于Session-based和Token-based认证的比较，以下说法错误的是？

A. Session-based认证需要在服务器端存储会话数据  
B. Token-based认证天然支持跨域请求，无需额外配置  
C. Session-based认证更容易实现主动登出功能  
D. Token-based认证的JWT令牌可以随时被服务器撤销  

**正确答案：D**

**详细解释：** JWT是无状态的，服务器签发后无法直接撤销。要实现撤销功能，需要额外的机制如令牌黑名单（将未过期的令牌加入黑名单并每次验证时检查），这会增加复杂度并部分抵消无状态的优势。相比之下，Session-based认证只需删除服务器端的会话数据即可立即生效。其他选项都是正确的对比。

### 问题5

以下哪种情况最适合使用OAuth2的客户端凭证模式（Client Credentials）？

A. 用户通过微信登录第三方网站  
B. 移动应用需要访问用户的个人相册  
C. 后端服务A调用后端服务B的内部API  
D. 桌面应用需要代表用户发送邮件  

**正确答案：C**

**详细解释：** 客户端凭证模式用于机器对机器（M2M）通信，没有最终用户参与。后端服务之间的API调用是典型场景，服务A使用自己的凭证（client_id和client_secret）获取访问令牌，然后调用服务B。选项A和D涉及用户授权，应使用授权码模式；选项B也需要用户授权，不适合客户端凭证模式。

## 本节知识框架

**课程定位**：分类「backend_development」· 学习阶段 进阶 · 建议用时 50 分钟。

本课主线：理解JWT结构签名、OAuth2授权流程、RBAC权限控制和会话管理。

### 复习清单

- [ ] 能不看正文复述本课核心术语，并指出一个边界或反例。
- [ ] 能运行或推演本课示例，记录输入、输出与失败现象。
- [ ] 能完成一次自测，并把错题对照考点精讲定位原因。

## 核心概念定义

| 术语 | 一句话说明 |
| --- | --- |
| JWT | 理解JWT结构签名、OAuth2授权流程、RBAC权限控制和会话管理。相关：正文给出可操作定义与适用边界。 |
| OAuth2 | 理解JWT结构签名、OAuth2授权流程、RBAC权限控制和会话管理。相关：正文给出可操作定义与适用边界。 |
| 认证 | 理解JWT结构签名、OAuth2授权流程、RBAC权限控制和会话管理。相关：正文给出可操作定义与适用边界。 |
| 授权 | 理解JWT结构签名、OAuth2授权流程、RBAC权限控制和会话管理。相关：正文给出可操作定义与适用边界。 |
| RBAC | 理解JWT结构签名、OAuth2授权流程、RBAC权限控制和会话管理。相关：正文给出可操作定义与适用边界。 |

## 原理与运行机制

正文各章按「输入是什么 → 中间如何转换 → 输出到哪 → 失败时怎样表现」四问展开；复习时给每个机制补一句自己的复述，再回到对应章节核对。

## 典型应用场景

- 结合「认证授权（JWT/OAuth2）」的常见落地场景与选型边界，详见正文各章节的对比讨论。
- 迁移到新项目时，先明确输入规模、失败代价与可观测手段，再决定采用深度。

## 代码/协议/SQL 示例

正文首个示例可作为最小验证起点（原样保留在上方章节）：先跑通，再改一个输入观察输出变化。

```javascript
// 最基础的认证方式
const user = await db.query(
  'SELECT * FROM users WHERE username = ? AND password = ?',
  [username, password]
);
```

## 时间/空间复杂度或性能分析

- 用本课方案处理规模 n 时，先估计主循环与嵌套层数，再决定优化方向；小样本上的耗时读数不能外推。
- 性能结论要绑定输入分布：换数据规模、并发度或缓存命中情况后须重新测量。

## 常见误区与易错点

| 错误做法 | 典型现象 | 修复方向 |
| --- | --- | --- |
| 只验证正常输入 | 边界数据触发时才暴露问题 | 为每个结论补一个空值/极值/重复值用例 |
| 背结论不跑实验 | 换个输入就失效 | 按「预测—实测—差异归因」三步复盘 |
| 忽略环境与版本差异 | 本机可用线上报错 | 把版本、配置与依赖写入复现步骤 |

## 与其他知识点的关系

本课与分类「backend_development」内相邻课程互为补充，建议按清单顺序学完再做综合练习。

## 自测题与参考答案

以下题目与题库同源，作答后再看解析；错误项要能说出错在哪一步。

## 考点精讲

### 考点 1

关于JWT的结构，以下哪项描述是正确的？

A. JWT由四部分组成：Header、Payload、Signature和Salt  
B. JWT的Payload部分是加密的，只有持有密钥的人才能查看  
C. JWT的Signature部分用于验证令牌完整性，防止篡改 ✅  
D. JWT过期后会自动从客户端删除  

**正确答案：** C

**解析：** JWT的Signature（签名）是通过对Header和Payload进行哈希运算生成的，用于验证令牌在传输过程中是否被篡改。如果任何部分被修改，签名验证将失败。选项A错误，JWT只有三部分；选项B错误，Payload只是Base64编码而非加密，任何人都可以解码查看；选项D错误，JWT本身没有自动删除机制，需要客户端自行管理。

### 考点 2

OAuth2授权码模式（Authorization Code）最适合哪种应用场景？

A. 纯前端JavaScript单页应用（SPA）  
B. 移动端原生应用  
C. 具有后端服务器的Web应用 ✅  
D. 命令行工具  

**正确答案：** C

**解析：** 授权码模式要求客户端能够安全地存储client_secret，因此最适合具有后端服务器的Web应用（Confidential Client）。纯前端应用无法安全存储密钥，应使用授权码模式+PKCE。移动端应用也推荐使用PKCE增强版本。命令行工具通常使用客户端凭证模式或设备授权流程。

### 考点 3

在RBAC模型中，以下哪种做法违反了最小权限原则？

A. 给所有内容编辑者分配Admin角色，方便他们管理文章 ✅  
B. 为新员工分配Viewer角色，仅能查看内容  
C. 创建专门的Moderator角色，仅包含审核评论的权限  
D. 定期审计用户权限，移除不再需要的权限  

**正确答案：** A

**解析：** 编辑者日常只需创建、修改、发布文章，分配 Admin 附带删用户、改系统配置等权限，属于典型的权限超发，一次令牌泄露即造成全局破坏，违反最小权限。正确做法是建 Editor 角色只授予内容相关权限。Viewer 只读、专门的 Moderator 仅含审核权、定期回收不再需要的权限，都是最小权限原则的正面实践。RBAC 的价值就在角色与权限矩阵可审计。

### 考点 4

关于Session-based和Token-based认证的比较，以下说法错误的是？

A. Session-based认证需要在服务器端存储会话数据  
B. Token-based认证天然支持跨域请求，无需额外配置  
C. Session-based认证更容易实现主动登出功能  
D. Token-based认证的JWT令牌可以随时被服务器撤销 ✅  

**正确答案：** D

**解析：** JWT是无状态的，服务器签发后无法直接撤销。要实现撤销功能，需要额外的机制如令牌黑名单（将未过期的令牌加入黑名单并每次验证时检查），这会增加复杂度并部分抵消无状态的优势。相比之下，Session-based认证只需删除服务器端的会话数据即可立即生效。其他选项都是正确的对比。

### 考点 5

以下哪种情况最适合使用OAuth2的客户端凭证模式（Client Credentials）？

A. 用户通过微信登录第三方网站  
B. 移动应用需要访问用户的个人相册  
C. 后端服务A调用后端服务B的内部API ✅  
D. 桌面应用需要代表用户发送邮件  

**正确答案：** C

**解析：** 客户端凭证模式用于机器对机器（M2M）通信，没有最终用户参与。后端服务之间的API调用是典型场景，服务A使用自己的凭证（client_id和client_secret）获取访问令牌，然后调用服务B。选项A和D涉及用户授权，应使用授权码模式；选项B也需要用户授权，不适合客户端凭证模式。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| JWT | 定位线索见正文小节；速查表只保留名称，避免脱离上下文使用。 |
| OAuth2 | 定位线索见正文小节；速查表只保留名称，避免脱离上下文使用。 |
| 认证 | 定位线索见正文小节；速查表只保留名称，避免脱离上下文使用。 |
| 授权 | 定位线索见正文小节；速查表只保留名称，避免脱离上下文使用。 |
| RBAC | 定位线索见正文小节；速查表只保留名称，避免脱离上下文使用。 |

## 参考资料与复核

- [本课资料锚点 backend_auth_jwt_oauth](https://zh.wikipedia.org/w/index.php?search=backend_auth_jwt_oauth)

- 官方/权威资料：[HTTP 规范](https://datatracker.ietf.org/doc/html/rfc9110)
- 主题延伸：[关于「OAuth2」的检索页](https://zh.wikipedia.org/w/index.php?search=OAuth2)
- 本课索引词：[锚点 backend_auth_jwt_oauth](https://datatracker.ietf.org/doc/html/rfc9110#JWT)
- 最后复核：2026-10-04
- 下次复核：2026-11-04

## 内容元数据

- 内容更新时间：2026-10-06

- 内容版本：v2.0
- 课程标识：backend_auth_jwt_oauth
- 所属分类：backend_development
- 学习阶段：进阶
- 建议用时：50 分钟

