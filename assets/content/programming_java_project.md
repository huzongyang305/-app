# 实战：Spring Boot REST API

![Spring Boot 应用的分层结构](images/diagram_spring_layers.webp)

![实战：Spring Boot REST API](images/remaining_java_project.webp)

> 内容更新时间：2026-10-06 · 学习阶段：高级 · 预计用时：110 分钟

## 本节知识框架

**课程定位**：所属分类 `java`（Java），课程主题 `实战：Spring Boot REST API`，学习阶段 高级，建议用时 135 分钟。

本课主线：分层结构、依赖注入、校验与集成测试。

**学完本课应当能够**
- 说清 `record` 与 `实战` 的含义与区别，并各举一个正例和一个反例。
- 用本课示例验证 `REST` 的行为，记录输入、输出与失败条件。
- 遇到「Entity 直接当接口返回」这类问题时，能说出触发条件与修复顺序。

### 从概念到验证的学习链条

1. `record`：先掌握 `record` 天生适合做 API 的请求/响应模型；`@NotBlank`、`@Min` 由 Bean Validation 在入口处自动校验，再用它解释 `实战` 为什么会出现。
2. `实战`：先掌握 实战：Spring Boot REST API解决了什么问题，而不是只背术语，再用它解释 `REST` 为什么会出现。
3. `REST`：先掌握 以资源 URI、HTTP 方法和状态码组织接口的无状态风格，再用它解释 `测试` 为什么会出现。
4. `测试`：先掌握 用可重复的输入和断言验证代码行为是否符合预期，再用它解释 本课示例的观察结果 为什么会出现。

**先修与衔接**：本课是「Java」分类的第 16 课。先修内容：《构建、测试与生态》。《构建、测试与生态》里的 `System.out.println`、`JUnit` 是本课的前提。相关或后续课程：《实战：Java 库存管理 REST 服务》。

### 完成判据

- **定义关**：不看正文也能说明 `record` 是 `record` 天生适合做 API 的请求/响应模型，`@NotBlank`、`@Min` 由 Bean Validation 在入口处自动校验，并指出一个反例。
- **机制关**：能按“输入 → 转换 → 输出 → 验证”复述 `实战：Spring Boot REST API`，而不是只背结论。
- **示例关**：能运行或推演 `实战：Spring Boot REST API` 的 `java` 示例，并说明一个真实出现的标识符或字面量。
- **证据关**：能指出 `实战：Spring Boot REST API` 示例里的 调用了 `User()`，并说明它支持或反驳了本课的哪一条结论。
- **排错关**：能复现 Entity 直接当接口返回，记录现象并按 用 DTO 转换 修复。
- **迁移关**：能把 `实战`、`Spring Boot`、`REST`、`依赖注入` 放进一个与 `实战：Spring Boot REST API` 不同的项目场景，并保持输入与验证条件可追踪。
- **复盘关**：学完 `实战：Spring Boot REST API` 后，用一句话写下仍然不确定的结论，并列出下一次验证需要的输入、环境和成功判据。

### 复习清单

- [ ] 能不看正文复述本课核心术语，并指出一个边界或反例。
- [ ] 能运行或推演本课示例，记录输入、输出与失败现象。
- [ ] 能完成一次自测，并把错题对照错误表定位原因。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| record | record 天生适合做 API 的请求/响应模型；@NotBlank、@Min 由 Bean Validation 在入口处自动校验。 | 不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。 |
| 实战 | 实战：Spring Boot REST API解决了什么问题，而不是只背术语。 | 不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。 |
| REST | 以资源 URI、HTTP 方法和状态码组织接口的无状态风格。 | 网络延迟、超时与版本协商会改变行为，只在真实链路或多版本客户端上验证才算数。 |
| 测试 | 用可重复的输入和断言验证代码行为是否符合预期。 | 易错：循环依赖、难测试；正确做法是用构造注入。 |

## 原理与运行机制

### 机制总览

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

### 一、「实战：Spring Boot REST API」的交付物评分表

