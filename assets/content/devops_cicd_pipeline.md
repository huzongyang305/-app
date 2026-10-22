# DevOps 课程：CI/CD 流水线设计与实现

> **版本**: v2.0  
> **难度**: 初学者友好  
> **前置知识**: Git 基础、Linux 命令行基础  
> **预计学习时间**: 3-4 小时

---

## 第 1 章 · 本节知识框架

```text
CI/CD 流水线设计与实现
├── 1. CI/CD 核心概念与价值
│   ├── 什么是持续集成（CI）
│   ├── 什么是持续交付/部署（CD）
│   └── CI/CD 带来的价值
├── 2. 流水线设计原则
│   ├── 阶段划分策略
│   ├── 并行执行模式
│   └── 缓存与复用策略
├── 3. Jenkins Pipeline 实战
│   ├── 声明式语法基础
│   ├── 阶段（Stage）与步骤（Step）
│   └── 后置操作（Post）
├── 4. GitLab CI/CD 配置
│   ├── .gitlab-ci.yml 结构
│   ├── stages 与 jobs
│   └── artifacts 与缓存
├── 5. GitHub Actions 工作流
│   ├── workflow / job / step / action
│   ├── 事件触发机制
│   └── 矩阵构建策略
├── 6. 流水线优化
│   ├── 并行测试分片
│   ├── 依赖缓存
│   └── 增量构建
├── 7. 安全集成（DevSecOps）
│   ├── 静态代码扫描（SAST）
│   ├── 依赖漏洞检查（SCA）
│   └── 密钥管理
└── 8. 综合实战：Node.js 项目完整 CI/CD
```

---

## 第 2 章 · 核心概念定义

### 2.1 生活类比：CI/CD 就像汽车生产线

想象一座现代化汽车工厂 🏭：

| 工厂环节 | CI/CD 对应 | 说明 |
|---------|-----------|------|
| 零件入库检验 | **持续集成（CI）** | 每个零件（代码提交）进入生产线前都要检测质量 |
| 组装流水线 | **Pipeline（流水线）** | 从零件到成品经过多个有序工位 |
| 质量测试工位 | **自动化测试** | 单元测试、集成测试、端到端测试 |
| 出厂质检 | **代码审查 + 安全扫描** | 确保产品符合安全与质量标准 |
| 交付到 4S 店 | **持续交付（CD）** | 随时可以上架销售（部署到生产环境） |
| 全自动无人交付 | **持续部署** | 从生产线直接到客户手中，无需人工干预 |

### 2.2 标准定义

- **持续集成（Continuous Integration, CI）**：开发者频繁地（每天多次）将代码变更合并到共享主干分支。每次合并自动触发构建和测试，尽早发现集成错误。

- **持续交付（Continuous Delivery）**：在 CI 的基础上，代码变更经过自动化构建、测试、打包后，随时可以手动一键发布到生产环境。

- **持续部署（Continuous Deployment）**：在持续交付的基础上更进一步——每一次通过测试的代码变更都会**自动**部署到生产环境，无需人工审批。

- **Pipeline（流水线）**：一系列按顺序执行的自动化步骤，将代码从提交到部署的整个过程串联起来。就像工厂的传送带，代码从一端进入，成品从另一端出来。

---

## 第 3 章 · 原理与运行机制

### 3.1 CI/CD 流水线的运行机制

```text
开发者 push 代码
      │
      ▼
┌─────────────┐
│  触发器      │  ← Webhook / 定时 / 手动触发
│  (Trigger)   │
└──────┬──────┘
       ▼
┌─────────────┐
│  拉取代码    │  ← git clone / git checkout
│  (Checkout)  │
└──────┬──────┘
       ▼
┌─────────────┐
│  构建阶段    │  ← npm install → npm run build
│  (Build)     │
└──────┬──────┘
       ▼
┌─────────────┐
│  测试阶段    │  ← 单元测试 → 集成测试 → E2E 测试
│  (Test)      │
└──────┬──────┘
       ▼
┌─────────────┐
│  安全扫描    │  ← SAST / SCA / 容器扫描
│  (Security)  │
└──────┬──────┘
       ▼
┌─────────────┐
│  打包阶段    │  ← Docker 镜像 / 产物归档
│  (Package)   │
└──────┬──────┘
       ▼
┌─────────────┐
│  部署阶段    │  → Staging → Production
│  (Deploy)    │
└─────────────┘
```

### 3.2 流水线执行模型

流水线本质上是一个**有向无环图（DAG）**：

1. **串行执行**：阶段按顺序执行，前一个阶段成功后才进入下一个阶段
2. **并行执行**：同一阶段内的多个任务可以同时运行（如并行跑不同浏览器的测试）
3. **条件执行**：根据前序结果决定是否执行（如只在 main 分支才部署到生产环境）
4. **失败快速反馈**：任意阶段失败，后续阶段不再执行，立即通知开发者

### 3.3 事件驱动架构

CI/CD 系统通过事件触发流水线：

