# 构建、测试与生态

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：65 分钟

![Java 构建、测试、日志与数据库工具](images/diagram_java_tooling.webp)

![构建、测试与生态](images/remaining_java_tooling.webp)

## 本节知识框架

**课程定位**：所属分类 `java`（Java），课程主题 `构建、测试与生态`，学习阶段 进阶，建议用时 60 分钟。

本课主线：Maven/Gradle、JUnit/Mockito、日志门面、JDBC 与常见框架选型。

**学完本课应当能够**
- 说清 `System.out.println` 与 `JUnit` 的含义与区别，并各举一个正例和一个反例。
- 用本课示例验证 `JDBC` 的行为，记录输入、输出与失败条件。
- 遇到「用 `system` 路径引本地 jar」这类问题时，能说出触发条件与修复顺序。

### 从概念到验证的学习链条

1. `System.out.println`：先掌握 用 SLF4J 门面 + Logback/Log4j2 实现，避免直接使用 `System.out.println`；日志要带上下文，且不要输出密码、令牌等敏感信息，再用它解释 `JUnit` 为什么会出现。
2. `JUnit`：先掌握 Java 常用的单元测试框架，用注解声明测试、断言和生命周期，再用它解释 `JDBC` 为什么会出现。
3. `JDBC`：先掌握 JDBC 是基础，实际项目常用连接池（HikariCP）+ JPA/MyBatis，再用它解释 `依赖坐标` 为什么会出现。
4. `依赖坐标`：先掌握 groupId 加 artifactId 加版本号唯一确定一个构件，冲突时按最近优先规则解析，再用它解释 本课示例的观察结果 为什么会出现。

**先修与衔接**：本课是「Java」分类的第 14 课。相关或后续课程：《实战：Spring Boot REST API》。

### 完成判据

- **定义关**：不看正文也能说明 `System.out.println` 是 用 SLF4J 门面 + Logback/Log4j2 实现，避免直接使用 `System.out.println`，日志要带上下文，且不要输出密码、令牌等敏感信息，并指出一个反例。
- **机制关**：能按“输入 → 转换 → 输出 → 验证”复述 `构建、测试与生态`，而不是只背结论。
- **示例关**：能运行或推演 `构建、测试与生态` 的 `xml` 示例，并说明一个真实出现的标识符或字面量。
- **证据关**：能指出 `构建、测试与生态` 示例里的 调用了 `mavenCentral()`，并说明它支持或反驳了本课的哪一条结论。
- **排错关**：能复现 用 `system` 路径引本地 jar，记录现象并按 装进私服或本地仓库 修复。
- **迁移关**：能把 `Maven`、`Gradle`、`JUnit`、`Mockito` 放进一个与 `构建、测试与生态` 不同的项目场景，并保持输入与验证条件可追踪。
- **复盘关**：学完 `构建、测试与生态` 后，用一句话写下仍然不确定的结论，并列出下一次验证需要的输入、环境和成功判据。

### 复习清单

- [ ] 能不看正文复述本课核心术语，并指出一个边界或反例。
- [ ] 能运行或推演本课示例，记录输入、输出与失败现象。
- [ ] 能完成一次自测，并把错题对照错误表定位原因。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| System.out.println | 用 SLF4J 门面 + Logback/Log4j2 实现，避免直接使用 System.out.println；日志要带上下文，且不要输出密码、令牌等敏感信息。 | 易错：生产日志无法统一收集；正确做法是用日志框架并分级。 |
| JUnit | Java 常用的单元测试框架，用注解声明测试、断言和生命周期。 | 越界、悬垂引用与释放顺序会破坏结论，必须在边界输入下复验。 |
| JDBC | JDBC 是基础，实际项目常用连接池（HikariCP）+ JPA/MyBatis。 | 只在「JDBC 是基础，实际项目常用连接池（HikariCP）+ JPA/MyBatis」这一前提下成立，换输入或换环境要重新验证。 |
| 依赖坐标 | groupId 加 artifactId 加版本号唯一确定一个构件，冲突时按最近优先规则解析。 | 不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。 |

## 原理与运行机制

### 机制总览

**教材衔接：生态速览**

| 领域 | 常用选择 |
| --- | --- |
| Web 框架 | Spring Boot、Quarkus、Javalin |
| 持久化 | JDBC、JPA/Hibernate、MyBatis |
| 测试 | JUnit 5、Mockito、Testcontainers |
| 构建 | Maven、Gradle |
| 日志 | SLF4J + Logback |

**教材衔接：构建工具速查**

| 目的 | Maven | Gradle |
| --- | --- | --- |
| 配置格式 | `pom.xml` | `build.gradle(.kts)` |
| 编译 | `mvn compile` | `gradle compileJava` |
| 测试 | `mvn test` | `gradle test` |
| 打包 | `mvn package` | `gradle build` |
| 跳过测试打包 | `mvn package -DskipTests` | `gradle build -x test` |
| 清理 | `mvn clean` | `gradle clean` |
| 依赖树 | `mvn dependency:tree` | `gradle dependencies` |
| 常用插件 | Surefire、Shade | Shadow、Spotless |

依赖管理速查：

