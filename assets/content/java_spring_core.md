# Spring Framework 核心

> 内容更新时间：2026-10-20 · 学习阶段：进阶 · 预计用时：60 分钟

> 学习阶段：进阶 · 预计用时：60 分钟 · 配图：Spring IoC 容器

![Spring IoC 容器](images/spring_ioc_container.webp)

## 本节知识框架

想象你开了一家餐厅。传统方式下，厨师（你的代码）需要自己去菜市场买菜（创建依赖对象）、自己准备调料（管理对象生命周期）。这很麻烦，而且一旦菜市场换了，厨师就得重新找路。

Spring 的 IoC（控制反转）就像是给餐厅配了一个采购经理。厨师只需要说"我需要白菜"，采购经理就会把白菜送过来。厨师不需要关心白菜从哪来、怎么买。这就是"控制反转"——把创建对象的控制权从代码转移到了容器。

**本课知识地图**

```text
IoC 是什么 → 依赖注入 → Bean 生命周期 → AOP 原理 → 实战应用
```

**学完本课你将能够**：

1. 解释 IoC（控制反转）和 DI（依赖注入）的含义。
2. 使用注解（`@Component`、`@Autowired`）配置 Spring Bean。
3. 理解 Bean 的作用域和生命周期。
4. 使用 AOP（面向切面编程）实现日志、事务等横切关注点。

**先修知识**：你需要了解 Java 基础语法和面向对象（来自《Java 基础》），以及 Servlet 的基本概念（来自《Servlet 与 JSP 基础》）。

---

## 核心概念定义

| 术语 | 一句话定义 | 生活类比 |
| --- | --- | --- |
| IoC（控制反转） | 把对象的创建和管理权从代码转移到容器。 | 从"自己买菜"变成"采购经理送菜"。 |
| DI（依赖注入） | IoC 的具体实现方式，容器自动把依赖对象注入到需要它们的组件中。 | 厨师说"我需要白菜"，采购经理就把白菜放到厨师手里。 |
| Bean | Spring 容器中管理的对象，通过配置创建和初始化。 | 餐厅里的食材、厨具、服务员——所有被管理的资源。 |
| BeanFactory | Spring 最基础的容器，负责创建和管理 Bean。 | 餐厅的仓库，存储和管理所有食材。 |
| ApplicationContext | BeanFactory 的高级版本，提供国际化、事件传播等额外功能。 | 餐厅的中央厨房，除了仓库功能还有更多管理能力。 |
| AOP（面向切面编程） | 把日志、事务等横切关注点从业务代码中分离出来，统一处理。 | 餐厅的监控系统——不需要每个厨师自己记录操作，统一由监控摄像头完成。 |
| 切面（Aspect） | 横切关注点的模块化，比如日志切面、事务切面。 | 监控摄像头系统——专门负责记录所有操作。 |
| 通知（Advice） | 切面在特定连接点执行的动作，比如"方法执行前记录日志"。 | 摄像头在厨师开始做菜时自动录像。 |
| 连接点（Joinpoint） | 程序执行过程中的某个点，比如方法调用、异常抛出。 | 厨师开始做菜、做完菜、遇到问题的时刻。 |
| 切点（Pointcut） | 定义哪些连接点需要被拦截的表达式。 | 规定"只监控热菜制作，不监控凉菜"。 |

---

## 原理与运行机制

### IoC 容器是怎么工作的？

**传统方式**：

```java
public class Chef {
    private Vegetable vegetable = new Cabbage(); // 厨师自己创建蔬菜
    
    public void cook() {
        System.out.println("做菜：" + vegetable.getName());
    }
}
```

问题：如果蔬菜供应商换了，需要修改 Chef 类的代码。

**Spring IoC 方式**：

```java
@Component
public class Chef {
    @Autowired
    private Vegetable vegetable; // 容器自动注入
    
    public void cook() {
        System.out.println("做菜：" + vegetable.getName());
    }
}

@Component
public class Cabbage implements Vegetable {
    public String getName() { return "白菜"; }
}
```

Spring 容器启动时：
1. 扫描所有带 `@Component` 注解的类
2. 创建它们的实例（Bean）
3. 把 `@Autowired` 标记的依赖自动注入

### 依赖注入的三种方式

**1. 构造器注入（推荐）**

```java
@Component
public class Chef {
    private final Vegetable vegetable;
    
    @Autowired
    public Chef(Vegetable vegetable) {
        this.vegetable = vegetable;
    }
}
```

优点：依赖不可变，对象创建后状态完整。

**2. Setter 注入**

```java
@Component
public class Chef {
    private Vegetable vegetable;
    
    @Autowired
    public void setVegetable(Vegetable vegetable) {
        this.vegetable = vegetable;
    }
}
```

优点：依赖可选，可以后续修改。

**3. 字段注入（不推荐）**

```java
@Component
public class Chef {
    @Autowired
    private Vegetable vegetable;
}
```

缺点：无法标记为 final，难以测试。

### Bean 生命周期