| 触发事件 | 典型场景 |
|---------|---------|
| `push` | 代码推送到仓库时触发构建和测试 |
| `pull_request` | 创建/更新 PR 时触发代码检查 |
| `schedule` | 定时触发（如每日夜间构建） |
| `manual` | 手动触发部署到生产环境 |
| `release` | 创建版本标签时触发发布流程 |

---

## 第 4 章 · 典型应用场景

### 4.1 场景一：Web 应用自动部署

```text
场景描述：
团队开发一个 React + Node.js 的 Web 应用
→ 开发者提交 PR 自动运行 lint + 测试
→ PR 合并到 main 自动构建 Docker 镜像
→ 自动部署到 staging 环境进行验收
→ 手动审批后自动部署到 production
```

### 4.2 场景二：移动端应用发布

```text
场景描述：
开发团队维护 iOS 和 Android 应用
→ 每日定时构建（Nightly Build）
→ 自动运行 UI 自动化测试
→ 签名打包生成 .ipa / .apk
→ 上传到内测分发平台（如 Firebase App Distribution）
→ 版本发布时自动提交到应用商店审核
```

### 4.3 场景三：微服务持续交付

```text
场景描述：
公司有 20+ 个微服务，每个服务独立部署
→ 每个服务有自己的 CI/CD 流水线
→ 代码变更后自动构建镜像并推送到镜像仓库
→ 自动更新 Kubernetes 部署
→ 金丝雀发布（Canary）逐步切流量
→ 监控指标正常则全量发布，异常则自动回滚
```

### 4.4 场景四：数据管道自动化

```text
场景描述：
数据团队维护 ETL 数据处理管道
→ 数据模型变更触发 CI 检查
→ 自动运行数据质量测试（Great Expectations）
→ 通过后自动部署到 Airflow/Spark 集群
→ 定时调度数据处理任务
```

---

## 第 5 章 · 代码示例

### 5.1 Jenkins Pipeline（声明式语法）

```groovy
// Jenkinsfile - 声明式流水线
pipeline {
    agent {
        docker {
            image 'node:18-alpine'
            args '-v /tmp/npm-cache:/root/.npm'
        }
    }

    environment {
        CI = 'true'
        DOCKER_REGISTRY = 'registry.example.com'
        IMAGE_NAME = 'my-node-app'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    triggers {
        pollSCM('H/5 * * * *')  // 每 5 分钟检查代码变更
    }

    stages {
        stage('安装依赖') {
            steps {
                sh 'npm ci --cache /root/.npm'
            }
        }

        stage('代码检查') {
            steps {
                sh 'npm run lint'
            }
        }

        stage('单元测试') {
            parallel {  // 并行执行不同类型的测试
                stage('前端测试') {
                    steps {
                        sh 'npm run test:frontend -- --coverage'
                    }
                }
                stage('后端测试') {
                    steps {
                        sh 'npm run test:backend -- --coverage'
                    }
                }
            }
        }

        stage('构建') {
            steps {
                sh 'npm run build'
            }
        }

        stage('构建 Docker 镜像') {
            when {
                branch 'main'
            }
            steps {
                script {
                    docker.build("${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}")
                    docker.build("${DOCKER_REGISTRY}/${IMAGE_NAME}:latest")
                }
            }
        }

        stage('部署到 Staging') {
            when {
                branch 'main'
            }
            steps {
                sh """
                    kubectl set image deployment/my-app \
                        my-app=${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} \
                        --namespace staging
                """
            }
        }

        stage('部署到 Production') {
            when {
                branch 'main'
            }
            input {
                message '是否部署到生产环境？'
                ok '确认部署'
                submitter 'admin,tech-lead'
            }
            steps {
                sh """
                    kubectl set image deployment/my-app \
                        my-app=${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} \
                        --namespace production
                """
            }
        }
    }

    post {
        always {
            // 无论成功失败都执行：归档测试报告和构建产物
            archiveArtifacts artifacts: 'dist/**', allowEmptyArchive: true
            junit testResults: '**/junit.xml', allowEmptyResults: true
        }
        success {
            // 构建成功时发送通知
            slackSend channel: '#deployments',
                      color: 'good',
                      message: "✅ ${env.JOB_NAME} #${env.BUILD_NUMBER} 构建成功"
        }
        failure {
            // 构建失败时发送通知
            slackSend channel: '#deployments',
                      color: 'danger',
                      message: "❌ ${env.JOB_NAME} #${env.BUILD_NUMBER} 构建失败"
        }
        cleanup {
            // 清理工作空间
            cleanWs()
        }
    }
}
```

### 5.2 GitLab CI/CD 配置