| 概念 | 说明 |
| --- | --- |
| `groupId:artifactId:version` | Maven 坐标，定位一个依赖 |
| `implementation` | Gradle 中不对使用者暴露的依赖 |
| `api` | Gradle 中会传递给使用者的依赖 |
| `testImplementation` | 只用于测试 |
| BOM / `platform` | 统一管理一组依赖版本 |
| `dependencyManagement` | Maven 中锁定版本 |
| 传递依赖冲突 | 用 `enforcedPlatform` 或 `exclude` 处理 |

**教材衔接：日志速查**

| 目的 | 写法 |
| --- | --- |
| 声明日志器 | `private static final Logger log = LoggerFactory.getLogger(X.class);` |
| 占位符 | `log.info("下单成功 userId={}, amount={}", userId, amount);` |
| 记录异常 | `log.error("处理失败 orderId={}", id, e);` |
| 条件日志 | `if (log.isDebugEnabled()) { ... }` |
| 级别 | `ERROR` > `WARN` > `INFO` > `DEBUG` > `TRACE` |
| 禁止 | `System.out.println`、字符串拼接日志、打印敏感数据 |

**教材衔接：版本与时效**

- 版本基线会影响 Maven 的可用 API，升级前先用编译与测试验证。
- 升级收益集中在并发与内存模型；Gradle 相关代码需要单独回归。
- 升级「构建、测试与生态」涉及的依赖前，先用 JavaLanguageVersion 复现当前行为，再逐项核对版本说明与破坏性变更。

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 升级时只动一个依赖版本，用 JavaLanguageVersion 记录构建与运行结果。
- 回归范围锁定 JavaLanguageVersion 的默认行为，并确认弃用警告是否出现在构建输出里。
- 升级完成后更新本课「最后复核 / 下次复核」日期，并记录 Maven 的版本变化。

### 机制拆解：每一步的输入、动作与输出

#### 1. `System.out.println`
- 输入：`Maven`；本步把 用 SLF4J 门面 + Logback/Log4j2 实现，避免直接使用 `System.out.println`；日志要带上下文，且不要输出密码、令牌等敏感信息 当作判断规则。
- 动作：围绕 `System.out.println` 保留中间状态，并记录它与 `JUnit` 的对应关系。
- 输出：`JUnit`，它可以被下一段代码、测试或记录继续使用。
- `System.out.println` 的失败条件：当用 `System.out.println` 调试时，会出现生产日志无法统一收集。

#### 2. `JUnit`
- 输入：`System.out.println`；本步把 Java 常用的单元测试框架，用注解声明测试、断言和生命周期 当作判断规则。
- 动作：围绕 `JUnit` 保留中间状态，并记录它与 `JDBC` 的对应关系。
- 输出：`JDBC`，它可以被下一段代码、测试或记录继续使用。
- `JUnit` 的失败条件：越界、悬垂引用与释放顺序会破坏结论，必须在边界输入下复验。

#### 3. `JDBC`
- 输入：`JUnit`；本步把 JDBC 是基础，实际项目常用连接池（HikariCP）+ JPA/MyBatis 当作判断规则。
- 动作：围绕 `JDBC` 保留中间状态，并记录它与 `依赖坐标` 的对应关系。
- 输出：`依赖坐标`，它可以被下一段代码、测试或记录继续使用。
- `JDBC` 的失败条件：只在「JDBC 是基础，实际项目常用连接池（HikariCP）+ JPA/MyBatis」这一前提下成立，换输入或换环境要重新验证。

#### 4. `依赖坐标`
- 输入：`JDBC`；本步把 groupId 加 artifactId 加版本号唯一确定一个构件，冲突时按最近优先规则解析 当作判断规则。
- 动作：围绕 `依赖坐标` 保留中间状态，并记录它与 `mavenCentral` 的对应关系。
- 输出：`mavenCentral`，它可以被下一段代码、测试或记录继续使用。
- `依赖坐标` 的失败条件：不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。

### 示例中的可观察事实

1. 调用了 `mavenCentral()`；它对应的课程主题是 `构建、测试与生态`。
2. 出现字面量 `java`；它对应的课程主题是 `构建、测试与生态`。

### 复现实验记录

- 环境：`构建、测试与生态` 使用 `xml` 示例，固定 `Maven`、`Gradle`、`JUnit`、`Mockito` 作为第一组条件。
- 首轮输入：先确认 调用了 `mavenCentral()`，预测 `System.out.println` 会怎样变化。
- 基线观察：记录命令、输入、输出和错误原文，不用截图代替可复制的文本。
- 单变量修改：只改变 `Maven`，观察 `依赖坐标` 是否仍满足定义。
- 失败注入：复现 用 `system` 路径引本地 jar，确认现象是 换机器就失败。
- 记录结论：把“修改前、修改后、预期变化、实际变化”写成四列表，这样复盘 `构建、测试与生态` 时才能区分概念错误与实现错误。

## 典型应用场景

- **用 `system` 路径引本地 jar**：典型现象是换机器就失败；正确做法是装进私服或本地仓库。
- **依赖版本互相冲突**：典型现象是`NoSuchMethodError`；正确做法是用 `dependency:tree` 排查。
- **忘提交 wrapper**：典型现象是构建环境不一致；正确做法是提交 `mvnw` / `gradlew`。
- **测试依赖生产配置**：典型现象是测试不稳定；正确做法是用测试专用配置。

### 最小验证场景