| 交付物 | 权重 | 合格线 | 需要的证据 |
| --- | ---: | --- | --- |
| 核心链路 | 34% | 能在干净环境复现，且失败路径有明确处理 | 命令与输出、对应测试、一次失败与恢复记录 |
| 测试与验收记录 | 33% | 能在干净环境复现，且失败路径有明确处理 | 命令与输出、对应测试、一次失败与恢复记录 |
| 运行与回滚说明 | 33% | 能在干净环境复现，且失败路径有明确处理 | 命令与输出、对应测试、一次失败与恢复记录 |

「实战：Spring Boot REST API」的评分先看证据再打分：任意一项只要拿不出可复现的命令或测试，该项按 0 分计，不允许用「基本完成」代替。


### 三、「实战：Spring Boot REST API」的交付证据链

本课未给出可执行命令，用下面的最小证据集代替：


### 五、评审记录模板

| 记录项 | 填写要求 |
| --- | --- |
| 项目标识 | `java_project` |
| 本次范围 | 说明这一轮交付了「实战：Spring Boot REST API」的哪些部分 |
| 未完成项 | 列出与 实战 相关但本轮未做的内容 |
| 证据位置 | 指向 evidence/ 目录下的具体文件 |
| 风险与回滚 | 写清剩余风险、回滚步骤和验证方式 |
| 结论 | 通过 / 有条件通过 / 不通过，三者选一 |

### 机制拆解：每一步的输入、动作与输出

#### 1. `record`
- 输入：`实战`；本步把 `record` 天生适合做 API 的请求/响应模型；`@NotBlank`、`@Min` 由 Bean Validation 在入口处自动校验 当作判断规则。
- 动作：围绕 `record` 保留中间状态，并记录它与 `实战` 的对应关系。
- 输出：`实战`，它可以被下一段代码、测试或记录继续使用。
- `record` 的失败条件：不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。

#### 2. `实战`
- 输入：`record`；本步把 实战：Spring Boot REST API解决了什么问题，而不是只背术语 当作判断规则。
- 动作：围绕 `实战` 保留中间状态，并记录它与 `REST` 的对应关系。
- 输出：`REST`，它可以被下一段代码、测试或记录继续使用。
- `实战` 的失败条件：不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。

#### 3. `REST`
- 输入：`实战`；本步把 以资源 URI、HTTP 方法和状态码组织接口的无状态风格 当作判断规则。
- 动作：围绕 `REST` 保留中间状态，并记录它与 `测试` 的对应关系。
- 输出：`测试`，它可以被下一段代码、测试或记录继续使用。
- `REST` 的失败条件：网络延迟、超时与版本协商会改变行为，只在真实链路或多版本客户端上验证才算数。

#### 4. `测试`
- 输入：`REST`；本步把 用可重复的输入和断言验证代码行为是否符合预期 当作判断规则。
- 动作：围绕 `测试` 保留中间状态，并记录它与 `User` 的对应关系。
- 输出：`User`，它可以被下一段代码、测试或记录继续使用。
- `测试` 的失败条件：当用字段注入时，会出现循环依赖、难测试。

### 示例中的可观察事实

1. 调用了 `User()`；它对应的课程主题是 `实战：Spring Boot REST API`。
2. 调用了 `Min()`；它对应的课程主题是 `实战：Spring Boot REST API`。

### 复现实验记录

- 环境：`实战：Spring Boot REST API` 使用 `java` 示例，固定 `实战`、`Spring Boot`、`REST`、`依赖注入` 作为第一组条件。
- 首轮输入：先确认 调用了 `User()`，预测 `record` 会怎样变化。
- 基线观察：记录命令、输入、输出和错误原文，不用截图代替可复制的文本。
- 单变量修改：只改变 `实战`，观察 `测试` 是否仍满足定义。
- 失败注入：复现 Entity 直接当接口返回，确认现象是 泄露字段、耦合表结构。
- 记录结论：把“修改前、修改后、预期变化、实际变化”写成四列表，这样复盘 `实战：Spring Boot REST API` 时才能区分概念错误与实现错误。