Spring Bean 的完整生命周期：

1. **实例化**：容器创建 Bean 实例
2. **属性赋值**：注入依赖
3. **初始化**：调用 `@PostConstruct` 方法
4. **使用**：Bean 可以被使用
5. **销毁**：容器关闭时调用 `@PreDestroy` 方法

```java
@Component
public class MyBean {
    
    public MyBean() {
        System.out.println("1. 实例化");
    }
    
    @Autowired
    public void setDependency(Dependency dep) {
        System.out.println("2. 属性赋值");
    }
    
    @PostConstruct
    public void init() {
        System.out.println("3. 初始化");
    }
    
    @PreDestroy
    public void destroy() {
        System.out.println("5. 销毁");
    }
}
```

### Bean 作用域

| 作用域 | 说明 | 使用场景 |
| --- | --- | --- |
| singleton | 容器中只有一个实例（默认） | 无状态服务，如 Service、DAO |
| prototype | 每次获取都创建新实例 | 有状态对象，如购物车 |
| request | 每个 HTTP 请求一个实例 | Web 应用，存储请求数据 |
| session | 每个 HTTP 会话一个实例 | Web 应用，存储用户登录信息 |

```java
@Component
@Scope("prototype")
public class ShoppingCart {
    private List<Item> items = new ArrayList<>();
    // 每个用户都有独立的购物车
}
```

### AOP 是怎么工作的？

AOP 的核心思想：把横切关注点（日志、事务、权限）从业务代码中分离出来。

**没有 AOP**：

```java
public class OrderService {
    private Logger logger = LoggerFactory.getLogger(OrderService.class);
    
    public void createOrder(Order order) {
        logger.info("开始创建订单"); // 业务代码中混入日志代码
        try {
            // 业务逻辑
            orderDao.save(order);
            logger.info("订单创建成功");
        } catch (Exception e) {
            logger.error("订单创建失败", e);
            throw e;
        }
    }
}
```

问题：每个方法都要写日志代码，重复且分散。

**使用 AOP**：

```java
// 业务代码只关心业务
@Service
public class OrderService {
    public void createOrder(Order order) {
        orderDao.save(order);
    }
}

// 日志逻辑独立出来
@Aspect
@Component
public class LogAspect {
    
    @Around("execution(* com.example.service.*.*(..))")
    public Object log(ProceedingJoinPoint joinPoint) throws Throwable {
        String methodName = joinPoint.getSignature().getName();
        Logger logger = LoggerFactory.getLogger(joinPoint.getTarget().getClass());
        
        logger.info("开始执行：" + methodName);
        try {
            Object result = joinPoint.proceed(); // 执行原方法
            logger.info("执行成功：" + methodName);
            return result;
        } catch (Exception e) {
            logger.error("执行失败：" + methodName, e);
            throw e;
        }
    }
}
```

AOP 的原理：Spring 在运行时动态生成代理类，拦截方法调用，在前后执行切面逻辑。

---

## 典型应用场景

- **Web 应用**：Spring MVC 是 Spring 的 Web 框架，底层就是 IoC 和 AOP。
- **微服务**：Spring Boot 基于 Spring，快速构建微服务。
- **事务管理**：使用 `@Transactional` 注解，AOP 自动处理事务。
- **权限控制**：使用 AOP 在方法执行前检查用户权限。
- **缓存**：使用 `@Cacheable` 注解，AOP 自动处理缓存逻辑。
- **异步处理**：使用 `@Async` 注解，AOP 自动把方法放到异步线程执行。

---

## 代码示例

### 最小 Spring 应用

**pom.xml**

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-context</artifactId>
        <version>5.3.20</version>
    </dependency>
</dependencies>
```

**AppConfig.java**

```java
@Configuration
@ComponentScan("com.example")
public class AppConfig {
    // 配置类，告诉 Spring 扫描哪个包
}
```

**Main.java**

```java
public class Main {
    public static void main(String[] args) {
        // 创建 Spring 容器
        ApplicationContext context = new AnnotationConfigApplicationContext(AppConfig.class);
        
        // 从容器获取 Bean
        Chef chef = context.getBean(Chef.class);
        chef.cook();
    }
}
```

### 完整的 IoC 示例

**Vegetable.java**

```java
public interface Vegetable {
    String getName();
}
```

**Cabbage.java**

```java
@Component
public class Cabbage implements Vegetable {
    public String getName() { return "白菜"; }
}
```

**Chef.java**

```java
@Component
public class Chef {
    private final Vegetable vegetable;
    
    @Autowired
    public Chef(Vegetable vegetable) {
        this.vegetable = vegetable;
    }
    
    public void cook() {
        System.out.println("做菜：" + vegetable.getName());
    }
}
```

### AOP 日志示例

**LogAspect.java**

```java
@Aspect
@Component
public class LogAspect {
    
    private static final Logger logger = LoggerFactory.getLogger(LogAspect.class);
    