- 准备：保留 `xml` 示例的原始输入，先记录 `构建、测试与生态` 的基线输出和完整运行命令。
- 观察：先核对 调用了 `mavenCentral()`，再改变一个与 `System.out.println` 相关的条件。
- 判定：新结果与 `构建、测试与生态` 的基线不同不等于错误；只有当差异破坏了 `System.out.println` 的定义或错误表中的约束，才判定为失败。

### 选择与边界

- 使用 `System.out.println` 时，先满足它的定义：用 SLF4J 门面 + Logback/Log4j2 实现，避免直接使用 `System.out.println`；日志要带上下文，且不要输出密码、令牌等敏感信息；易错：生产日志无法统一收集；正确做法是用日志框架并分级。
- 使用 `JUnit` 时，先满足它的定义：Java 常用的单元测试框架，用注解声明测试、断言和生命周期；越界、悬垂引用与释放顺序会破坏结论，必须在边界输入下复验。
- 使用 `JDBC` 时，先满足它的定义：JDBC 是基础，实际项目常用连接池（HikariCP）+ JPA/MyBatis；只在「JDBC 是基础，实际项目常用连接池（HikariCP）+ JPA/MyBatis」这一前提下成立，换输入或换环境要重新验证。
- 使用 `依赖坐标` 时，先满足它的定义：groupId 加 artifactId 加版本号唯一确定一个构件，冲突时按最近优先规则解析；不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。

## 代码/协议/SQL 示例

### 最小可验证示例

```xml
<!-- pom.xml（Maven）-->
<project>
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example</groupId>
  <artifactId>demo</artifactId>
  <version>1.0.0</version>
  <properties>
    <maven.compiler.release>21</maven.compiler.release>
  </properties>
  <dependencies>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter</artifactId>
      <version>5.10.0</version>
      <scope>test</scope>
    </dependency>
  </dependencies>
</project>
```

**教材衔接：Maven 与 Gradle**

```groovy
// build.gradle（Gradle）
plugins { id 'java' }
java { toolchain { languageVersion = JavaLanguageVersion.of(21) } }
repositories { mavenCentral() }
dependencies {
    testImplementation 'org.junit.jupiter:junit-jupiter:5.10.0'
}
```

```bash
mvn clean package          # Maven：编译 + 测试 + 打包
gradle build               # Gradle：默认增量构建更快
```

**教材衔接：单元测试**

```java
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class CalculatorTest {
    @Test
    void addsNumbers() {
        assertEquals(5, Calculator.add(2, 3));
    }

    @Test
    void throwsOnDivideByZero() {
        assertThrows(ArithmeticException.class, () -> Calculator.divide(1, 0));
    }
}
```

Mockito 用于隔离依赖：

```java
UserRepository repo = mock(UserRepository.class);
when(repo.findById(1L)).thenReturn(Optional.of(new User("tom")));
```

**教材衔接：日志**

```java
private static final Logger log = LoggerFactory.getLogger(Service.class);

log.info("创建订单 id={} userId={}", orderId, userId);
log.warn("库存不足 sku={}", sku);
log.error("下单失败 userId={}", userId, exception);   // 异常作为最后一个参数
```

用 SLF4J 门面 + Logback/Log4j2 实现，避免直接使用 `System.out.println`；日志要带上下文，且不要输出密码、令牌等敏感信息。

**教材衔接：数据库访问**

```java
try (Connection conn = DriverManager.getConnection(url, user, password);
     PreparedStatement ps = conn.prepareStatement("SELECT name FROM users WHERE id = ?")) {
    ps.setLong(1, userId);
    try (ResultSet rs = ps.executeQuery()) {
        if (rs.next()) System.out.println(rs.getString("name"));
    }
}
```

JDBC 是基础，实际项目常用连接池（HikariCP）+ JPA/MyBatis。**永远使用 PreparedStatement 防 SQL 注入**。

**教材衔接：JUnit 5 速查**

| 注解 / 方法 | 作用 |
| --- | --- |
| `@Test` | 标记测试方法 |
| `@BeforeEach` / `@AfterEach` | 每个用例前后执行 |
| `@BeforeAll` / `@AfterAll` | 整个测试类前后执行（需静态） |
| `@DisplayName` | 可读的用例名 |
| `@Disabled` | 暂时跳过 |
| `@ParameterizedTest` + `@ValueSource` / `@CsvSource` | 参数化 |
| `@Nested` | 分组用例 |
| `@Tag` | 分类标记（如 `slow`） |
| `assertThrows` | 断言抛异常 |
| `assertAll` | 一次断言多项，全部失败都报告 |
| `assertTimeout` | 断言执行时间 |

```java
import org.junit.jupiter.api.*;
import static org.junit.jupiter.api.Assertions.*;

class PriceCalculatorTest {
    private PriceCalculator calculator;

    @BeforeEach
    void setUp() {
        calculator = new PriceCalculator();
    }

    @Test
    @DisplayName("VIP 用户免运费")
    void vipFreeShipping() {
        assertEquals(0, calculator.shippingFee("vip", 100));
    }

    @ParameterizedTest
    @CsvSource({"normal,100,10", "normal,300,0"})
    void shippingByAmount(String type, int amount, int expected) {
        assertEquals(expected, calculator.shippingFee(type, amount));
    }

    @Test
    void rejectsNegativeAmount() {
        assertThrows(IllegalArgumentException.class,
                () -> calculator.shippingFee("normal", -1));
    }
}
```

**教材衔接：零基础详解：Java 工具链与工程实践**

### 一句话说清它是什么

