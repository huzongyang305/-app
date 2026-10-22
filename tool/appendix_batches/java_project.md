## Spring Boot 注解速查

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

## 分层职责速查

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

## 常见错误对照表

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

## 自测清单

- [ ] 分层职责清晰，Controller 不写业务逻辑。
- [ ] 使用构造器注入，依赖不可变。
- [ ] 事务声明在 Service 层，且不包含网络调用。
- [ ] 用 DTO 隔离实体，避免暴露敏感字段。
- [ ] 数据库结构变更由迁移脚本管理。
