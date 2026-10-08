# 实战：Spring Boot REST API

![Spring Boot 应用的分层结构](images/diagram_spring_layers.webp)

![实战：Spring Boot REST API](images/remaining_java_project.webp)

> 内容更新时间：2026-10-06 · 学习阶段：高级 · 预计用时：135 分钟

## 本节知识框架

**课程定位**：所属分类为「Java」，课程主题为「实战：Spring Boot REST API」，学习阶段为「高级」，建议用时 135 分钟。

**本课要解决的主问题**：分层结构、依赖注入、校验与集成测试。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「实战：Spring Boot REST API」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「实战：Spring Boot REST API」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「实战」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《构建、测试与生态》

**学习位置**：本课位于《多线程与并发》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《实战：Java 库存管理 REST 服务》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释实战：Spring Boot REST API解决了什么问题，而不是只背术语。
- 能说清 「实战」、「Spring Boot」、「REST」、「依赖注入」 之间的关系，并分别举出一个例子。
- 能把 实战 放回「实战：Spring Boot REST API」的知识体系，说明它和 Spring Boot 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：分层结构、依赖注入、校验与集成测试。

**教材衔接：前置知识**

- 先完成上一课《构建、测试与生态》；如果已经掌握，可以直接用本课练习自测。
- 开始前先复习：实战、Spring Boot、REST。
- 卡在 实战 上时不要跳过：把输入、预期和实际输出写成三行，再回头读正文。

**教材衔接：本课小结**

Spring Boot 的关键是**分层 + 依赖注入 + 约定优于配置**：controller 薄、service 厚、repository 只负责数据。

## 核心概念定义

> 阅读约定：本课先给「实战：Spring Boot REST API」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| record | record 天生适合做 API 的请求/响应模型；@NotBlank、@Min 由 Bean Validation 在入口处自动校验。 | 仅在「实战：Spring Boot REST API」明确给出的输入、版本与资源条件下成立。 |
| 实战 | 实战：Spring Boot REST API解决了什么问题，而不是只背术语。 | 仅在「实战：Spring Boot REST API」明确给出的输入、版本与资源条件下成立。 |
| REST | 以资源 URI、HTTP 方法和状态码组织接口的无状态风格。 | 仅在「实战：Spring Boot REST API」明确给出的输入、版本与资源条件下成立。 |
| 测试 | 用可重复的输入和断言验证代码行为是否符合预期。 | 仅在「实战：Spring Boot REST API」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「实战：Spring Boot REST API」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

**教材衔接：数据模型与校验**

```java
public record User(Long id, @NotBlank String name, @Min(0) int age) { }
```

`record` 天生适合做 API 的请求/响应模型；`@NotBlank`、`@Min` 由 Bean Validation 在入口处自动校验。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「record」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「实战」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「REST」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「实战：Spring Boot REST API」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | record | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | 实战 | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | REST | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「实战：Spring Boot REST API」自己的示例验证。「实战：Spring Boot REST API」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：上线前检查**

1. 统一异常处理（`@RestControllerAdvice`）返回一致的错误结构。
2. 日志用 SLF4J，禁止打印敏感字段。
3. 配置外部化（`application-{env}.yml` + 环境变量）。
4. 用 Actuator 暴露健康检查，接入监控。

**教材衔接：分层职责速查**

| 层 | 职责 | 不该做的事 |
| --- | --- | --- |
| Controller | 参数绑定、校验、返回状态码 | 写业务规则、拼 SQL |
| Service | 业务规则、事务边界、编排 | 直接依赖 HTTP 对象 |
| Repository | 数据访问 | 写业务判断 |
| DTO | 对外数据结构 | 直接暴露实体与敏感字段 |
| Entity | 持久化模型 | 承担接口返回格式 |

JPA 与事务速查：

| 目的 | 写法 |
| --- | --- |
| 查询单条 | `findById(id)` 返回 `Optional` |
| 条件查询 | `findByStatusAndCreatedAtAfter(...)` |
| 分页 | `PageRequest.of(page, size, Sort.by("createdAt").descending())` |
| 避免 N+1 | `@EntityGraph` 或 `join fetch` |
| 只读事务 | `@Transactional(readOnly = true)` |
| 更新并返回 | `saveAndFlush` 或 `@Modifying` 批量更新 |
| 乐观锁 | `@Version` 字段 + 捕获冲突后重试 |
| 迁移 | Flyway / Liquibase 管理脚本 |

**教材衔接：版本与时效**