Java 的工具链负责四件事：**编译、依赖管理、构建打包、测试与质量检查**。
现代项目基本都用 Maven 或 Gradle 中的一个，再配上 JUnit 与静态检查。

### 用生活比喻理解

| 工具 | 比喻 | 说明 |
| --- | --- | --- |
| JDK | 全套工具 | 编译器 + 运行时 + 工具 |
| Maven / Gradle | 施工队 | 拉材料、编译、打包 |
| 仓库 | 建材市场 | 中央仓库 + 私服 |
| JUnit | 验收员 | 自动跑测试 |
| 依赖范围 | 材料用途 | compile / runtime / test |

### Maven 与 Gradle 怎么选

| 对比 | Maven | Gradle |
| --- | --- | --- |
| 配置方式 | XML，约定优先 | Groovy/Kotlin DSL，灵活 |
| 学习曲线 | 平缓 | 前期略陡 |
| 构建速度 | 一般 | 增量与缓存更好 |
| 生态 | 极其成熟 | 现代 Android 与微服务主流 |
| 建议 | 企业传统项目 | 新项目或 Android |

### Maven 的 pom 关键片段

```xml
<properties>
  <maven.compiler.release>21</maven.compiler.release>
  <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
</properties>

<dependencies>
  <dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-databind</artifactId>
    <version>2.18.0</version>
  </dependency>
  <dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter</artifactId>
    <version>5.11.0</version>
    <scope>test</scope>            <!-- 只在测试期需要 -->
  </dependency>
</dependencies>

<build>
  <plugins>
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-surefire-plugin</artifactId>
      <version>3.5.0</version>
    </plugin>
  </plugins>
</build>
```

常用命令：

```bash
mvn -q clean verify            # 清理 + 编译 + 测试 + 打包校验
mvn -q test                    # 只跑测试
mvn -q dependency:tree         # 查看依赖树，排查冲突
mvn -q versions:display-dependency-updates   # 检查可升级依赖
```

### Gradle 的 build.gradle.kts 关键片段

```kotlin
plugins {
    java
    application
}

java {
    toolchain { languageVersion = JavaLanguageVersion.of(21) }
}

repositories { mavenCentral() }

dependencies {
    implementation("com.fasterxml.jackson.core:jackson-databind:2.18.0")
    testImplementation("org.junit.jupiter:junit-jupiter:5.11.0")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

tasks.test {
    useJUnitPlatform()
}

application { mainClass = "com.example.App" }
```

```bash
./gradlew build             # 编译 + 测试 + 打包
./gradlew test --info       # 详细测试输出
./gradlew dependencies      # 依赖树
./gradlew --refresh-dependencies build
```

**记得提交 `gradle/wrapper` 与 `mvnw`**，这样别人不用装指定版本也能构建。

### JUnit 5 的三件套

```java
import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import static org.junit.jupiter.api.Assertions.*;

class PriceTest {
    @Test
    void 保留两位小数() {
        assertEquals("19.90", Price.format(19.9));
    }

    @Test
    void 负数抛异常() {
        var ex = assertThrows(IllegalArgumentException.class, () -> Price.format(-1));
        assertTrue(ex.getMessage().contains("不能为负"));
    }

    @ParameterizedTest
    @ValueSource(strings = {"", " ", "abc"})
    void 非法输入都报错(String input) {
        assertThrows(IllegalArgumentException.class, () -> Price.parse(input));
    }
}
```

| 注解 | 作用 |
| --- | --- |
| `@Test` | 一个测试方法 |
| `@BeforeEach` / `@AfterEach` | 每个用例前后执行 |
| `@ParameterizedTest` | 一组数据跑同一逻辑 |
| `@Disabled` | 临时跳过（需说明原因） |
| `@DisplayName` | 给用例起可读名字 |

### CI 里的标准动作

```yaml
- run: ./mvnw -B -q clean verify        # 或 ./gradlew build
- run: ./mvnw -B org.jacoco:jacoco-maven-plugin:report
```

| 检查 | 工具 |
| --- | --- |
| 单元测试 | JUnit 5 |
| 覆盖率 | JaCoCo |
| 静态分析 | SpotBugs、Error Prone |
| 依赖漏洞 | OWASP Dependency-Check |
| 代码格式 | Spotless、google-java-format |

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 用 `system` 路径引本地 jar | 换机器就失败 | 装进私服或本地仓库 |
| 依赖版本互相冲突 | `NoSuchMethodError` | 用 `dependency:tree` 排查 |
| 忘提交 wrapper | 构建环境不一致 | 提交 `mvnw` / `gradlew` |
| 测试依赖生产配置 | 测试不稳定 | 用测试专用配置 |
| 依赖不写 `test` 范围 | 打包体积变大 | 测试依赖标 `test` |
| 用 `mvn install` 代替 `verify` | 污染本地仓库 | CI 用 `verify` |
| 忽略编码设置 | 中文乱码 | 显式设 UTF-8 |
| 不看依赖更新 | 漏洞长期存在 | 定期升级并跑漏洞扫描 |

### 手把手练习：给项目加质量门禁