```yaml
# .gitlab-ci.yml
# ==========================================
# 全局配置
# ==========================================
variables:
  NODE_IMAGE: node:18-alpine
  DOCKER_REGISTRY: registry.example.com
  IMAGE_NAME: my-node-app

stages:
  - install
  - lint
  - test
  - build
  - security
  - deploy-staging
  - deploy-production

# 全局缓存策略
default:
  image: $NODE_IMAGE
  cache:
    key:
      files:
        - package-lock.json
    paths:
      - node_modules/
      - .npm/
    policy: pull-push

# ==========================================
# 安装依赖阶段
# ==========================================
install:
  stage: install
  script:
    - npm ci --cache .npm/
  cache:
    key:
      files:
        - package-lock.json
    paths:
      - node_modules/
      - .npm/
    policy: pull-push
  artifacts:
    paths:
      - node_modules/
    expire_in: 1 hour

# ==========================================
# 代码检查阶段
# ==========================================
lint:
  stage: lint
  needs: ["install"]
  script:
    - npm run lint
    - npm run type-check

# ==========================================
# 测试阶段（并行执行）
# ==========================================
test:unit:
  stage: test
  needs: ["install"]
  script:
    - npm run test:unit -- --coverage
  coverage: '/All files[^|]*\|[^|]*\s+([\d\.]+)/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
      junit:
        - junit/unit-results.xml
    paths:
      - coverage/

test:integration:
  stage: test
  needs: ["install"]
  services:
    - postgres:15-alpine
    - redis:7-alpine
  variables:
    POSTGRES_DB: test_db
    POSTGRES_USER: test
    POSTGRES_PASSWORD: test
    DATABASE_URL: postgresql://test:test@postgres:5432/test_db
    REDIS_URL: redis://redis:6379
  script:
    - npm run test:integration
  artifacts:
    reports:
      junit:
        - junit/integration-results.xml

test:e2e:
  stage: test
  needs: ["install"]
  image: mcr.microsoft.com/playwright:v1.40.0-jammy
  script:
    - npm run build
    - npm run test:e2e
  artifacts:
    when: always
    paths:
      - playwright-report/
    expire_in: 7 days

# ==========================================
# 构建阶段
# ==========================================
build:
  stage: build
  needs: ["test:unit", "test:integration", "test:e2e"]
  script:
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 week

build:docker:
  stage: build
  needs: ["build"]
  image: docker:24-dind
  services:
    - docker:24-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $DOCKER_REGISTRY
  script:
    - docker build -t $DOCKER_REGISTRY/$IMAGE_NAME:$CI_COMMIT_SHA .
    - docker push $DOCKER_REGISTRY/$IMAGE_NAME:$CI_COMMIT_SHA
  only:
    - main
    - tags

# ==========================================
# 安全扫描阶段
# ==========================================
security:sast:
  stage: security
  needs: ["build"]
  script:
    - npx semgrep --config=auto --json -o gl-sast-report.json src/
  artifacts:
    reports:
      sast: gl-sast-report.json
    paths:
      - gl-sast-report.json
  allow_failure: false

security:dependencies:
  stage: security
  needs: ["install"]
  script:
    - npm audit --audit-level=high --json > npm-audit-report.json || true
    - npx audit-ci --high --report
  artifacts:
    paths:
      - npm-audit-report.json
    expire_in: 30 days

# ==========================================
# 部署阶段
# ==========================================
deploy:staging:
  stage: deploy-staging
  needs: ["build:docker", "security:sast", "security:dependencies"]
  environment:
    name: staging
    url: https://staging.example.com
  script:
    - kubectl set image deployment/$IMAGE_NAME
        $IMAGE_NAME=$DOCKER_REGISTRY/$IMAGE_NAME:$CI_COMMIT_SHA
        --namespace staging
    - kubectl rollout status deployment/$IMAGE_NAME --namespace staging --timeout=300s
  only:
    - main
  when: manual

deploy:production:
  stage: deploy-production
  needs: ["deploy:staging"]
  environment:
    name: production
    url: https://www.example.com
  script:
    - kubectl set image deployment/$IMAGE_NAME
        $IMAGE_NAME=$DOCKER_REGISTRY/$IMAGE_NAME:$CI_COMMIT_SHA
        --namespace production
    - kubectl rollout status deployment/$IMAGE_NAME --namespace production --timeout=300s
  only:
    - main
  when: manual  # 生产环境需要手动审批
  allow_failure: false
```

### 5.3 GitHub Actions 工作流