## 典型应用场景

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

- **Entity 直接当接口返回**：典型现象是泄露字段、耦合表结构；正确做法是用 DTO 转换。
- **用字段注入**：典型现象是循环依赖、难测试；正确做法是用构造注入。
- **把异常堆栈返回给用户**：典型现象是泄露实现细节；正确做法是统一异常处理。
- **事务加在 Controller**：典型现象是事务边界不清；正确做法是加在 Service 方法。

### 最小验证场景

- 准备：保留 `java` 示例的原始输入，先记录 `实战：Spring Boot REST API` 的基线输出和完整运行命令。
- 观察：先核对 调用了 `User()`，再改变一个与 `record` 相关的条件。
- 判定：新结果与 `实战：Spring Boot REST API` 的基线不同不等于错误；只有当差异破坏了 `record` 的定义或错误表中的约束，才判定为失败。

### 选择与边界

- 使用 `record` 时，先满足它的定义：`record` 天生适合做 API 的请求/响应模型；`@NotBlank`、`@Min` 由 Bean Validation 在入口处自动校验；不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。
- 使用 `实战` 时，先满足它的定义：实战：Spring Boot REST API解决了什么问题，而不是只背术语；不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。
- 使用 `REST` 时，先满足它的定义：以资源 URI、HTTP 方法和状态码组织接口的无状态风格；网络延迟、超时与版本协商会改变行为，只在真实链路或多版本客户端上验证才算数。
- 使用 `测试` 时，先满足它的定义：用可重复的输入和断言验证代码行为是否符合预期；易错：循环依赖、难测试；正确做法是用构造注入。

## 代码/协议/SQL 示例

### 最小可验证示例

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

**运行方式**：运行 `实战：Spring Boot REST API` 的示例时，保存为 `.java` 后用 `javac` 编译、`java` 运行；注意类名与文件名一致。

### 示例精读：先找证据，再改一个条件

1. 调用了 `User()`；它出现在 `实战：Spring Boot REST API` 的示例中，阅读时先确认它前后各发生了什么。
2. 调用了 `Min()`；它出现在 `实战：Spring Boot REST API` 的示例中，阅读时先确认它前后各发生了什么。
- 在 `实战：Spring Boot REST API` 中与 `record` 对照：示例必须能支持 `record` 天生适合做 API 的请求/响应模型；`@NotBlank`、`@Min` 由 Bean Validation 在入口处自动校验，否则说明这一段还缺少实现或验证步骤。
- 在 `实战：Spring Boot REST API` 中与 `实战` 对照：示例必须能支持 实战：Spring Boot REST API解决了什么问题，而不是只背术语，否则说明这一段还缺少实现或验证步骤。
- 在 `实战：Spring Boot REST API` 中与 `REST` 对照：示例必须能支持 以资源 URI、HTTP 方法和状态码组织接口的无状态风格，否则说明这一段还缺少实现或验证步骤。
- 在 `实战：Spring Boot REST API` 中与 `测试` 对照：示例必须能支持 用可重复的输入和断言验证代码行为是否符合预期，否则说明这一段还缺少实现或验证步骤。

## 时间/空间复杂度或性能分析

**性能关注点（实战：Spring Boot REST API）**：JVM 预热与 GC 影响测量：记录吞吐、P99 延迟与堆占用，先跑预热再采样。

**本课特有开销（实战：Spring Boot REST API · 实战）**：并发度提高后要观察是否出现拐点：延迟上升而吞吐不增，说明瓶颈已转移。

**测量方法**：以 `实战：Spring Boot REST API` 的 `实战` 场景为对象，固定输入跑一遍记录基线，再把规模或并发度提高一个数量级复测；两次结果的差值与波动范围才是结论依据。

### 需要控制的变量与记录项