```xml
<plugin>
  <groupId>org.jacoco</groupId>
  <artifactId>jacoco-maven-plugin</artifactId>
  <version>0.8.12</version>
  <executions>
    <execution>
      <goals><goal>prepare-agent</goal></goals>
    </execution>
    <execution>
      <id>check</id>
      <phase>verify</phase>
      <goals><goal>check</goal></goals>
      <configuration>
        <rules>
          <rule>
            <element>BUNDLE</element>
            <limits>
              <limit>
                <counter>LINE</counter>
                <value>COVEREDRATIO</value>
                <minimum>0.70</minimum>
              </limit>
            </limits>
          </rule>
        </rules>
      </configuration>
    </execution>
  </executions>
</plugin>
```

这样覆盖率低于 70% 时 `mvn verify` 会直接失败，形成硬门禁。

### 学完自测

- [ ] 能说出 Maven 与 Gradle 的三点差异。
- [ ] 知道 `test` 依赖范围的作用。
- [ ] 能说出 `mvn verify` 与 `mvn install` 的区别。
- [ ] 知道为什么要提交 wrapper 与 mvnw。
- [ ] 能用 JaCoCo 配置一条覆盖率门禁。

### 示例精读：先找证据，再改一个条件

1. 调用了 `mavenCentral()`；它出现在 `构建、测试与生态` 的示例中，阅读时先确认它前后各发生了什么。
2. 出现字面量 `java`；它出现在 `构建、测试与生态` 的示例中，阅读时先确认它前后各发生了什么。
- 在 `构建、测试与生态` 中与 `System.out.println` 对照：示例必须能支持 用 SLF4J 门面 + Logback/Log4j2 实现，避免直接使用 `System.out.println`；日志要带上下文，且不要输出密码、令牌等敏感信息，否则说明这一段还缺少实现或验证步骤。
- 在 `构建、测试与生态` 中与 `JUnit` 对照：示例必须能支持 Java 常用的单元测试框架，用注解声明测试、断言和生命周期，否则说明这一段还缺少实现或验证步骤。
- 在 `构建、测试与生态` 中与 `JDBC` 对照：示例必须能支持 JDBC 是基础，实际项目常用连接池（HikariCP）+ JPA/MyBatis，否则说明这一段还缺少实现或验证步骤。
- 在 `构建、测试与生态` 中与 `依赖坐标` 对照：示例必须能支持 groupId 加 artifactId 加版本号唯一确定一个构件，冲突时按最近优先规则解析，否则说明这一段还缺少实现或验证步骤。

## 时间/空间复杂度或性能分析

**性能关注点（构建、测试与生态）**：JVM 预热与 GC 影响测量：记录吞吐、P99 延迟与堆占用，先跑预热再采样。

**本课特有开销（构建、测试与生态 · Maven）**：并发度提高后要观察是否出现拐点：延迟上升而吞吐不增，说明瓶颈已转移。

**测量方法**：以 `构建、测试与生态` 的 `Maven` 场景为对象，固定输入跑一遍记录基线，再把规模或并发度提高一个数量级复测；两次结果的差值与波动范围才是结论依据。

### 需要控制的变量与记录项

- `构建、测试与生态` 的 `Maven`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `构建、测试与生态` 的 `Gradle`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `构建、测试与生态` 的 `JUnit`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `构建、测试与生态` 的 `Mockito`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `构建、测试与生态` 的 `SLF4J`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `构建、测试与生态` 中 `System.out.println` 的边界：易错：生产日志无法统一收集；正确做法是用日志框架并分级。达到边界时不要外推，必须重新测量。
- `构建、测试与生态` 中 `JUnit` 的边界：越界、悬垂引用与释放顺序会破坏结论，必须在边界输入下复验。达到边界时不要外推，必须重新测量。
- `构建、测试与生态` 中 `JDBC` 的边界：只在「JDBC 是基础，实际项目常用连接池（HikariCP）+ JPA/MyBatis」这一前提下成立，换输入或换环境要重新验证。达到边界时不要外推，必须重新测量。
- `构建、测试与生态` 中 `依赖坐标` 的边界：不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。达到边界时不要外推，必须重新测量。
- `构建、测试与生态` 的代码证据：先验证 调用了 `mavenCentral()`，再记录该路径的输入规模与耗时；只看代码行数不能推出复杂度。

## 常见误区与易错点

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用 `system` 路径引本地 jar | 换机器就失败 | 装进私服或本地仓库 |
| 依赖版本互相冲突 | `NoSuchMethodError` | 用 `dependency:tree` 排查 |
| 忘提交 wrapper | 构建环境不一致 | 提交 `mvnw` / `gradlew` |
| 测试依赖生产配置 | 测试不稳定 | 用测试专用配置 |
| 依赖不写 `test` 范围 | 打包体积变大 | 测试依赖标 `test` |
| 用 `mvn install` 代替 `verify` | 污染本地仓库 | CI 用 `verify` |
| 忽略编码设置 | 中文乱码 | 显式设 UTF-8 |
| 不看依赖更新 | 漏洞长期存在 | 定期升级并跑漏洞扫描 |
| `mvn package -DskipTests` 当成默认 | 带缺陷发布 | 只在明确需要时跳过，CI 必须跑测试 |
| 依赖不加版本、依赖 BOM 缺失 | 版本漂移 | 用 BOM 或显式声明版本 |
| `implementation` 与 `api` 混用 | 使用方编译失败或依赖泄漏 | 内部依赖用 `implementation` |
| 测试依赖放进 `dependencies` | 生产包体积变大 | 用 `testImplementation` / `test` scope |
| 依赖冲突不排查 | 运行时 `NoSuchMethodError` | 用依赖树定位并排除 |
| 日志用字符串拼接 | 无谓的性能开销 | 用占位符 `{}` |
| 用 `System.out.println` 调试 | 生产日志无法统一收集 | 用日志框架并分级 |
| 日志打印密码或令牌 | 安全事件 | 脱敏处理 |
| 测试之间共享静态状态 | 单跑通过、一起跑失败 | 每个用例独立准备数据 |
| 断言太弱（只断言不抛异常） | 回归测不出来 | 断言具体值或异常类型 |
| implementation 与 api 混用 | 使用方编译失败或依赖泄漏。 | 内部依赖用 implementation。 |
| 测试依赖放进 dependencies | 生产包体积变大。 | 用 testImplementation / test scope。 |