- 先确认运行环境是 Java 21 还是 25，再决定 UserService 能否使用新语法。
- 升级收益集中在并发与内存模型；Spring Boot 相关代码需要单独回归。
- 升级前确认 实战 的兼容范围，把不可回退的改动单独拆成一次提交。

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改 实战 的版本变量，记录编译、测试与产物体积的变化。
- 回归范围锁定 UserService 的默认行为，并确认弃用警告是否出现在构建输出里。
- 升级完成后记录 实战 的新旧版本差异，并据此调整下次复核时间。

**教材衔接：交付评审：评分表、决策记录与证据链**

「实战：Spring Boot REST API」的验收不能只看功能能不能跑通。下面把正文里的交付物、验证命令和关键设计点整理成一张评审表，按表逐项留下证据即可。

### 一、「实战：Spring Boot REST API」的交付物评分表

| 交付物 | 权重 | 合格线 | 需要的证据 |
| --- | ---: | --- | --- |
| 核心链路 | 34% | 能在干净环境复现，且失败路径有明确处理 | 命令与输出、对应测试、一次失败与恢复记录 |
| 测试与验收记录 | 33% | 能在干净环境复现，且失败路径有明确处理 | 命令与输出、对应测试、一次失败与恢复记录 |
| 运行与回滚说明 | 33% | 能在干净环境复现，且失败路径有明确处理 | 命令与输出、对应测试、一次失败与恢复记录 |

「实战：Spring Boot REST API」的评分先看证据再打分：任意一项只要拿不出可复现的命令或测试，该项按 0 分计，不允许用「基本完成」代替。

### 二、需要写下来的决策（ADR）

| 决策点 | 本课给出的做法 | 备选方案 | 代价与回滚 |
| --- | --- | --- | --- |
| 架构与数据流 | 用户/输入 → 接口或命令 → 领域逻辑 → 存储/外部依赖 → 输出与监控 | 不做「架构与数据流」，沿用最朴素的实现（需要额外补一次对照实验） | 若「架构与数据流」出问题，回到上一版本并按本课验收场景重跑 |

ADR 不需要长：每个决策三行就够——选了什么、放弃了什么、出问题怎么退。评审时只检查这三行是否和「实战：Spring Boot REST API」的实际代码一致。

### 三、「实战：Spring Boot REST API」的交付证据链

本课未给出可执行命令，用下面的最小证据集代替：

1. 一条从零开始的环境准备命令。
2. 一条跑通核心链路的命令及其完整输出。
3. 一条触发失败的命令，以及恢复后的验证结果。

把「实战：Spring Boot REST API」的上表整理成一个 evidence/ 目录：每条命令一个文件，文件名带日期，内容包含版本、命令与输出。评审时直接按目录核对，不再口头确认。

### 四、「实战：Spring Boot REST API」的验收指标

| 指标 | 目标值 | 测量方式 | 不达标时的动作 |
| --- | --- | --- | --- |
| 实战 的核心路径耗时与失败率 | 用本课正文给出的阈值，没有就写实测基线 | 固定环境重复三次取中位数 | 回到对应小节定位，先修原因再重测 |
| 资源占用峰值与回收情况 | 用本课正文给出的阈值，没有就写实测基线 | 固定环境重复三次取中位数 | 回到对应小节定位，先修原因再重测 |
| 验收场景的通过率 | 用本课正文给出的阈值，没有就写实测基线 | 固定环境重复三次取中位数 | 回到对应小节定位，先修原因再重测 |

指标必须能用一条命令或一次操作测出来；写不出测量方式的指标，在「实战：Spring Boot REST API」的评审里一律视为未定义。

### 五、评审记录模板

| 记录项 | 填写要求 |
| --- | --- |
| 项目标识 | `java_project` |
| 本次范围 | 说明这一轮交付了「实战：Spring Boot REST API」的哪些部分 |
| 未完成项 | 列出与 实战 相关但本轮未做的内容 |
| 证据位置 | 指向 evidence/ 目录下的具体文件 |
| 风险与回滚 | 写清剩余风险、回滚步骤和验证方式 |
| 结论 | 通过 / 有条件通过 / 不通过，三者选一 |

「实战：Spring Boot REST API」评审结束后把这张表填完并归档；下一轮迭代直接读上一次的「未完成项」与「风险与回滚」，避免重复讨论同一个问题。
<!-- p1-project-review:end -->

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 实战、Spring Boot | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「实战：Spring Boot REST API」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「实战：Spring Boot REST API」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**课程内置实验入口**：`sandbox:java`，用于动手验证《实战：Spring Boot REST API》的机制；实验结论不替代概念定义与复杂度分析。

**教材衔接：项目结构**

```text
src/main/java/com/example/demo/
├── DemoApplication.java
├── controller/UserController.java
├── service/UserService.java
├── repository/UserRepository.java
└── model/User.java
```