- `实战：Spring Boot REST API` 的 `实战`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `实战：Spring Boot REST API` 的 `Spring Boot`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `实战：Spring Boot REST API` 的 `REST`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `实战：Spring Boot REST API` 的 `依赖注入`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `实战：Spring Boot REST API` 的 `测试`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `实战：Spring Boot REST API` 中 `record` 的边界：不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。达到边界时不要外推，必须重新测量。
- `实战：Spring Boot REST API` 中 `实战` 的边界：不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。达到边界时不要外推，必须重新测量。
- `实战：Spring Boot REST API` 中 `REST` 的边界：网络延迟、超时与版本协商会改变行为，只在真实链路或多版本客户端上验证才算数。达到边界时不要外推，必须重新测量。
- `实战：Spring Boot REST API` 中 `测试` 的边界：易错：循环依赖、难测试；正确做法是用构造注入。达到边界时不要外推，必须重新测量。
- `实战：Spring Boot REST API` 的代码证据：先验证 调用了 `User()`，再记录该路径的输入规模与耗时；只看代码行数不能推出复杂度。

## 常见误区与易错点

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| Entity 直接当接口返回 | 泄露字段、耦合表结构 | 用 DTO 转换 |
| 用字段注入 | 循环依赖、难测试 | 用构造注入 |
| 把异常堆栈返回给用户 | 泄露实现细节 | 统一异常处理 |
| 事务加在 Controller | 事务边界不清 | 加在 Service 方法 |
| 配置硬编码 | 换环境要改代码 | 用环境变量与 profile |
| 忘了 graceful shutdown | 发布时 502 | 开启并设置超时 |
| 用 `System.out` 打日志 | 无法分级与采集 | 用 SLF4J |
| 容器里堆内存不限 | 被 OOM Kill | 设置 `MaxRAMPercentage` |
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
| 字段注入 @Autowired | 难以测试、隐藏依赖。 | 用构造器注入。 |
| 忘记 @Transactional | 多次写入出现半成功。 | 在 Service 层声明事务。 |

### 现场 1：Entity 直接当接口返回

**症状**：泄露字段、耦合表结构。

**根因与修复**：用 DTO 转换。

**自检**：在本课示例里复现「Entity 直接当接口返回」，改成用 DTO 转换后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 2：用字段注入

**症状**：循环依赖、难测试。

**根因与修复**：用构造注入。

**自检**：在本课示例里复现「用字段注入」，改成用构造注入后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 3：把异常堆栈返回给用户

**症状**：泄露实现细节。

**根因与修复**：统一异常处理。

**自检**：在本课示例里复现「把异常堆栈返回给用户」，改成统一异常处理后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 4：事务加在 Controller

**症状**：事务边界不清。

**根因与修复**：加在 Service 方法。

**自检**：在本课示例里复现「事务加在 Controller」，改成加在 Service 方法后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 5：配置硬编码

**症状**：换环境要改代码。

**根因与修复**：用环境变量与 profile。

**自检**：在本课示例里复现「配置硬编码」，改成用环境变量与 profile后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 6：忘了 graceful shutdown

**症状**：发布时 502。

**根因与修复**：开启并设置超时。

**自检**：在本课示例里复现「忘了 graceful shutdown」，改成开启并设置超时后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 7：用 `System.out` 打日志

**症状**：无法分级与采集。

**根因与修复**：用 SLF4J。

**自检**：在本课示例里复现「用 `System.out` 打日志」，改成用 SLF4J后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 8：容器里堆内存不限

**症状**：被 OOM Kill。

**根因与修复**：设置 `MaxRAMPercentage`。

**自检**：在本课示例里复现「容器里堆内存不限」，改成设置 `MaxRAMPercentage`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 9：Controller 直接返回实体

**症状**：暴露敏感字段、循环序列化。

**根因与修复**：用 DTO 转换。

**自检**：在本课示例里复现「Controller 直接返回实体」，改成用 DTO 转换后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

## 与其他知识点的关系