### 现场 1：用 `system` 路径引本地 jar

**症状**：换机器就失败。

**根因与修复**：装进私服或本地仓库。

**自检**：在本课示例里复现「用 `system` 路径引本地 jar」，改成装进私服或本地仓库后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 2：依赖版本互相冲突

**症状**：`NoSuchMethodError`。

**根因与修复**：用 `dependency:tree` 排查。

**自检**：在本课示例里复现「依赖版本互相冲突」，改成用 `dependency:tree` 排查后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 3：忘提交 wrapper

**症状**：构建环境不一致。

**根因与修复**：提交 `mvnw` / `gradlew`。

**自检**：在本课示例里复现「忘提交 wrapper」，改成提交 `mvnw` / `gradlew`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 4：测试依赖生产配置

**症状**：测试不稳定。

**根因与修复**：用测试专用配置。

**自检**：在本课示例里复现「测试依赖生产配置」，改成用测试专用配置后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 5：依赖不写 `test` 范围

**症状**：打包体积变大。

**根因与修复**：测试依赖标 `test`。

**自检**：在本课示例里复现「依赖不写 `test` 范围」，改成测试依赖标 `test`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 6：用 `mvn install` 代替 `verify`

**症状**：污染本地仓库。

**根因与修复**：CI 用 `verify`。

**自检**：在本课示例里复现「用 `mvn install` 代替 `verify`」，改成CI 用 `verify`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 7：忽略编码设置

**症状**：中文乱码。

**根因与修复**：显式设 UTF-8。

**自检**：在本课示例里复现「忽略编码设置」，改成显式设 UTF-8后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 8：不看依赖更新

**症状**：漏洞长期存在。

**根因与修复**：定期升级并跑漏洞扫描。

**自检**：在本课示例里复现「不看依赖更新」，改成定期升级并跑漏洞扫描后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 9：`mvn package -DskipTests` 当成默认

**症状**：带缺陷发布。

**根因与修复**：只在明确需要时跳过，CI 必须跑测试。

**自检**：在本课示例里复现「`mvn package -DskipTests` 当成默认」，改成只在明确需要时跳过，CI 必须跑测试后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

## 与其他知识点的关系

- **相关或后续**：`实战：Spring Boot REST API`。本课术语会在这些课程里继续使用。
- **术语归属**：`System.out.println`、`JUnit`、`JDBC` 的定义以本课「核心概念定义」为准，换到其他课程时先确认定义是否被改写。
- 同一分类的《实战：Java 库存管理 REST 服务》也涉及 `JUnit`；两课衔接时先确认这个术语的定义是否一致。

### 先修与后续术语接口

- `实战：Spring Boot REST API`：两者通过本分类的学习顺序衔接，阅读时重点比较各自的输入与失败条件。

### 容易混淆的相邻概念

- `System.out.println` 与 `JUnit`：前者强调 用 SLF4J 门面 + Logback/Log4j2 实现，避免直接使用 `System.out.println`；日志要带上下文，且不要输出密码、令牌等敏感信息；后者强调 Java 常用的单元测试框架，用注解声明测试、断言和生命周期。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `JUnit` 与 `JDBC`：前者强调 Java 常用的单元测试框架，用注解声明测试、断言和生命周期；后者强调 JDBC 是基础，实际项目常用连接池（HikariCP）+ JPA/MyBatis。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `JDBC` 与 `依赖坐标`：前者强调 JDBC 是基础，实际项目常用连接池（HikariCP）+ JPA/MyBatis；后者强调 groupId 加 artifactId 加版本号唯一确定一个构件，冲突时按最近优先规则解析。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。

## 自测题与参考答案

> 先独立作答，再对照参考答案；答案都能在本课正文、术语表或错误表里找到依据。

### 自测 1（概念复述）

不看正文，写出 `System.out.println` 的操作性定义，并说明它与 `JUnit` 的区别。

**参考答案**：用 SLF4J 门面 + Logback/Log4j2 实现，避免直接使用 `System.out.println`；日志要带上下文，且不要输出密码、令牌等敏感信息。

`JUnit` 的定位是：Java 常用的单元测试框架，用注解声明测试、断言和生命周期；两者的差别要从适用对象与失败模式上说明。

### 自测 2（排错）

本课错误表记录了「用 `system` 路径引本地 jar」这类做法。请写出它会出现的现象、根因，以及修复顺序。

**参考答案**：现象是换机器就失败；正确做法是装进私服或本地仓库。修复时先复现现象并保留证据，再改动一处假设重跑，确认现象消失。

### 自测 3（动手验证）

运行本课的 `xml` 示例，把其中的 `4` 换成一个边界值后重新运行，记录输出与错误信息。