分层职责：controller 处理 HTTP、service 承载业务、repository 访问数据、model 表达数据结构。

**教材衔接：零基础详解：Java 项目实战骨架**

### 一句话说清它是什么

一个可交付的 Java 服务要分层清晰、配置外置、能探活、能优雅关闭、有测试、能打包成镜像。
下面用「订单服务」把整套骨架走一遍。

### 用生活比喻理解

| 层 | 比喻 | 职责 |
| --- | --- | --- |
| Controller | 前台 | 收请求、校验、返回 |
| Service | 后厨 | 业务规则与事务 |
| Repository | 仓库 | 只跟数据库打交道 |
| DTO | 表单 | 对外数据结构 |
| Entity | 库存台账 | 与表结构对应 |

### 包结构

```text
src/main/java/com/example/order/
  OrderApplication.java
  controller/OrderController.java
  service/OrderService.java
  repository/OrderRepository.java
  domain/Order.java
  dto/CreateOrderRequest.java
  config/AppConfig.java
  exception/GlobalExceptionHandler.java
src/main/resources/
  application.yml
  application-prod.yml
src/test/java/...
```

**要点**：DTO 与 Entity 分开，不要让接口结构跟着表结构走。

### 分层写法

```java
@RestController
@RequestMapping("/api/orders")
public class OrderController {
    private final OrderService service;

    public OrderController(OrderService service) {   // 构造注入，便于测试
        this.service = service;
    }

    @PostMapping
    public ResponseEntity<OrderView> create(@Valid @RequestBody CreateOrderRequest req) {
        OrderView view = service.create(req);
        return ResponseEntity.status(HttpStatus.CREATED).body(view);
    }
}

@Service
public class OrderService {
    private final OrderRepository repository;

    public OrderService(OrderRepository repository) {
        this.repository = repository;
    }

    @Transactional
    public OrderView create(CreateOrderRequest req) {
        if (req.quantity() <= 0) {
            throw new IllegalArgumentException("数量必须为正");
        }
        Order saved = repository.save(Order.from(req));
        return OrderView.from(saved);
    }
}
```

```java
public record CreateOrderRequest(
        @NotBlank String customer,
        @Positive int quantity) {}

public record OrderView(long id, String customer, int quantity, String status) {
    static OrderView from(Order order) {
        return new OrderView(order.getId(), order.getCustomer(),
                             order.getQuantity(), order.getStatus().name());
    }
}
```