- **先修**：`构建、测试与生态`。本课默认这些内容已经掌握。
- **相关或后续**：`实战：Java 库存管理 REST 服务`。本课术语会在这些课程里继续使用。
- **术语归属**：`record`、`实战`、`REST` 的定义以本课「核心概念定义」为准，换到其他课程时先确认定义是否被改写。
- 同一分类的《实战：Java 库存管理 REST 服务》也涉及 `Spring Boot`；两课衔接时先确认这个术语的定义是否一致。

### 先修与后续术语接口

- `构建、测试与生态`：两者通过本分类的学习顺序衔接，阅读时重点比较各自的输入与失败条件。
- `实战：Java 库存管理 REST 服务`：共同关键词 `Spring Boot`。

### 容易混淆的相邻概念

- `record` 与 `实战`：前者强调 `record` 天生适合做 API 的请求/响应模型；`@NotBlank`、`@Min` 由 Bean Validation 在入口处自动校验；后者强调 实战：Spring Boot REST API解决了什么问题，而不是只背术语。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `实战` 与 `REST`：前者强调 实战：Spring Boot REST API解决了什么问题，而不是只背术语；后者强调 以资源 URI、HTTP 方法和状态码组织接口的无状态风格。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `REST` 与 `测试`：前者强调 以资源 URI、HTTP 方法和状态码组织接口的无状态风格；后者强调 用可重复的输入和断言验证代码行为是否符合预期。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。

## 自测题与参考答案

> 先独立作答，再对照参考答案；答案都能在本课正文、术语表或错误表里找到依据。

### 自测 1（概念复述）

不看正文，写出 `record` 的操作性定义，并说明它与 `实战` 的区别。

**参考答案**：`record` 天生适合做 API 的请求/响应模型；`@NotBlank`、`@Min` 由 Bean Validation 在入口处自动校验。

`实战` 的定位是：实战：Spring Boot REST API解决了什么问题，而不是只背术语；两者的差别要从适用对象与失败模式上说明。

### 自测 2（排错）

本课错误表记录了「Entity 直接当接口返回」这类做法。请写出它会出现的现象、根因，以及修复顺序。

**参考答案**：现象是泄露字段、耦合表结构；正确做法是用 DTO 转换。修复时先复现现象并保留证据，再改动一处假设重跑，确认现象消失。

### 自测 3（动手验证）

运行本课的 `java` 示例，把其中的 `0` 换成一个边界值后重新运行，记录输出与错误信息。

**参考答案**：正常输入下 `java` 示例应当复现正文给出的结果；把 `0` 换成边界值后，如果结果改变或报错，先核对它是否满足 `实战：Spring Boot REST API` 中`record` 的适用范围，再检查错误表里是否有同类现象。

### 自测 4（代码阅读）

阅读本课开头的 `java` 示例，说明它体现了`record` 的哪一条性质，并指出改动哪个输入会让这条性质不再成立。

**参考答案**：`record` 的定义是 `record` 天生适合做 API 的请求/响应模型，`@NotBlank`、`@Min` 由 Bean Validation 在入口处自动校验，示例正是在实现这条定义。改动与 `record` 有关的一个输入后，如果结果不再符合 `实战：Spring Boot REST API` 的正文描述，就说明该性质只在当前前提成立。

### 自测 5（迁移）

把 `实战：Spring Boot REST API` 的方法迁移到自己的项目：围绕 `record` 写出一个与错误表同类的风险点，并说明触发条件和检验方式。

**参考答案**：例如「忘记 @Transactional」，它会导致多次写入出现半成功；检验方式是按在 Service 层声明事务改一处再复现，确认现象消失且没有引入新的失败分支。

### 自测 6（对比）

用一个表格对比 `record` 与 `实战`：各写一行适用场景、一行失败表现。

**参考答案**：`record` 的定义是`record` 天生适合做 API 的请求/响应模型；`@NotBlank`、`@Min` 由 Bean Validation 在入口处自动校验；`实战` 的定义是实战：Spring Boot REST API解决了什么问题，而不是只背术语。两者的失败表现分别对应本课错误表里与本术语相关的行。

### 自测 7（排错顺序）