**参考答案**：正常输入下 `xml` 示例应当复现正文给出的结果；把 `4` 换成边界值后，如果结果改变或报错，先核对它是否满足 `构建、测试与生态` 中`System.out.println` 的适用范围，再检查错误表里是否有同类现象。

### 自测 4（代码阅读）

阅读本课开头的 `xml` 示例，说明它体现了`System.out.println` 的哪一条性质，并指出改动哪个输入会让这条性质不再成立。

**参考答案**：`System.out.println` 的定义是 用 SLF4J 门面 + Logback/Log4j2 实现，避免直接使用 `System.out.println`，日志要带上下文，且不要输出密码、令牌等敏感信息，示例正是在实现这条定义。改动与 `System.out.println` 有关的一个输入后，如果结果不再符合 `构建、测试与生态` 的正文描述，就说明该性质只在当前前提成立。

### 自测 5（迁移）

把 `构建、测试与生态` 的方法迁移到自己的项目：围绕 `System.out.println` 写出一个与错误表同类的风险点，并说明触发条件和检验方式。

**参考答案**：例如「测试依赖放进 dependencies」，它会导致生产包体积变大；检验方式是按用 testImplementation / test scope改一处再复现，确认现象消失且没有引入新的失败分支。

### 自测 6（对比）

用一个表格对比 `System.out.println` 与 `JUnit`：各写一行适用场景、一行失败表现。

**参考答案**：`System.out.println` 的定义是用 SLF4J 门面 + Logback/Log4j2 实现，避免直接使用 `System.out.println`；日志要带上下文，且不要输出密码、令牌等敏感信息；`JUnit` 的定义是Java 常用的单元测试框架，用注解声明测试、断言和生命周期。两者的失败表现分别对应本课错误表里与本术语相关的行。

### 自测 7（排错顺序）

面对「用 `system` 路径引本地 jar」引发的问题，请把“复现 换机器就失败 → 保留证据 → 装进私服或本地仓库 → 回归验证”四步写成可执行的检查清单。

**参考答案**：第一步按换机器就失败复现；第二步记录输入、版本与完整报错；第三步按装进私服或本地仓库只改一处；第四步重跑并确认失败路径也按预期变化。

### 自测 8（边界判断）

针对 `依赖坐标`，分别写出“可以使用”的条件和“结论不再成立”的条件。

**参考答案**：不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。 同时要把 `依赖坐标` 的定义 groupId 加 artifactId 加版本号唯一确定一个构件，冲突时按最近优先规则解析 与实际输入逐项对照。

### 自测 9（机制重建）

不看正文，按输入、转换、输出、验证四段重建 `System.out.println` → `JUnit` → `JDBC` → `依赖坐标` 的作用链。

**参考答案**：起点是 `System.out.println` 的定义 用 SLF4J 门面 + Logback/Log4j2 实现，避免直接使用 `System.out.println`；日志要带上下文，且不要输出密码、令牌等敏感信息；中间每一步都保留可观察状态；终点由 `依赖坐标` 检查，失败时回到错误表定位第一个偏离定义的步骤。

### 自测 10（综合排错）

在 `构建、测试与生态` 中，现象是 生产包体积变大。请围绕 测试依赖放进 dependencies 写出最小复现、关键证据、修复动作和回归验证，并说明为什么不能只凭一次运行下结论。

**参考答案**：先复现 测试依赖放进 dependencies，记录输入与完整错误；再按 用 testImplementation / test scope 只改一处。回归时同时跑正常路径和边界路径，只有两次结果都可解释，才把修复视为完成。

### 自测 11（一分钟复述）

用每分钟约 200 字的速度复述 `构建、测试与生态`：先给主问题，再按顺序说出 `System.out.println`、`JUnit`、`JDBC`、`依赖坐标`，最后给一个失败案例。

**自评标准**：主问题必须对应 Maven/Gradle、JUnit/Mockito、日志门面、JDBC 与常见框架选型；每个术语都要能接上一句定义或边界；失败案例必须写成可观察现象，不能用“可能有风险”代替证据。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `System.out.println` | 用 SLF4J 门面 + Logback/Log4j2 实现，避免直接使用 `System.out.println`；日志要带上下文，且不要输出密码、令牌等敏感信息。 |
| `JUnit` | Java 常用的单元测试框架，用注解声明测试、断言和生命周期。 |
| `JDBC` | JDBC 是基础，实际项目常用连接池（HikariCP）+ JPA/MyBatis。 |
| `依赖坐标` | groupId 加 artifactId 加版本号唯一确定一个构件，冲突时按最近优先规则解析。 |

**术语关系**：`System.out.println`（用 SLF4J 门面 + Logback/Log4j2 实现） → `JUnit`（Java 常用的单元测试框架） → `JDBC`（JDBC 是基础） → `依赖坐标`（groupId 加 artifactId 加版本号唯一确定一个构件）。

## 考点精讲

`构建、测试与生态` 的题库有 6 道题，下面逐题给出题干、正确项与判断依据：先自己作答，再核对正确项，最后回到正文对应小节复核。

### 考点 1：第 1 题

- **题目**：围绕“构建、测试与生态”中的 Maven、Gradle、JUnit，下列哪两项是本课强调的实践判断？
- **正确项**：学习 Maven 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 Gradle 时要固定版本并覆盖边界输入，结论才可复现
- **判断依据**：这道题落在术语 `JUnit` 上：Java 常用的单元测试框架，用注解声明测试、断言和生命周期。复习时把 `JUnit` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 2：第 2 题