```yaml
# .github/workflows/ci-cd.yml
name: Node.js CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  workflow_dispatch:  # 支持手动触发
    inputs:
      environment:
        description: '部署目标环境'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production

# 全局环境变量
env:
  NODE_VERSION: '18'
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

# 并发控制：同一分支只保留最新的流水线运行
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  # ==========================================
  # 依赖安装与缓存
  # ==========================================
  install:
    name: 安装依赖
    runs-on: ubuntu-latest
    steps:
      - name: 检出代码
        uses: actions/checkout@v4

      - name: 设置 Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}

      - name: 缓存 node_modules
        uses: actions/cache@v4
        id: npm-cache
        with:
          path: node_modules
          key: ${{ runner.os }}-node-${{ hashFiles('package-lock.json') }}
          restore-keys: |
            ${{ runner.os }}-node-

      - name: 安装依赖
        if: steps.npm-cache.outputs.cache-hit != 'true'
        run: npm ci

  # ==========================================
  # 代码质量检查
  # ==========================================
  lint:
    name: 代码检查
    runs-on: ubuntu-latest
    needs: install
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
      - name: 恢复缓存
        uses: actions/cache@v4
        with:
          path: node_modules
          key: ${{ runner.os }}-node-${{ hashFiles('package-lock.json') }}
      - name: 运行 ESLint
        run: npm run lint
      - name: TypeScript 类型检查
        run: npm run type-check

  # ==========================================
  # 测试（矩阵策略：多版本并行测试）
  # ==========================================
  test:
    name: 测试 (Node ${{ matrix.node-version }})
    runs-on: ubuntu-latest
    needs: install
    strategy:
      fail-fast: false
      matrix:
        node-version: [16, 18, 20]
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_DB: test_db
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
      - name: 恢复缓存
        uses: actions/cache@v4
        with:
          path: node_modules
          key: ${{ runner.os }}-node-${{ hashFiles('package-lock.json') }}
      - name: 运行测试
        run: npm run test:ci
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/test_db
          CI: true
      - name: 上传覆盖率报告
        if: matrix.node-version == 18
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: coverage/
          retention-days: 7

  # ==========================================
  # 构建
  # ==========================================
  build:
    name: 构建应用
    runs-on: ubuntu-latest
    needs: [lint, test]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
      - name: 恢复缓存
        uses: actions/cache@v4
        with:
          path: node_modules
          key: ${{ runner.os }}-node-${{ hashFiles('package-lock.json') }}
      - name: 构建
        run: npm run build
      - name: 上传构建产物
        uses: actions/upload-artifact@v4
        with:
          name: build-output
          path: dist/
          retention-days: 3

  # ==========================================
  # 构建并推送 Docker 镜像
  # ==========================================
  docker:
    name: 构建 Docker 镜像
    runs-on: ubuntu-latest
    needs: build
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4

      - name: 登录容器镜像仓库
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: 设置 Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: 提取元数据（标签和版本号）
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,prefix=
            type=raw,value=latest

      - name: 构建并推送镜像
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  # ==========================================
  # 安全扫描
  # ==========================================
  security:
    name: 安全扫描
    runs-on: ubuntu-latest
    needs: build
    steps:
      - uses: actions/checkout@v4
      - name: 恢复缓存
        uses: actions/cache@v4
        with:
          path: node_modules
          key: ${{ runner.os }}-node-${{ hashFiles('package-lock.json') }}
      - name: 运行 npm audit
        run: npm audit --audit-level=high
        continue-on-error: true
      - name: 运行 SAST 扫描
        uses: returntocorp/semgrep-action@v1
        with:
          config: >-
            p/owasp-top-ten
            p/security-audit

  # ==========================================
  # 部署到 Staging
  # ==========================================
  deploy-staging:
    name: 部署到 Staging
    runs-on: ubuntu-latest
    needs: [docker, security]
    if: github.ref == 'refs/heads/main'
    environment:
      name: staging
      url: https://staging.example.com
    steps:
      - name: 部署到 Staging
        run: |
          echo "🚀 部署到 Staging 环境..."
          # kubectl set image deployment/my-app \
          #   my-app=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }} \
          #   --namespace staging

  # ==========================================
  # 部署到 Production（需手动审批）
  # ==========================================
  deploy-production:
    name: 部署到 Production
    runs-on: ubuntu-latest
    needs: deploy-staging
    if: github.event_name == 'workflow_dispatch' && github.event.inputs.environment == 'production'
    environment:
      name: production
      url: https://www.example.com
    steps:
      - name: 部署到 Production
        run: |
          echo "🚀 部署到 Production 环境..."
          # kubectl set image deployment/my-app \
          #   my-app=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }} \
          #   --namespace production
```

### 5.4 Dockerfile 示例

```dockerfile
# Dockerfile - 多阶段构建
# ==========================================
# 阶段 1: 构建
# ==========================================
FROM node:18-alpine AS builder

WORKDIR /app

# 先复制依赖文件，利用 Docker 缓存层
COPY package.json package-lock.json ./
RUN npm ci --only=production && \
    cp -R node_modules prod_node_modules && \
    npm ci

# 复制源代码并构建
COPY . .
RUN npm run build

# ==========================================
# 阶段 2: 生产镜像
# ==========================================
FROM node:18-alpine AS production

WORKDIR /app

# 安全：不使用 root 用户运行
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# 只复制生产依赖和构建产物
COPY --from=builder --chown=nodejs:nodejs /app/prod_node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./

USER nodejs

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "dist/main.js"]
```

---

## 第 6 章 · 时间/空间复杂度与性能分析

### 6.1 流水线性能指标

| 指标 | 定义 | 优秀标准 | 优化方法 |
|------|------|---------|---------|
| **流水线总耗时** | 从触发到完成的总时间 | < 10 分钟 | 并行化、缓存、增量构建 |
| **反馈时间** | 开发者提交代码到获得测试结果的时间 | < 5 分钟 | 快速 lint/测试前置 |
| **部署频率** | 单位时间内的部署次数 | 每日多次 | 自动化全流程 |
| **变更失败率** | 导致故障的变更占比 | < 5% | 完善测试覆盖 |
| **恢复时间（MTTR）** | 从故障到恢复的时间 | < 1 小时 | 自动回滚机制 |