面对「Entity 直接当接口返回」引发的问题，请把“复现 泄露字段、耦合表结构 → 保留证据 → 用 DTO 转换 → 回归验证”四步写成可执行的检查清单。

**参考答案**：第一步按泄露字段、耦合表结构复现；第二步记录输入、版本与完整报错；第三步按用 DTO 转换只改一处；第四步重跑并确认失败路径也按预期变化。

### 自测 8（边界判断）

针对 `测试`，分别写出“可以使用”的条件和“结论不再成立”的条件。

**参考答案**：易错：循环依赖、难测试；正确做法是用构造注入。 同时要把 `测试` 的定义 用可重复的输入和断言验证代码行为是否符合预期 与实际输入逐项对照。

### 自测 9（机制重建）

不看正文，按输入、转换、输出、验证四段重建 `record` → `实战` → `REST` → `测试` 的作用链。

**参考答案**：起点是 `record` 的定义 `record` 天生适合做 API 的请求/响应模型；`@NotBlank`、`@Min` 由 Bean Validation 在入口处自动校验；中间每一步都保留可观察状态；终点由 `测试` 检查，失败时回到错误表定位第一个偏离定义的步骤。

### 自测 10（综合排错）

在 `实战：Spring Boot REST API` 中，现象是 多次写入出现半成功。请围绕 忘记 @Transactional 写出最小复现、关键证据、修复动作和回归验证，并说明为什么不能只凭一次运行下结论。

**参考答案**：先复现 忘记 @Transactional，记录输入与完整错误；再按 在 Service 层声明事务 只改一处。回归时同时跑正常路径和边界路径，只有两次结果都可解释，才把修复视为完成。

### 自测 11（一分钟复述）

用每分钟约 200 字的速度复述 `实战：Spring Boot REST API`：先给主问题，再按顺序说出 `record`、`实战`、`REST`、`测试`，最后给一个失败案例。

**自评标准**：主问题必须对应 分层结构、依赖注入、校验与集成测试；每个术语都要能接上一句定义或边界；失败案例必须写成可观察现象，不能用“可能有风险”代替证据。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `record` | `record` 天生适合做 API 的请求/响应模型；`@NotBlank`、`@Min` 由 Bean Validation 在入口处自动校验。 |
| `实战` | 实战：Spring Boot REST API解决了什么问题，而不是只背术语。 |
| `REST` | 以资源 URI、HTTP 方法和状态码组织接口的无状态风格。 |
| `测试` | 用可重复的输入和断言验证代码行为是否符合预期。 |

**术语关系**：`record`（`record` 天生适合做 API 的请求/响应模型） → `实战`（实战：Spring Boot REST API解决了什么问题） → `REST`（以资源 URI、HTTP 方法和状态码组织接口的无状态风格） → `测试`（用可重复的输入和断言验证代码行为是否符合预期）。

## 考点精讲

`实战：Spring Boot REST API` 的题库有 6 道题，下面逐题给出题干、正确项与判断依据：先自己作答，再核对正确项，最后回到正文对应小节复核。

### 考点 1：第 1 题

- **题目**：围绕“实战：Spring Boot REST API”中的 实战、Spring Boot、REST，下列哪两项是本课强调的实践判断？
- **正确项**：验证 Spring Boot 时要固定版本并覆盖边界输入，结论才可复现；学习 实战 时要同时说明输入、输出和失败路径，不能只看正常流程
- **判断依据**：这道题落在术语 `实战` 上：实战：Spring Boot REST API解决了什么问题，而不是只背术语。复习时把 `实战` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 2：第 2 题

- **题目**：使用构造器注入的主要好处是？
- **正确项**：依赖显式且便于测试
- **判断依据**：这道题落在术语 `测试` 上：用可重复的输入和断言验证代码行为是否符合预期。复习时把 `测试` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 3：第 3 题

- **题目**：这段 `java` 代码对应 `实战：Spring Boot REST API` 的 `record`。课程要解决的是分层结构、依赖注入、校验与集成测试。关于代码内容，哪一项说法准确？
- **正确项**：调用了 `Min()`
- **判断依据**：这道题落在术语 `record` 上：`record` 天生适合做 API 的请求/响应模型，`@NotBlank`、`@Min` 由 Bean Validation 在入口处自动校验。复习时把 `record` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 4：第 4 题