- **题目**：`构建、测试与生态` 的示例代码用于验证 `System.out.println`，其背景是Maven/Gradle、JUnit/Mockito、日志门面、JDBC 与常见框架选型。代码的真实内容是下面哪一项？
- **正确项**：出现字面量 `java`
- **判断依据**：这道题落在术语 `System.out.println` 上：用 SLF4J 门面 + Logback/Log4j2 实现，避免直接使用 `System.out.println`，日志要带上下文，且不要输出密码、令牌等敏感信息。复习时把 `System.out.println` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 3：第 3 题

- **题目**：防止 SQL 注入的正确做法是？
- **正确项**：使用 PreparedStatement 参数占位符
- **判断依据**：这道题检验本课主问题：Maven/Gradle、JUnit/Mockito、日志门面、JDBC 与常见框架选型。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 4：第 4 题

- **题目**：JUnit 5 中编写参数化测试使用哪个注解？
- **正确项**：@ParameterizedTest
- **判断依据**：这道题落在术语 `JUnit` 上：Java 常用的单元测试框架，用注解声明测试、断言和生命周期。复习时把 `JUnit` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 5：第 5 题

- **题目**：Gradle 中 settings.gradle 与 build.gradle 的分工是？
- **正确项**：settings 定义项目结构（包含哪些模块）
- **判断依据**：这道题检验本课主问题：Maven/Gradle、JUnit/Mockito、日志门面、JDBC 与常见框架选型。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 6：第 6 题

- **题目**：填空：补齐下面这段术语说明中的空缺。课程 `Maven/Gradle、JUnit/Mockito、日志门面、JDBC 与常见框架选型。`，这段说明是：`____`：Java 常用的单元测试框架，用注解声明测试、断言和生命周期。空缺处应填哪个术语？
- **正确项**：JUnit
- **判断依据**：这道题落在术语 `JUnit` 上：Java 常用的单元测试框架，用注解声明测试、断言和生命周期。复习时把 `JUnit` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 7：`System.out.println`

- **要点**：用 SLF4J 门面 + Logback/Log4j2 实现，避免直接使用 `System.out.println`；日志要带上下文，且不要输出密码、令牌等敏感信息。
- **System.out.println 的边界**：易错：生产日志无法统一收集；正确做法是用日志框架并分级。

### 考点 8：`JUnit`

- **要点**：Java 常用的单元测试框架，用注解声明测试、断言和生命周期。
- **JUnit 的边界**：越界、悬垂引用与释放顺序会破坏结论，必须在边界输入下复验。

### 考点 9：`JDBC`

- **要点**：JDBC 是基础，实际项目常用连接池（HikariCP）+ JPA/MyBatis。
- **JDBC 的边界**：只在「JDBC 是基础，实际项目常用连接池（HikariCP）+ JPA/MyBatis」这一前提下成立，换输入或换环境要重新验证。

### 考点 10：`依赖坐标`

- **要点**：groupId 加 artifactId 加版本号唯一确定一个构件，冲突时按最近优先规则解析。
- **依赖坐标 的边界**：不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。

### 考点 11：排错——用 `system` 路径引本地 jar

- **现象**：换机器就失败。
- **处理**：装进私服或本地仓库。

### 考点 12：排错——依赖版本互相冲突

- **现象**：`NoSuchMethodError`。
- **处理**：用 `dependency:tree` 排查。

### 考点 13：综合辨析——`System.out.println` 与 `依赖坐标`

- **辨析点**：`System.out.println` 的定义是 用 SLF4J 门面 + Logback/Log4j2 实现，避免直接使用 `System.out.println`；日志要带上下文，且不要输出密码、令牌等敏感信息；`依赖坐标` 的定义是 groupId 加 artifactId 加版本号唯一确定一个构件，冲突时按最近优先规则解析。
- **答题要求**：面对 `构建、测试与生态` 的题目，先判断描述的是 `System.out.println` 还是 `依赖坐标`，再归到对应定义，最后写出一个会让该定义失效的边界输入。

### 考点 14：排错评分点

- **现象分**：能写出 换机器就失败，而不是只写“程序有错”。
- **证据分**：保留触发 用 `system` 路径引本地 jar 的输入、版本和错误原文。
- **修复分**：按 装进私服或本地仓库 只改一处，并同时回归正常路径与边界路径。

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Java 21+ / Maven 或 Gradle
；本课聚焦 Maven。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Maven、Gradle、JUnit、Mockito、SLF4J、JDBC
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-02-24
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；本课核对关键词：Maven、Gradle、JUnit、Mockito、SLF4J、JDBC。

| 参考资料 | 本课用途 |
| --- | --- |
| [Gradle 文档](https://docs.gradle.org/current/userguide/userguide.html) | 构建脚本与依赖管理 |
| [JUnit 用户指南](https://junit.org/junit5/docs/current/user-guide/) | 自动化测试与断言 |
| [Java 并发教程](https://docs.oracle.com/javase/tutorial/essential/concurrency/) | 线程、同步与并发工具 |

| [本课术语索引：构建、测试与生态](#核心概念定义) | 按本课输入、术语边界和错误表现逐项核对 |
> 「构建、测试与生态」的链接用于离线阅读后的延伸核对；App 不会自动联网。