### 6.2 并行化加速比分析

假设流水线有 n 个独立任务，每个任务耗时 t：

```text
串行执行总时间 = n × t
并行执行总时间 = t（理想情况）
加速比 S = n × t / t = n

实际加速比（考虑开销）：
S = n × t / (t + overhead)

其中 overhead = 调度延迟 + 资源竞争 + 同步等待
```

### 6.3 缓存命中率与构建时间关系

```text
无缓存构建时间：T_total = T_install + T_build + T_test
有缓存构建时间：T_cached = T_cache_restore + T_incremental_build + T_test

典型节省比例：
├── npm install:  从 120s → 5s（缓存命中时节省 96%）
├── Docker build: 从 300s → 60s（层缓存节省 80%）
├── 编译构建:     从 180s → 30s（增量编译节省 83%）
└── 总计:         从 600s → 95s（整体节省 84%）
```

### 6.4 空间复杂度（存储成本）

```text
流水线存储消耗 = 代码仓库 + 构建产物 + Docker 镜像 + 测试报告

优化策略：
├── 构建产物保留策略：保留最近 10 个版本
├── Docker 镜像清理：删除 Untagged 镜像 + 定期 GC
├── 日志轮转：超过 30 天的日志自动归档
└── 缓存大小限制：node_modules 缓存通常 200MB-500MB
```

---

## 第 7 章 · 常见误区与易错点

### 7.1 误区一：流水线里跑手动操作

```text
❌ 错误做法：
- 在流水线中 SSH 到服务器手动执行命令
- 构建过程中需要人工输入密码
- 部署步骤依赖某个人的本地环境

✅ 正确做法：
- 所有操作都通过脚本自动化
- 使用密钥管理服务存储凭证
- 在标准化的容器/虚拟机中执行
```

### 7.2 误区二：忽视流水线速度

```text
❌ 错误做法：
- 所有测试串行执行，流水线跑 40 分钟
- 每次都全量安装依赖
- 不区分快速反馈和慢速反馈

✅ 正确做法：
- 快速检查（lint、单元测试）前置，慢速测试（E2E）后置
- 利用缓存减少重复下载
- 并行执行独立任务
- 目标：快速反馈 < 5 分钟
```

### 7.3 误区三：不测试流水线本身

```text
❌ 错误做法：
- 流水线配置文件写完就不管了
- 不验证流水线在干净环境能否运行
- 依赖隐式的环境变量和全局工具

✅ 正确做法：
- 定期在干净环境验证流水线
- 所有依赖显式声明（包括工具版本）
- 流水线代码也纳入 Code Review
```

### 7.4 误区四：密钥硬编码

```text
❌ 错误做法：
- 把数据库密码写在 Jenkinsfile 里
- 在 .gitlab-ci.yml 中明文存储 API Key
- 将密钥提交到 Git 仓库

✅ 正确做法：
- 使用 CI/CD 平台的 Secret 管理功能
- 使用 HashiCorp Vault / AWS Secrets Manager
- 密钥通过环境变量注入，永不落盘
```

### 7.5 误区五：缺少失败处理

```text
❌ 错误做法：
- 构建失败后没有通知
- 部署失败后没有回滚机制
- 不记录失败原因和日志

✅ 正确做法：
- 配置多渠道通知（Slack、邮件、钉钉）
- 实现自动回滚（rollout undo）
- 保留完整日志用于事后分析
```

---

## 第 8 章 · 与其他知识点的关系

```text
CI/CD 流水线 ─── 关联知识图谱
     │
     ├──→ 版本控制（Git）
     │    └── 分支策略决定流水线触发规则
     │
     ├──→ 容器化（Docker）
     │    └── 构建产物打包为镜像，保证环境一致性
     │
     ├──→ 容器编排（Kubernetes）
     │    └── 部署阶段的目标平台
     │
     ├──→ 基础设施即代码（IaC）
     │    └── Terraform / Ansible 管理部署环境
     │
     ├──→ 监控与可观测性
     │    └── 部署后通过 Prometheus/Grafana 验证
     │
     ├──→ 安全（DevSecOps）
     │    └── 在流水线中集成安全扫描
     │
     ├──→ 测试策略
     │    └── 测试金字塔：单元 → 集成 → E2E
     │
     └──→ 敏捷开发
          └── CI/CD 是敏捷实践的技术基石
```

---

## 第 9 章 · 自测题与参考答案

### 题目 1：概念理解

**问题**：以下关于 CI/CD 的描述，哪个是正确的？

A. 持续集成是指每天固定时间统一合并代码  
B. 持续部署意味着所有代码变更都自动进入生产环境  
C. 持续交付要求每次变更都必须手动部署到生产环境  
D. CI/CD 只适用于大型团队

<details>
<summary>点击查看答案</summary>

**正确答案：B**