### 统一异常处理：别把堆栈返回给用户

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ApiError onValidation(MethodArgumentNotValidException ex) {
        List<String> issues = ex.getBindingResult().getFieldErrors().stream()
                .map(e -> e.getField() + ": " + e.getDefaultMessage())
                .toList();
        return new ApiError("参数不合法", "VALIDATION_FAILED", issues);
    }

    @ExceptionHandler(OrderNotFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public ApiError onNotFound(OrderNotFoundException ex) {
        return new ApiError(ex.getMessage(), "ORDER_NOT_FOUND", List.of());
    }

    @ExceptionHandler(Exception.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public ApiError onUnexpected(Exception ex) {
        log.error("未预期异常", ex);              // 细节只进日志
        return new ApiError("服务内部错误", "INTERNAL_ERROR", List.of());
    }
}

public record ApiError(String message, String code, List<String> issues) {}
```

### 配置外置与校验

```yaml
# application.yml
server:
  port: ${PORT:8080}
  shutdown: graceful          # 优雅关闭

spring:
  datasource:
    url: ${DB_URL}
    username: ${DB_USER}
    password: ${DB_PASSWORD}
  lifecycle:
    timeout-per-shutdown-phase: 20s

app:
  retry:
    max-attempts: ${RETRY_MAX:3}
```

```java
@ConfigurationProperties(prefix = "app.retry")
@Validated
public record RetryProperties(
        @Min(1) @Max(10) int maxAttempts) {}
```

**启动时校验配置**，而不是运行到一半才发现缺变量。

### 健康检查与指标

```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  endpoint:
    health:
      probes:
        enabled: true          # 提供 /healthz/live 与 /healthz/ready
```

### 测试三层

```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {
    @Mock OrderRepository repository;
    @InjectMocks OrderService service;

    @Test
    void 数量为零时抛出异常() {
        var req = new CreateOrderRequest("小明", 0);
        assertThatThrownBy(() -> service.create(req))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("数量");
    }
}
```

| 层级 | 工具 | 覆盖 |
| --- | --- | --- |
| 单元测试 | JUnit 5 + Mockito | 业务规则 |
| 切片测试 | `@WebMvcTest` | 控制器与序列化 |
| 集成测试 | `@SpringBootTest` + Testcontainers | 数据库与外部依赖 |

### 打包成镜像

```dockerfile
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY target/app.jar app.jar
RUN useradd -r -u 1001 appuser && chown -R appuser /app
USER appuser
EXPOSE 8080
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-jar", "/app/app.jar"]
```

| 参数 | 作用 |
| --- | --- |
| `MaxRAMPercentage` | 容器里按比例限制堆，避免被 OOM Kill |
| `USER` | 非 root 运行 |
| `shutdown: graceful` | 发布时不中断在途请求 |

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| Entity 直接当接口返回 | 泄露字段、耦合表结构 | 用 DTO 转换 |
| 用字段注入 | 循环依赖、难测试 | 用构造注入 |
| 把异常堆栈返回给用户 | 泄露实现细节 | 统一异常处理 |
| 事务加在 Controller | 事务边界不清 | 加在 Service 方法 |
| 配置硬编码 | 换环境要改代码 | 用环境变量与 profile |
| 忘了 graceful shutdown | 发布时 502 | 开启并设置超时 |
| 用 `System.out` 打日志 | 无法分级与采集 | 用 SLF4J |
| 容器里堆内存不限 | 被 OOM Kill | 设置 `MaxRAMPercentage` |

### 学完自测

- [ ] 能说出 Controller、Service、Repository 各自的职责。
- [ ] 知道为什么 DTO 要与 Entity 分开。
- [ ] 能说出构造注入相比字段注入的优势。
- [ ] 知道为什么要开启 graceful shutdown。
- [ ] 能说出容器里限制堆内存的参数。

**教材衔接：项目专属规格：实战：Spring Boot REST API**

### 核心场景

分层结构、依赖注入、校验与集成测试。 项目目标是把「实战、Spring Boot、REST、依赖注入、测试」落实为可运行、可测试、可回滚的交付物。

### 架构与数据流

```text
用户/输入 → 接口或命令 → 领域逻辑 → 存储/外部依赖 → 输出与监控
                         ↘ 失败分类 → 重试/补偿 → 回滚
```

### 最小数据模型

| 对象 | 关键字段 | 约束 |
| --- | --- | --- |
| 输入实体 | 实战、时间、来源 | 必填校验、长度限制、幂等键 |
| 任务实体 | 状态、优先级、创建时间 | 状态迁移合法、不可重复执行 |
| 结果实体 | 输出、错误码、耗时 | 可序列化、错误可解释 |
| 审计记录 | 操作者、动作、结果、时间 | 不可篡改、可查询、脱敏 |

### 验收场景

1. 正常路径：最小输入得到预期输出，并留下日志与指标。
2. 边界路径：实战 的空值、最大值、重复数据和超长内容都得到明确处理。
3. 失败路径：依赖超时或不可用时能快速失败、重试或降级。
4. 幂等路径：同一请求执行两次不会产生重复副作用。
5. 回滚路径：Spring Boot 的失败能按预案恢复，并记录影响范围。

**教材衔接：项目交付物**

### 建议仓库结构

```text
src/main/java/
src/main/resources/
src/test/java/
pom.xml
README.md
```

### 测试矩阵

| 层级 | 覆盖内容 | 最低数量 | 通过标准 |
| --- | --- | ---: | --- |
| 单元测试 | 领域规则、边界和错误分类 | 8 | 正常、边界、失败路径全部通过 |
| 集成测试 | 数据库、网络、文件或平台边界 | 3 | 使用真实边界且可重复运行 |
| 端到端测试 | 核心用户路径 | 1 | 从输入到输出完整跑通 |
| 手动验收 | 文档中列出的 5 个场景 | 5 | 有命令、输出和结论记录 |

### 验收数据

```json
{
  "project": "java_project",
  "scenario": "实战的正常路径",
  "input": {"case": "normal", "value": "UserService"},
  "expected": {"ok": true, "checks": ["实战可复现", "Spring Boot有记录"]},
  "failure_case": {"case": "Spring Boot越界或缺失", "error": "validation_error"},
  "idempotency_key": "java_project-001"
}
```

### 复盘模板

| 问题 | 记录 |
| --- | --- |
| 原目标是什么？ | 用一句话描述可验收目标 |
| 实际发生了什么？ | 时间线、指标和关键日志 |
| 哪个假设被推翻？ | 根因与促成因素 |
| 如何回滚？ | 步骤、耗时和数据校验 |
| 下一步做什么？ | 负责人、期限和验证方式 |

> 项目验收围绕「实战、Spring Boot、REST」：至少完成一次正常路径、一次边界输入、一次失败恢复和一次幂等检查。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《实战：Spring Boot REST API》原文中的最小示例。先预测《实战：Spring Boot REST API》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```text
src/main/java/com/example/demo/
├── DemoApplication.java
├── controller/UserController.java
├── service/UserService.java
├── repository/UserRepository.java
└── model/User.java
```

**教材衔接：依赖与配置**

```xml
<dependencies>
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
  </dependency>
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-validation</artifactId>
  </dependency>
</dependencies>
```

```properties
server.port=8080
spring.jackson.default-property-inclusion=non_null
```

**教材衔接：服务与控制器**

```java
@Service
public class UserService {
    private final Map<Long, User> store = new ConcurrentHashMap<>();
    private final AtomicLong ids = new AtomicLong();

    public List<User> findAll() { return List.copyOf(store.values()); }

    public User create(String name, int age) {
        long id = ids.incrementAndGet();
        User user = new User(id, name, age);
        store.put(id, user);
        return user;
    }

    public Optional<User> findById(long id) { return Optional.ofNullable(store.get(id)); }
}

@RestController
@RequestMapping("/api/users")
public class UserController {
    private final UserService service;

    public UserController(UserService service) { this.service = service; }   // 构造器注入

    @GetMapping
    public List<User> list() { return service.findAll(); }

    @GetMapping("/{id}")
    public User get(@PathVariable long id) {
        return service.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public User create(@Valid @RequestBody User request) {
        return service.create(request.name(), request.age());
    }
}
```

**教材衔接：测试**

```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class UserControllerTest {
    @Autowired TestRestTemplate rest;

    @Test
    void createsAndFetchesUser() {
        User created = rest.postForObject("/api/users", new User(null, "tom", 18), User.class);
        assertThat(created.id()).isNotNull();
        assertThat(rest.getForObject("/api/users/" + created.id(), User.class).name()).isEqualTo("tom");
    }
}
```

**教材衔接：Spring Boot 注解速查**

| 注解 | 作用 |
| --- | --- |
| `@SpringBootApplication` | 启动类，组合配置与组件扫描 |
| `@RestController` | REST 控制器，返回值序列化为 JSON |
| `@RequestMapping` / `@GetMapping` / `@PostMapping` | 路由映射 |
| `@PathVariable` / `@RequestParam` | 路径变量 / 查询参数 |
| `@RequestBody` | 请求体绑定为对象 |
| `@Valid` / `@Validated` | 触发参数校验 |
| `@Service` / `@Repository` / `@Component` | 组件声明 |
| `@Configuration` + `@Bean` | 手动声明 Bean |
| `@Autowired` | 注入（推荐构造器注入，可省略该注解） |
| `@Transactional` | 事务边界 |
| `@ControllerAdvice` + `@ExceptionHandler` | 全局异常处理 |
| `@ConfigurationProperties` | 绑定配置项 |

```java
@RestController
@RequestMapping("/api/orders")
public class OrderController {
    private final OrderService service;

    // 构造器注入：依赖不可变、便于测试
    public OrderController(OrderService service) {
        this.service = service;
    }

    @GetMapping("/{id}")
    public OrderResponse get(@PathVariable long id) {
        return service.findById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public OrderResponse create(@Valid @RequestBody CreateOrderRequest request) {
        return service.create(request);
    }
}

@RestControllerAdvice
class GlobalExceptionHandler {
    @ExceptionHandler(OrderNotFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    ErrorResponse handleNotFound(OrderNotFoundException ex) {
        return new ErrorResponse("ORDER_NOT_FOUND", ex.getMessage());
    }
}
```

**教材衔接：验证命令与预期输出**

实战 的交付物要能用固定命令复现；下表是本项目的最低验证集：

| 阶段 | 命令 | 预期输出 |
| --- | --- | --- |
| 编译 | `./mvnw -q -DskipTests package` | 生成 JAR 且编译无错误 |
| 运行测试 | `./mvnw test` | JUnit 测试全部通过 |
| 启动服务 | `java -jar target/app.jar` | 端口监听成功并输出启动日志 |

### 验收证据

- [ ] 保存依赖安装和启动命令的完整输出。
- [ ] 测试覆盖 Spring Boot 的核心规则，并包含一次可预期的失败。
- [ ] 连续两次触发 Spring Boot，检查数据与计数是否被重复累加。
- [ ] 记录一次失败状态码、错误日志和恢复步骤。
- [ ] 在 README 中写明 实战 所需的环境版本、启动方式和回滚方式。

### 回归与回滚

1. 用临时环境验证 UserService，确认无误后再对真实数据执行。
2. 修改一处逻辑后重跑全部验证命令，确认没有回归。
3. 若失败，回滚到上一个可运行版本并保留失败日志。
4. 定位原因后补一条自动化测试，再重新执行发布流程。
5. 把教训写入项目复盘或本课笔记，形成下一次的检查项。

## 时间/空间复杂度或性能分析

**复杂度证据**：「实战：Spring Boot REST API」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「实战：Spring Boot REST API」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「实战：Spring Boot REST API」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

## 常见误区与易错点

> 复核《实战：Spring Boot REST API》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「实战：Spring Boot REST API」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| Controller 直接返回实体 | 暴露敏感字段、循环序列化 | 用 DTO 转换 |
| 字段注入 `@Autowired` | 难以测试、隐藏依赖 | 用构造器注入 |
| 事务方法内部 `try/catch` 吞异常 | 事务不回滚 | 只捕获需要处理的异常，或手动标记回滚 |
| 同类内部方法调用事务方法 | 事务不生效 | 通过代理调用，或拆分 Bean |
| 忘记 `@Transactional` | 多次写入出现半成功 | 在 Service 层声明事务 |
| `@Transactional` 方法里发网络请求 | 事务变长、连接占用 | 外部调用放在事务外 |
| 实体关联默认急加载 | 查询变慢、笛卡尔积 | 按需设置 `FetchType.LAZY` 并用 `join fetch` |
| 拼接 SQL 字符串 | 注入风险 | 用参数绑定或 Spring Data 方法命名 |
| 用 `application.properties` 存密钥 | 泄漏 | 用环境变量或配置中心 |
| 参数校验靠手写 if | 代码重复、遗漏 | 用 `@Valid` + 注解 |
| 用 500 返回业务错误 | 客户端无法区分 | 用 `@ControllerAdvice` 映射合适状态码 |

**教材衔接：故障现场**

### 现场 1：Controller 直接返回实体

**症状**：在《实战：Spring Boot REST API》的复现场景中，暴露敏感字段、循环序列化。

**根因**：当出现“Controller 直接返回实体”时，执行路径已经绕过了《实战：Spring Boot REST API》的关键约束，最终以“暴露敏感字段、循环序列化”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《实战：Spring Boot REST API》的问题，用 DTO 转换。

**验证**：在《实战：Spring Boot REST API》中按“用 DTO 转换”调整后，从“Controller 直接返回实体”的触发条件重放同一条路径，确认“暴露敏感字段、循环序列化”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 2：字段注入 @Autowired

**症状**：在《实战：Spring Boot REST API》的复现场景中，难以测试、隐藏依赖。

**根因**：当出现“字段注入 @Autowired”时，执行路径已经绕过了《实战：Spring Boot REST API》的关键约束，最终以“难以测试、隐藏依赖”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《实战：Spring Boot REST API》的问题，用构造器注入。

**验证**：在《实战：Spring Boot REST API》中按“用构造器注入”调整后，从“字段注入 @Autowired”的触发条件重放同一条路径，确认“难以测试、隐藏依赖”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 3：忘记 @Transactional

**症状**：在《实战：Spring Boot REST API》的复现场景中，多次写入出现半成功。

**根因**：当出现“忘记 @Transactional”时，执行路径已经绕过了《实战：Spring Boot REST API》的关键约束，最终以“多次写入出现半成功”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《实战：Spring Boot REST API》的问题，在 Service 层声明事务。

**验证**：先在《实战：Spring Boot REST API》中记录“忘记 @Transactional”留下的失败证据，再执行“在 Service 层声明事务”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《构建、测试与生态》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《实战：Java 库存管理 REST 服务》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《多线程与并发》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《实战：Java 库存管理 REST 服务》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「实战：Spring Boot REST API」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《实战：Spring Boot REST API》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

围绕“实战：Spring Boot REST API”中的 实战、Spring Boot、REST，下列哪两项是本课强调的实践判断？

A. 验证 Spring Boot 时要固定版本并覆盖边界输入，结论才可复现
B. 把 Spring Boot 的单次运行结果当成所有版本和规模都成立
C. 学习 实战 时要同时说明输入、输出和失败路径，不能只看正常流程
D. 只要 实战 的常规示例通过，就可以跳过边界与异常路径

**参考答案**：验证 Spring Boot 时要固定版本并覆盖边界输入，结论才可复现；学习 实战 时要同时说明输入、输出和失败路径，不能只看正常流程

**解析**：在「实战：Spring Boot REST API」里，学习 实战 时要同时说明输入、输出和失败路径，不能只看正常流程。在实战：Spring Boot REST API里，判断 Spring Boot 时要固定版本与边界输入，所以“验证 Spring Boot 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 自测 2

使用构造器注入的主要好处是？

A. 提升运行速度
B. 避免继承
C. 代码更短
D. 依赖显式且便于测试

**参考答案**：依赖显式且便于测试

**解析**：在「实战：Spring Boot REST API」里，依赖显式且便于测试。构造器注入让依赖不可变、显式，单元测试可直接传入 mock。在「实战：Spring Boot REST API」里判断这道题，要把实战、Spring Boot、REST的条件、过程与失败路径逐项对齐，换成“使用构造器注入的主要好处是”这个场景，只有满足前提的结论才成立。

### 自测 3

下面这段 Java 代码摘自「实战：Spring Boot REST API」的正文示例。关于这段代码，下面哪一项说法与实际内容相符？

```java
@RestController
@RequestMapping("/api/orders")
public class OrderController {
    private final OrderService service;

    // 构造器注入：依赖不可变、便于测试
    public OrderController(OrderService service) {
        this.service = service;
    }

    @GetMapping("/{id}")
    public OrderResponse get(@PathVariable long id) {
        return service.findById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public OrderResponse create(@Valid @RequestBody CreateOrderRequest request) {
        return service.create(request);
    }
}

@RestControllerAdvice
class GlobalExceptionHandler {
    @ExceptionHandler(OrderNotFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    ErrorResponse handleNotFound(OrderNotFoundException ex) {
        return new ErrorResponse("ORDER_NOT_FOUND", ex.getMessage());
    }
}
```

A. 这段代码会读取外部输入，结果依赖传入的数据。
B. 这段代码会产生可观察的输出，运行后能看到结果。
C. 这段代码只做静态声明，没有循环、分支或可观察输出。
D. 这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。

**参考答案**：这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。

**解析**：在「实战：Spring Boot REST API」里，这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。这段代码出自「实战：Spring Boot REST API」的正文示例，围绕实战、Spring Boot、REST展开；把输入或边界换成空值、极值或失败情况后，结论要以「实战：Spring Boot REST API」的实际运行结果为准。

**教材衔接：复习与自测**

- [ ] 分层职责清晰，Controller 不写业务逻辑。
- [ ] 使用构造器注入，依赖不可变。
- [ ] 事务声明在 Service 层，且不包含网络调用。
- [ ] 用 DTO 隔离实体，避免暴露敏感字段。
- [ ] 数据库结构变更由迁移脚本管理。

**教材衔接：动手练习**

> 本课练习重点：围绕「实战、Spring Boot、REST」完成复述、实验和交付，每个结果都要能被别人检查。

先把 Spring Boot 的正常路径测通，再引入并发与异常。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 实战：Spring Boot REST API解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「Spring Boot」是什么关系？

验收标准：说明 实战 与 Spring Boot 的分工，并写出一个失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：先在「项目结构」里找一个可运行的最小输入，再按五步法记录实战的影响；预测与结果不一致时补写被忽略的前提。

### 练习 3：交付一个小结果（30 分钟）

写一个可运行的小类，补一个普通测试和一个边界输入测试。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「实战」和「Spring Boot」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

### 任务 1：先跑通，再解释

```xml
<dependencies>
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
  </dependency>
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-validation</artifactId>
  </dependency>
</dependencies>
```

**预期输出**：沙箱会解析并格式化实战：Spring Boot REST API中的这段 XML；请重点检查标签闭合、属性和嵌套层级。

### 任务 2：只改一个条件

把「实战：Spring Boot REST API」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：只调整 UserService 的一个参数，其余条件一律不动。
- 预测：先写下「实战：Spring Boot REST API」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响实战。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的 实战 数据，保持输出格式与任务 1 一致。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「在分层架构中，Controller 的职责是？」的判断依据。
- [ ] 不看解析，能说出「使用构造器注入的主要好处是？」的判断依据。
- [ ] 不看解析，能说出「@Valid 注解在 @RequestBody 上的作用是？」的判断依据。
- [ ] 不看解析，能说出「@RestController 与 @Controller 的差别是？」的判断依据。
- [ ] 不看解析，能说出「JPA 中 N+1 查询问题的常见解法是？」的判断依据。
- [ ] 跑通「实战：Spring Boot REST API」的最小示例，并记录一次失败输入的处理方式。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

---

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `record` | `record` 天生适合做 API 的请求/响应模型；`@NotBlank`、`@Min` 由 Bean Validation 在入口处自动校验。 |
| `实战` | 实战：Spring Boot REST API解决了什么问题，而不是只背术语。 |
| `REST` | 以资源 URI、HTTP 方法和状态码组织接口的无状态风格。 |
| `测试` | 用可重复的输入和断言验证代码行为是否符合预期。 |

## 考点精讲

### 考点 1：多选辨析·实战

- **题目**：围绕“实战：Spring Boot REST API”中的 实战、Spring Boot、REST，下列哪两项是本课强调的实践判断？
- **判断依据**：在「实战：Spring Boot REST API」里，学习 实战 时要同时说明输入、输出和失败路径，不能只看正常流程。在实战：Spring Boot REST API里，判断 Spring Boot 时要固定版本与边界输入，所以“验证 Spring Boot 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 2：概念判断·实战

- **题目**：使用构造器注入的主要好处是？
- **判断依据**：在「实战：Spring Boot REST API」里，依赖显式且便于测试。构造器注入让依赖不可变、显式，单元测试可直接传入 mock。在「实战：Spring Boot REST API」里判断这道题，要把实战、Spring Boot、REST的条件、过程与失败路径逐项对齐，换成“使用构造器注入的主要好处是”这个场景，只有满足前提的结论才成立。

### 考点 3：代码补全·实战

- **题目**：下面这段 Java 代码摘自「实战：Spring Boot REST API」的正文示例。关于这段代码，下面哪一项说法与实际内容相符？
- **判断依据**：在「实战：Spring Boot REST API」里，这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。这段代码出自「实战：Spring Boot REST API」的正文示例，围绕实战、Spring Boot、REST展开；把输入或边界换成空值、极值或失败情况后，结论要以「实战：Spring Boot REST API」的实际运行结果为准。

### 考点 4：概念判断·实战

- **题目**：@RestController 与 @Controller 的差别是？
- **判断依据**：在「实战：Spring Boot REST API」里，结论应落在「@RestController 默认返回 JSON」。返回视图页面时用 @Controller，写 REST API 时用 @RestController 更省事。记忆要点：看返回值是要渲染视图，还是要直接写入响应体。

### 考点 5：概念判断·实战

- **题目**：JPA 中 N+1 查询问题的常见解法是？
- **判断依据**：在「实战：Spring Boot REST API」里，用 join fetch / @EntityGraph 一次性预加载关联数据。N+1 的典型现象是 1 条主查询 + N 条关联查询，用批量抓取或联表抓取可以解决。把“用 join fetch / @Enti”代回「实战：Spring Boot REST API」里“JPA 中 N+1 查询问题的常见解法是”的例子核对，条件一旦改变，结论就要用实战、Spring Boot、REST重新推导。

### 考点 6：填空·实战

- **题目**：补全代码：「实战：Spring Boot REST API」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `@____(prefix = "app.retry")`
- **判断依据**：空格应填写「ConfigurationProperties」、「configurationproperties」。这道题的关键在「实战：Spring Boot REST API」的实战、Spring Boot、REST：先确认题干“补全代码”问的是哪一步，再排除偷换前提的选项。

## English Overview

**Title:** Project: Spring Boot API

**Summary:** Layering, DI, validation and integration tests.

**Category:** Java
**Level:** 高级
**Key terms:** 实战, Spring Boot, REST, 依赖注入, 测试

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：高级
- 适用环境：Java 21+ / Maven 或 Gradle
；本课聚焦 实战。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：实战、Spring Boot、REST、依赖注入、测试
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## Full English Study Guide

### Overview

**Project: Spring Boot API** focuses on Layering, DI, validation and integration tests.

### Learning Outcomes

- Explain what **Project: Spring Boot API** solves and when it should be used.

### Glossary

- Topic: **Project: Spring Boot API**
- Related terms: 实战, Spring Boot, REST, 依赖注入

## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning objectives |
| 前置知识 | Prerequisites |
| 项目结构 | 项目结构 |
| 依赖与配置 | 依赖与配置 |
| 数据模型与校验 | 数据Model与校验 |
| 服务与控制器 | 服务与控制器 |
| 测试 | Testing |
| 上线前检查 | 上线前检查 |
| 本课小结 | Summary |
| Spring Boot 注解速查 | Spring Boot 注解速查 |

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-02-24
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Gradle 文档](https://docs.gradle.org/current/userguide/userguide.html) | 构建脚本与依赖管理 |
| [JUnit 用户指南](https://junit.org/junit5/docs/current/user-guide/) | 自动化测试与断言 |
| [dev.java 学习](https://dev.java/learn/) | 现代 Java 官方教程 |

> 「实战：Spring Boot REST API」的链接用于离线阅读后的延伸核对；App 不会自动联网。

<!-- p1-project-review:start -->