- **题目**：@RestController 与 @Controller 的差别是？
- **正确项**：@RestController 默认返回 JSON
- **判断依据**：这道题检验本课主问题：分层结构、依赖注入、校验与集成测试。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 5：第 5 题

- **题目**：JPA 中 N+1 查询问题的常见解法是？
- **正确项**：用 join fetch / @EntityGraph 一次性预加载关联数据
- **判断依据**：这道题检验本课主问题：分层结构、依赖注入、校验与集成测试。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 6：第 6 题

- **题目**：填空：补齐下面这段术语说明中的空缺。课程 `分层结构、依赖注入、校验与集成测试。`，这段说明是：`____`：以资源 URI、HTTP 方法和状态码组织接口的无状态风格。空缺处应填哪个术语？
- **正确项**：REST
- **判断依据**：这道题落在术语 `REST` 上：以资源 URI、HTTP 方法和状态码组织接口的无状态风格。复习时把 `REST` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 7：`record`

- **要点**：`record` 天生适合做 API 的请求/响应模型；`@NotBlank`、`@Min` 由 Bean Validation 在入口处自动校验。
- **record 的边界**：不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。

### 考点 8：`实战`

- **要点**：实战：Spring Boot REST API解决了什么问题，而不是只背术语。
- **实战 的边界**：不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。

### 考点 9：`REST`

- **要点**：以资源 URI、HTTP 方法和状态码组织接口的无状态风格。
- **REST 的边界**：网络延迟、超时与版本协商会改变行为，只在真实链路或多版本客户端上验证才算数。

### 考点 10：`测试`

- **要点**：用可重复的输入和断言验证代码行为是否符合预期。
- **测试 的边界**：易错：循环依赖、难测试；正确做法是用构造注入。

### 考点 11：排错——Entity 直接当接口返回

- **现象**：泄露字段、耦合表结构。
- **处理**：用 DTO 转换。

### 考点 12：排错——用字段注入

- **现象**：循环依赖、难测试。
- **处理**：用构造注入。

### 考点 13：综合辨析——`record` 与 `测试`

- **辨析点**：`record` 的定义是 `record` 天生适合做 API 的请求/响应模型；`@NotBlank`、`@Min` 由 Bean Validation 在入口处自动校验；`测试` 的定义是 用可重复的输入和断言验证代码行为是否符合预期。
- **答题要求**：面对 `实战：Spring Boot REST API` 的题目，先判断描述的是 `record` 还是 `测试`，再归到对应定义，最后写出一个会让该定义失效的边界输入。

### 考点 14：排错评分点

- **现象分**：能写出 泄露字段、耦合表结构，而不是只写“程序有错”。
- **证据分**：保留触发 Entity 直接当接口返回 的输入、版本和错误原文。
- **修复分**：按 用 DTO 转换 只改一处，并同时回归正常路径与边界路径。

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：高级
- 适用环境：Java 21+ / Maven 或 Gradle
；本课聚焦 实战。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：实战、Spring Boot、REST、依赖注入、测试
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-02-24
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；本课核对关键词：实战、Spring Boot、REST、依赖注入、测试。

| 参考资料 | 本课用途 |
| --- | --- |
| [Gradle 文档](https://docs.gradle.org/current/userguide/userguide.html) | 构建脚本与依赖管理 |
| [JUnit 用户指南](https://junit.org/junit5/docs/current/user-guide/) | 自动化测试与断言 |
| [dev.java 学习](https://dev.java/learn/) | 现代 Java 官方教程 |

| [本课术语索引：实战：Spring Boot REST API](#核心概念定义) | 按本课输入、术语边界和错误表现逐项核对 |
> 「实战：Spring Boot REST API」的链接用于离线阅读后的延伸核对；App 不会自动联网。

<!-- p1-project-review:start -->