- A 错误：CI 强调的是频繁、小批量的集成（每天多次），而非固定时间
- B 正确：持续部署（Continuous Deployment）的核心就是每次通过测试的变更自动部署
- C 错误：持续交付是"随时可以部署"，但部署动作可以是手动的
- D 错误：任何规模的团队都可以从 CI/CD 中受益

</details>

### 题目 2：Jenkins Pipeline

**问题**：在 Jenkins 声明式流水线中，`post` 块的 `always`、`success`、`failure` 分别在什么时候执行？

<details>
<summary>点击查看答案</summary>

- `always`：无论流水线成功还是失败，都会执行（适合归档产物、清理环境）
- `success`：仅在所有阶段都成功时执行（适合发送成功通知）
- `failure`：仅在有阶段失败时执行（适合发送告警通知）

执行顺序：先执行 `always`，再根据结果执行 `success` 或 `failure`。

</details>

### 题目 3：GitLab CI 缓存

**问题**：在 GitLab CI 中，`cache` 和 `artifacts` 有什么区别？

<details>
<summary>点击查看答案</summary>

| 特性 | cache | artifacts |
|------|-------|-----------|
| 用途 | 加速后续构建（如 node_modules） | 传递构建产物到后续阶段或下载 |
| 生命周期 | 可过期，会被覆盖 | 与 Pipeline 绑定，可设置保留时间 |
| 可见性 | 同一项目的后续 Pipeline 可用 | 可在 Pipeline UI 中下载 |
| 典型内容 | 依赖目录、编译缓存 | 构建输出、测试报告、覆盖率 |

</details>

### 题目 4：GitHub Actions

**问题**：`needs` 关键字的作用是什么？如果不设置会怎样？

<details>
<summary>点击查看答案</summary>

`needs` 用于定义 job 之间的依赖关系：

- 设置了 `needs: [job-a, job-b]` 的 job 会等待 job-a 和 job-b 都完成后才执行
- 如果不设置 `needs`，所有 job 会并行执行（没有先后顺序）
- `needs` 还可以传递 artifacts：后续 job 可以下载前置 job 上传的 artifacts

</details>

### 题目 5：性能优化

**问题**：你的流水线运行时间从 8 分钟增长到了 25 分钟，请列出至少 3 种优化方法。

<details>
<summary>点击查看答案</summary>

1. **并行化**：将独立的测试套件（单元测试、集成测试）改为并行执行
2. **依赖缓存**：缓存 node_modules、Docker 层等，避免每次重新下载
3. **增量构建**：只构建变更的模块，而非全量构建
4. **快速反馈前置**：将 lint 和类型检查放在最前面，快速失败
5. **精简镜像**：使用 Alpine 基础镜像减少拉取时间
6. **条件执行**：只在相关代码变更时触发对应的流水线

</details>

---

## 第 10 章 · 考点精讲

### 考点 1：流水线阶段划分原则

**核心思想**：快速反馈优先，慢速任务后置

```text
推荐顺序：
1. 安装依赖（最快，约 10-30 秒）
2. Lint / 类型检查（快速，约 30 秒-1 分钟）
3. 单元测试（中等，约 1-3 分钟）
4. 集成测试（较慢，约 3-5 分钟）
5. E2E 测试（最慢，约 5-15 分钟）
6. 构建 / 打包（约 1-3 分钟）
7. 安全扫描（约 2-5 分钟）
8. 部署（约 1-3 分钟）
```

### 考点 2：三种 CI/CD 工具对比