    // 定义切点：匹配 service 包下所有类的所有方法
    @Pointcut("execution(* com.example.service.*.*(..))")
    public void serviceLayer() {}
    
    // 前置通知
    @Before("serviceLayer()")
    public void logBefore(JoinPoint joinPoint) {
        logger.info("开始执行：{}", joinPoint.getSignature().getName());
    }
    
    // 后置通知
    @AfterReturning(pointcut = "serviceLayer()", returning = "result")
    public void logAfter(JoinPoint joinPoint, Object result) {
        logger.info("执行成功：{}，返回值：{}", joinPoint.getSignature().getName(), result);
    }
    
    // 异常通知
    @AfterThrowing(pointcut = "serviceLayer()", throwing = "ex")
    public void logException(JoinPoint joinPoint, Exception ex) {
        logger.error("执行失败：{}，异常：{}", joinPoint.getSignature().getName(), ex.getMessage());
    }
}
```

---

## 复杂度或性能分析

- **内存占用**：Spring 容器本身占用不大，但会缓存所有 Bean 的元数据。
- **启动时间**：大型项目可能需要几秒到几十秒启动，因为要扫描、创建所有 Bean。
- **运行时性能**：AOP 使用动态代理，会有轻微性能损耗（通常可以忽略）。
- **学习曲线**：Spring 概念较多，需要时间理解 IoC、AOP、Bean 生命周期等。

---

## 常见误区与易错点

| 错误 | 现象 | 修法 |
| --- | --- | --- |
| 循环依赖 | 启动报错：BeanCurrentlyInCreationException | 重构代码，使用 `@Lazy` 或改为构造器注入 |
| 在 singleton Bean 中注入 prototype Bean | prototype Bean 只被创建一次 | 使用 `@Lookup` 或 `ObjectFactory` |
| AOP 切面不生效 | 方法没有被拦截 | 检查切点表达式，确保类被 Spring 管理 |
| 忘记添加 `@Component` | Bean 没有被创建 | 给类添加 `@Component` 或 `@Service` 等注解 |
| 在静态方法中使用 `@Autowired` | 注入失败，为 null | 改为实例方法，或使用静态配置类 |

---

## 与其他知识点的关系

- **先修**：《Java 基础》、《Servlet 与 JSP 基础》
- **后续**：《Spring MVC 与 Web 开发》、《Spring Boot 入门》
- **相关**：《AOP 原理》、《设计模式》

---

## 自测题与参考答案

**Q1**：IoC 的全称是什么？它的核心思想是什么？

<details>
<summary>点击查看答案</summary>

IoC 全称 Inversion of Control（控制反转）。核心思想是把对象的创建和管理权从代码转移到容器，由容器负责注入依赖。
</details>

**Q2**：Spring 中推荐的依赖注入方式是什么？

<details>
<summary>点击查看答案</summary>

构造器注入。因为依赖不可变，对象创建后状态完整，易于测试。
</details>

**Q3**：AOP 的切面（Aspect）和通知（Advice）有什么区别？

<details>
<summary>点击查看答案</summary>

切面是横切关注点的模块化（如日志切面），通知是切面在特定连接点执行的动作（如"方法执行前记录日志"）。一个切面可以包含多个通知。
</details>

---

## 考点精讲

### 考点 1：第 1 题

- **题目**：Spring IoC 容器中，Bean 的默认作用域是什么？
- **正确项**：singleton
- **判断依据**：这道题落在术语「Bean 作用域」上：Spring 容器中 Bean 的生命周期和实例数量。复习时把「singleton」的定义、使用场景和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 2：第 2 题

- **题目**：AOP 中，定义哪些连接点需要被拦截的表达式称为？
- **正确项**：切点（Pointcut）
- **判断依据**：这道题落在术语「AOP」上：面向切面编程的核心概念。复习时把「切点」的定义、语法和一个反例一起说清楚，再回到「核心概念定义」核对原文。

---

## 术语速查

| 术语 | 含义 |
| --- | --- |
| IoC | 控制反转，把对象创建和管理权交给容器 |
| DI | 依赖注入，IoC 的具体实现方式 |
| Bean | Spring 容器中管理的对象 |
| ApplicationContext | Spring 的高级容器 |
| AOP | 面向切面编程，分离横切关注点 |
| Aspect | 切面，横切关注点的模块化 |
| Advice | 通知，切面在连接点执行的动作 |
| Pointcut | 切点，定义拦截哪些连接点 |

---

## 参考资料与复核

- [Spring Framework 官方文档](https://docs.spring.io/spring-framework/docs/current/reference/html/)
- [Spring IoC 容器](https://docs.spring.io/spring-framework/docs/current/reference/html/core.html#beans)
- 复核日期：2026-10-20

---

## 内容元数据

- 课程 ID：java_spring_core
- 分类：Java Web 开发
- 难度：进阶
- 预计用时：60 分钟
- 先修课程：Java 基础、Servlet 与 JSP 基础
- 后续课程：Spring MVC 与 Web 开发、Spring Boot 入门
