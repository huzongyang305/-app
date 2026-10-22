## 零基础详解：CI 流水线模板

### 一句话说清它是什么

CI 流水线就是「每次提交后自动跑的那串检查」。
好的流水线有三个特征：**快、稳定、失败信息清楚**。

### 用生活比喻理解

| 阶段 | 比喻 | 说明 |
| --- | --- | --- |
| 检出与缓存 | 备料 | 装依赖，尽量复用缓存 |
| 静态检查 | 质检 | lint、类型检查、shellcheck |
| 测试 | 验收 | 单元与集成测试 |
| 构建 | 打包 | 产出制品，只构建一次 |
| 发布 | 发货 | 部署到环境，可回滚 |

### 模板一：通用多语言项目

```yaml
name: ci
on:
  push: { branches: [main] }
  pull_request:

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true          # 新提交自动取消旧流水线

jobs:
  check:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: npm }
      - run: npm ci
      - run: npx tsc --noEmit
      - run: npm run lint
      - run: npm test -- --run

  build:
    needs: check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: npm }
      - run: npm ci
      - run: npm run build
      - uses: actions/upload-artifact@v4
        with:
          name: dist-${{ github.sha }}     # 用 commit SHA 命名
          path: dist/
          retention-days: 7
```

### 模板二：Shell 脚本仓库

```yaml
name: shell-ci
on: [push, pull_request]

jobs:
  lint-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: 安装工具
        run: |
          sudo apt-get update
          sudo apt-get install -y shellcheck bats
      - name: 静态检查
        run: shellcheck -S warning scripts/*.sh
      - name: 单元测试
        run: bats test/
      - name: 语法检查
        run: |
          for f in scripts/*.sh; do
            bash -n "$f"
          done
```

### 模板三：Docker 镜像构建与扫描

```yaml
name: image
on:
  push: { tags: ["v*"] }

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - name: 登录镜像仓库
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: 构建并推送
        uses: docker/build-push-action@v6
        with:
          push: true
          tags: ghcr.io/${{ github.repository }}:${{ github.ref_name }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
      - name: 漏洞扫描
        uses: aquasecurity/trivy-action@0.28.0
        with:
          image-ref: ghcr.io/${{ github.repository }}:${{ github.ref_name }}
          severity: HIGH,CRITICAL
          exit-code: "1"          # 有高危漏洞就失败
```

### 让流水线变快的五招

| 手段 | 效果 |
| --- | --- |
| 依赖缓存（`cache: npm`） | 省掉每次下载时间 |
| `concurrency` 取消旧任务 | 不浪费并行额度 |
| 拆分并行 job | 用时间换机器数 |
| 只跑受影响的包（monorepo） | 大幅缩短时间 |
| 容器镜像层缓存 | 加速镜像构建 |

### 让流水线可信的四条纪律

```text
1. 只构建一次：制品用 commit SHA 命名，各环境复用同一份
2. 密钥进 Secrets：绝不写在 YAML 里
3. 失败要能定位：日志分级、保留测试报告与制品
4. 关键检查不许跳过：类型检查、测试、漏洞扫描都是门禁
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 每个环境都重新构建 | 测试过的不是发布的 | 构建一次，复用制品 |
| 用 `npm install` | 版本可能与 lockfile 不一致 | CI 用 `npm ci` |
| 密钥写进 YAML | 泄露 | 用 Secrets |
| 没设 `timeout-minutes` | 卡住的任务占用额度 | 每个 job 设超时 |
| 缓存键不含 lockfile | 用到过期依赖 | 用 lockfile 哈希做键 |
| 所有检查串在一个 job | 出错慢、定位难 | 拆分并行 job |
| 只跑测试不跑构建 | 上线才发现打不出包 | 构建纳入流水线 |
| 制品没保留期限 | 存储无限增长 | 设置 `retention-days` |

### 学完自测

- [ ] 能说出 CI 的五个典型阶段。
- [ ] 知道为什么 CI 要用 `npm ci` 而不是 `npm install`。
- [ ] 能说出让流水线变快的至少三招。
- [ ] 知道「只构建一次」为什么重要。
- [ ] 能为 Shell 仓库写出 shellcheck 加 bats 的流水线。