| 特性 | Jenkins | GitLab CI | GitHub Actions |
|------|---------|-----------|----------------|
| 配置文件 | Jenkinsfile | .gitlab-ci.yml | .github/workflows/*.yml |
| 语法风格 | Groovy（声明式/脚本式） | YAML | YAML |
| 托管方式 | 自托管 | SaaS + 自托管 Runner | SaaS + 自托管 Runner |
| 并行能力 | parallel stage | parallel jobs | matrix strategy |
| 插件生态 | 最丰富（1800+） | 内置功能多 | Marketplace 丰富 |
| 学习曲线 | 较陡 | 中等 | 较低 |
| 适用场景 | 复杂企业级流水线 | GitLab 生态项目 | GitHub 开源/企业项目 |

### 考点 3：安全集成要点（DevSecOps）

```text
安全左移原则：在流水线中尽早发现安全问题

流水线中的安全检查点：
├── 代码提交时：pre-commit hook（密钥检测、代码格式化）
├── 构建阶段：SAST（静态应用安全测试，如 Semgrep、SonarQube）
├── 依赖安装：SCA（软件成分分析，如 npm audit、Snyk）
├── 镜像构建：容器扫描（如 Trivy、Snyk Container）
├── 部署前：DAST（动态应用安全测试）
└── 运行时：RASP（运行时应用自我保护）
```

### 考点 4：分支策略与流水线触发

```text
GitFlow 策略下的流水线触发规则：

feature/* 分支：
  → 触发 lint + 单元测试
  → 不触发部署

develop 分支：
  → 触发完整测试套件
  → 自动部署到 dev 环境

release/* 分支：
  → 触发完整测试 + 安全扫描
  → 自动部署到 staging 环境

main 分支：
  → 触发完整流水线
  → 手动审批后部署到 production

tag (v*)：
  → 触发发布流水线
  → 构建 Docker 镜像 + 生成 Release Notes
```

---

## 考点精讲

### 问题1

以下关于 CI/CD 的描述，哪个是正确的？

A. 持续集成（CI）是指每天固定时间统一合并代码
B. 持续部署（Continuous Deployment）意味着每次通过测试的代码变更都会自动部署到生产环境
C. 持续交付（Continuous Delivery）要求每次变更都必须手动部署到生产环境
D. CI/CD 只适用于大型团队

**正确答案：B**

**详细解释：** 持续部署的核心特征是每次通过测试的变更自动部署到生产环境，无需人工审批。A 错误，CI 强调频繁、小批量集成（每天多次），而非固定时间。C 错误，持续交付是"随时可以一键部署"，但部署动作本身可以是手动的。D 错误，任何规模的团队都可以从 CI/CD 中受益。

---

### 问题2

在 Jenkins 声明式流水线中，"post" 块的 "always"、"success"、"failure" 三个条件的执行顺序是怎样的？

A. 只执行其中一个，根据流水线结果决定
B. 先执行 "success" 或 "failure"，再执行 "always"
C. 先执行 "always"，再根据结果执行 "success" 或 "failure"
D. 三个条件同时并行执行

**正确答案：C**

**详细解释：** Jenkins 的 "post" 块执行顺序是：无论成功失败都先执行 "always"（适合归档产物、清理环境），然后根据流水线最终结果执行 "success"（发送成功通知）或 "failure"（发送告警通知）。"always" 是必定执行的，而 "success" 和 "failure" 是互斥的。

---

### 问题3

在 GitLab CI 中，"cache" 和 "artifacts" 的核心区别是什么？

A. "cache" 用于传递构建产物到后续阶段，"artifacts" 用于加速后续构建
B. "cache" 用于加速后续构建（如 "node_modules"），"artifacts" 用于传递构建产物到后续阶段或供下载
C. 两者功能完全相同，只是语法不同
D. "cache" 只能缓存 Docker 镜像，"artifacts" 可以缓存任何文件

**正确答案：B**

**详细解释：** "cache" 的主要目的是加速后续构建，例如缓存 "node_modules" 目录，避免每次都重新安装依赖，它可过期且会被覆盖。"artifacts" 的主要目的是在 Pipeline 的阶段之间传递构建产物（如编译输出、测试报告），也可在 Pipeline UI 中供用户下载，它与 Pipeline 绑定并可设置保留时间。

---

### 问题4

在 GitHub Actions 中，"needs" 关键字的作用是什么？如果一个 job 不设置 "needs"，会发生什么？

A. "needs" 用于定义 job 之间的依赖关系；不设置则所有 job 并行执行
B. "needs" 用于定义 step 之间的执行顺序；不设置则所有 step 并行执行
C. "needs" 用于指定运行环境；不设置则使用默认环境
D. "needs" 用于声明所需密钥；不设置则无法访问密钥

**正确答案：A**

**详细解释：** "needs" 用于定义 job 之间的依赖关系。设置了 "needs: [job-a, job-b]" 的 job 会等待 job-a 和 job-b 都完成后才执行。如果不设置 "needs"，所有 job 默认并行执行，没有先后顺序。"needs" 还可以传递 artifacts，后续 job 可以下载前置 job 上传的 artifacts。

---

### 问题5

以下哪种做法违反了 DevSecOps 中"安全左移"的原则？

A. 在代码提交时通过 pre-commit hook 检测密钥泄露
B. 在构建阶段运行 SAST 静态安全扫描
C. 在部署到生产环境后才进行安全审计
D. 在依赖安装时通过 "npm audit" 检查依赖漏洞

**正确答案：C**

**详细解释：** "安全左移"的核心理念是在开发流程中尽早发现安全问题。A、B、D 都是在流水线的前中期阶段进行安全检查，符合安全左移原则。C 将安全审计推迟到部署之后，此时发现问题的修复成本最高、风险最大，违背了安全左移的原则。正确的做法是在部署前就完成所有安全检查。

---

## 第 11 章 · 术语速查

| 术语 | 英文 | 含义 |
|------|------|------|
| CI | Continuous Integration | 持续集成：频繁合并代码并自动测试 |
| CD | Continuous Delivery/Deployment | 持续交付/部署：自动化发布流程 |
| Pipeline | Pipeline | 流水线：自动化任务的有序集合 |
| Stage | Stage | 阶段：流水线中的逻辑分组（如 Build、Test） |
| Job | Job | 作业：阶段中的具体执行单元 |
| Step | Step | 步骤：作业中的单个操作 |
| Artifact | Artifact | 产物：构建生成的文件（如 .jar、.zip） |
| Runner/Agent | Runner / Agent | 执行器：运行流水线任务的机器 |
| Trigger | Trigger | 触发器：启动流水线的条件（push、PR 等） |
| Cache | Cache | 缓存：跨次构建复用的依赖/文件 |
| Secret | Secret | 密钥：加密存储的敏感信息 |
| Matrix | Matrix | 矩阵：多版本/多平台并行测试策略 |
| SAST | Static Application Security Testing | 静态安全测试：扫描源代码中的漏洞 |
| SCA | Software Composition Analysis | 软件成分分析：检查第三方依赖漏洞 |
| DAST | Dynamic Application Security Testing | 动态安全测试：运行时检测安全问题 |
| MTTR | Mean Time To Recovery | 平均恢复时间 |
| Idempotent | Idempotent | 幂等性：多次执行结果与一次相同 |
| Rollback | Rollback | 回滚：部署失败后恢复到上一版本 |
| Canary | Canary Release | 金丝雀发布：先向少量用户发布新版本 |
| Blue-Green | Blue-Green Deployment | 蓝绿部署：两套环境切换实现零停机 |

---

## 第 12 章 · 参考资料与复核

### 官方文档（权威来源）

1. **Jenkins 官方文档** - [Pipeline Syntax Reference](https://www.jenkins.io/doc/book/pipeline/syntax/)
2. **GitLab CI/CD 文档** - [.gitlab-ci.yml 参考](https://docs.gitlab.com/ee/ci/yaml/)
3. **GitHub Actions 文档** - [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
4. **Docker 最佳实践** - [Dockerfile 参考](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

### 推荐书籍

1. 《持续交付：发布可靠软件的系统方法》 - Jez Humble & David Farley
2. 《DevOps 实践指南》 - Gene Kim 等
3. 《Accelerate》 - Nicole Forsgren 等（DORA 研究报告）

### 行业报告

- **DORA State of DevOps Report** - 年度 DevOps 状态报告，定义了四大关键指标
- **Accelerate 四大指标**：部署频率、变更前置时间、变更失败率、服务恢复时间

### 复核清单

- [ ] 所有代码示例语法正确，可直接使用
- [ ] Jenkins Pipeline 使用声明式语法（非脚本式）
- [ ] GitLab CI 配置包含缓存和 artifacts 策略
- [ ] GitHub Actions workflow 包含并发控制和矩阵策略
- [ ] 安全扫描集成在部署之前
- [ ] 密钥管理使用环境变量，无硬编码
- [ ] Docker 镜像使用多阶段构建，非 root 运行

---

## 第 13 章 · 内容元数据

```yaml
# 内容元数据
title: "DevOps 课程：CI/CD 流水线设计与实现"
version: "v2.0"
author: "DevOps 教学团队"
date_created: "2026-10-19"
date_updated: "2026-10-19"
language: "zh-CN"
difficulty: "初学者友好"
estimated_time: "3-4 小时"
prerequisites:
  - "Git 基础操作"
  - "Linux 命令行基础"
  - "基本的编程概念"
tags:
  - DevOps
  - CI/CD
  - Jenkins
  - GitLab CI
  - GitHub Actions
  - Pipeline
  - Docker
  - DevSecOps
  - 自动化部署
learning_objectives:
  - "理解 CI/CD 的核心概念和价值"
  - "掌握流水线设计原则和阶段划分策略"
  - "能够编写 Jenkins、GitLab CI、GitHub Actions 配置文件"
  - "了解流水线性能优化方法"
  - "掌握 DevSecOps 安全集成实践"
  - "能够设计完整的 Node.js 项目 CI/CD 流水线"
image_path: "images/devops_cicd_pipeline.webp"
related_courses:
  - "Docker 容器化实战"
  - "Kubernetes 入门与进阶"
  - "基础设施即代码（Terraform）"
  - "监控与可观测性"
```

---

## 复习清单

完成本课程学习后，请确认你能够：

- [ ] **概念理解**：用自己的话解释 CI、CD（交付 vs 部署）、Pipeline 的区别
- [ ] **工具使用**：能够独立编写 Jenkinsfile / .gitlab-ci.yml / GitHub Actions workflow
- [ ] **设计能力**：为一个新项目设计合理的流水线阶段划分和并行策略
- [ ] **性能优化**：说出至少 3 种加速流水线的方法（缓存、并行、增量构建等）
- [ ] **安全意识**：知道如何在流水线中集成安全扫描，以及密钥管理的最佳实践
- [ ] **实战经验**：完成 Node.js 项目完整 CI/CD 流水线的搭建和调试
- [ ] **故障排查**：能够分析流水线失败原因并修复（查看日志、定位问题阶段）
- [ ] **知识关联**：理解 CI/CD 与 Git 分支策略、容器化、监控之间的关系

---

> 📌 **学习建议**：先通读全文理解概念，然后动手实践代码示例。建议从 GitHub Actions 开始（配置最简单），再学习 GitLab CI，最后挑战 Jenkins（功能最强但配置最复杂）。
>
> 🎯 **下一步**：完成本课程后，建议继续学习 Docker 容器化和 Kubernetes 编排，这些是 CI/CD 流水线的下游技术。
