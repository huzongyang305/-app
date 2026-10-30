# 构建、测试与生态

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：45 分钟

![Java 构建、测试、日志与数据库工具](images/diagram_java_tooling.webp)

![构建、测试与生态](images/remaining_java_tooling.webp)

## 本节知识框架

写完了 Java 代码，接下来要解决"怎么跑起来"的问题。想象你开了一家餐厅：Maven/Gradle 是施工队负责拉材料、编译、打包；JUnit 是验收员负责自动检查菜品质量；日志系统是你的监控摄像头记录每天发生了什么；JDBC 是通往仓库的通道让你存取食材。

**本课你将学到：**
- Maven 和 Gradle 的基本用法
- JUnit 5 写单元测试
- 日志框架的正确使用方式
- JDBC 数据库访问与防 SQL 注入

**先修要求：** 学完前面所有 Java 基础课程即可。

### 复习清单

- [ ] 能说出 Maven 和 Gradle 的三个区别
- [ ] 能用 JUnit 5 写一个包含断言和异常断言的测试
- [ ] 能解释为什么不该用 System.out.println 做日志

## 核心概念定义

| 术语 | 一句话说明 |
| --- | --- |
| Maven | 基于 XML 的构建工具，约定优于配置，pom.xml 管理依赖和构建流程。 |
| Gradle | 基于 Groovy/Kotlin DSL 的构建工具，增量构建更快，build.gradle 配置。 |
| JUnit | Java 最常用的单元测试框架，用注解声明测试、断言和生命周期。 |
| JDBC | Java 数据库连接标准 API，实际项目常用连接池 + JPA/MyBatis。 |
| Mockito | 用 mock 对象把外部依赖假扮出来，测试只验证自己这一层的分支。 |
| SLF4J | 日志门面，只规定「怎么调用」；真正的写出与分级由 Logback 或 Log4j2 完成。 |
| 依赖范围 | Maven 的 scope 决定依赖是否进入产物，test 依赖只在测试 classpath 可见。 |
| Wrapper | mvnw 与 gradlew 把构建工具本体和版本一起提交，换机器不必手工安装。 |

## 原理与运行机制

### Maven vs Gradle

```text
对比维度      Maven                    Gradle
─────────────────────────────────────────────────────
配置格式      pom.xml (XML)            build.gradle (Groovy/Kotlin)
编译命令      mvn compile              gradle compileJava
测试命令      mvn test                 gradle test
打包命令      mvn package              gradle build
依赖树        mvn dependency:tree      gradle dependencies
学习曲线      平缓                     前期略陡
构建速度      一般                     增量与缓存更好
```

### Maven pom.xml 关键片段

```xml
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

### Gradle build.gradle 关键片段

```groovy
plugins { id 'java' }
java { toolchain { languageVersion = JavaLanguageVersion.of(21) } }
repositories { mavenCentral() }
dependencies {
    testImplementation 'org.junit.jupiter:junit-jupiter:5.10.0'
}
```

settings.gradle 定义项目结构（包含哪些模块），build.gradle 定义构建逻辑和依赖。

### JUnit 5 测试

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

    @ParameterizedTest
    @CsvSource({"1,2,3", "0,0,0", "-1,1,0"})
    void addsVarious(int a, int b, int expected) {
        assertEquals(expected, Calculator.add(a, b));
    }
}
```

### 日志的正确用法

```java
private static final Logger log = LoggerFactory.getLogger(Service.class);

log.info("创建订单 id={} userId={}", orderId, userId);
log.warn("库存不足 sku={}", sku);
log.error("下单失败 userId={}", userId, exception);
```

用 SLF4J 门面 + Logback/Log4j2 实现，避免直接使用 System.out.println。

### JDBC 数据库访问

```java
try (Connection conn = DriverManager.getConnection(url, user, password);
     PreparedStatement ps = conn.prepareStatement(
         "SELECT name FROM users WHERE id = ?")) {
    ps.setLong(1, userId);
    try (ResultSet rs = ps.executeQuery()) {
        if (rs.next()) System.out.println(rs.getString("name"));
    }
}
```

永远使用 PreparedStatement 防 SQL 注入，不要拼接 SQL 字符串。

### settings.gradle 与 build.gradle 的分工

`settings.gradle` 只回答一件事：这个项目由哪些模块组成。里面通常只有 `rootProject.name` 和几行 `include`。`build.gradle` 回答的是另一个问题：这个模块怎么构建——插件、仓库、依赖、任务都写在它里面。多模块工程漏提交 `settings.gradle` 时，Gradle 会把当前目录当成孤立项目，子目录的源码根本不参与编译，而报错信息往往只是「找不到符号」，不会点出真正原因。

```text
settings.gradle   rootProject.name = 'order'
                  include 'app', 'domain', 'infra'
build.gradle      根目录那份只放公共配置，每个模块目录各有一份自己的
```

公共部分可以收在根构建脚本里，也可以用 `gradle/libs.versions.toml` 这个 version catalog 集中管版本号，升级 JUnit 时只改一行，不会出现某个模块还在用旧版本的情况。

### Maven 走生命周期，Gradle 走任务图

Maven 的构建是按固定阶段推进的：`clean`、`compile`、`test`、`package`、`install`、`deploy`，执行到某阶段时前面的阶段一定会先跑完，你没法只跑其中一段。Gradle 执行的是任务图：`build` 由 `compileJava`、`test`、`jar` 等任务组成，靠输入输出声明决定谁先谁后，没有变化的任务可以整段跳过（UP-TO-DATE），也能从另一台机器的缓存里直接取结果。

这个差别决定了两个工具的排错入口不一样：Maven 出问题看「阶段有没有跑到」，Gradle 出问题看「任务为什么被判定为最新」——加 `--info` 或 `--scan` 才能看到跳过原因。

### 依赖冲突为什么到运行期才炸

构建工具解决版本时用的是「路径最近优先，同深度先声明优先」，所以最终 classpath 里只会有一个版本，编译期看不出异常。等到运行期调用了一个只在新版本存在的方法，抛出的就是 `NoSuchMethodError` 或 `NoClassDefFoundError`。定位时 Maven 用 `mvn dependency:tree -Dverbose`，Gradle 用 `gradle dependencies --configuration runtimeClasspath`，看清是谁把旧版本带进来的，再用 exclusion 或强制版本（Gradle 的 `resolutionStrategy.force`）收敛。

### 让结论可复现的三个固定量

同一份代码在别人的机器上跑不通，多半是这三处没锁：JDK 版本（Gradle 用 `toolchain`，Maven 用 `maven.compiler.release`）、构建工具版本（提交 mvnw 与 gradlew）、以及依赖版本（避免用 LATEST 或范围版本）。测试还要额外锁时区与随机种子，否则一条今天通过的用例明天就会翻。本课之所以强调「覆盖边界输入」，正是因为只跑正常值时，版本差异根本暴露不出来——溢出、空集合、极大值这些边界才会把不同版本的行为差摊开。

### 日志与数据库访问的接缝

`System.out.println` 无法分级、无法带线程与上下文、也无法被采集端按级别过滤，所以生产代码统一走 SLF4J 门面。日志和 JDBC 是同一条链路上的两段：出问题时靠日志里的 `orderId` 定位，靠数据库里的记录核对状态，因此日志要带上业务主键，但绝不能带上密码、令牌或完整身份证号——这些字段在写出前就要脱敏。

SQL 注入的根源在于拼接把「数据」当成了「SQL 结构」：`"... WHERE name = '" + input + "'"` 里，用户输入一个 `' OR '1'='1` 就能改写查询逻辑。`PreparedStatement` 的占位符走的是预编译加参数绑定，参数永远是值，不会参与 SQL 语法解析，所以填什么都改不了查询结构。要注意 `?` 只能替换值，表名、列名、排序方向这类结构必须用白名单映射，不能靠占位符。

## 典型应用场景

| 场景 | 推荐做法 | 为什么 |
| --- | --- | --- |
| 新项目构建 | Maven 或 Gradle | 依赖管理、编译、打包一体化 |
| 单元测试 | JUnit 5 + Mockito | 行业标准，注解丰富 |
| 日志记录 | SLF4J + Logback | 门面模式，可切换实现 |
| 数据库访问 | JDBC + HikariCP | 连接池提升性能 |
| 防 SQL 注入 | PreparedStatement | 参数化查询 |
| 多模块拆分 | settings.gradle 里 include，版本集中在 version catalog | 升一次版本，所有模块一起生效 |
| 排查「编译过、运行炸」 | dependency:tree 或 gradle dependencies | 谁把旧版本带进来，只有依赖树知道 |
| 校验金额与边界输入 | @ParameterizedTest 配 @CsvSource | 一张表格就能覆盖空值、极值、负数 |
| CI 里加速构建 | 提交 wrapper 并缓存本地仓库与构建缓存 | 缓存命中才是增量构建省时间的那一半 |

### 一次典型的排查动作

线上报 `NoSuchMethodError`，本地却能跑：先确认两边的 JDK 与依赖版本是否一致（`java -version` 与 `gradle dependencies`），再比对 CI 用的 wrapper 版本；如果版本一致，就检查是不是某个 fat jar 打包时把两个同名类都塞了进去。整个过程不要靠「重装一遍环境」来定位——那会把线索抹掉。

## 代码/协议/SQL 示例

### 完整测试示例

```java
class PriceCalculatorTest {
    private PriceCalculator calculator;

    @BeforeEach
    void setUp() { calculator = new PriceCalculator(); }

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

### Mockito 隔离依赖

```java
UserRepository repo = mock(UserRepository.class);
when(repo.findById(1L)).thenReturn(Optional.of(new User("tom")));
```

### CI 质量门禁

```text
检查              工具
──────────────────────────────
单元测试          JUnit 5
覆盖率            JaCoCo
静态分析          SpotBugs
代码格式          Spotless
依赖漏洞          OWASP Dependency-Check
```

### 最小可跑：从空目录到第一条测试

先把「能编译、能跑测试」这条最短路径走通，再谈模块拆分。目录约定不能改：主代码在 `src/main/java`，测试在 `src/test/java`，两边包名一致才能互相找到。

```bash
# Gradle 版本锁进仓库，换机器不需要手装
gradle wrapper --gradle-version 8.10
./gradlew --version          # 打印 Gradle 与本机 JDK 版本，这就是排查冲突的第一步
./gradlew test --info        # 看哪些任务 UP-TO-DATE，哪些真的跑了
```

```text
order/
├── settings.gradle
├── build.gradle
└── src
    ├── main/java/com/example/Calculator.java
    └── test/java/com/example/CalculatorTest.java
```

### 参数化测试：把边界输入写成一张表

`@ParameterizedTest` 的作用是把「同一套逻辑、多组输入」压成一个方法，JUnit 5 会为每一行数据单独生成一次执行，失败时能指出是哪一行数据出错。光测正常值等于没测，至少要带上一条空值、一条极值、一条非法输入。

```java
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.MethodSource;
import java.util.stream.Stream;

class ShippingTest {
    @ParameterizedTest(name = "{0} 元订单应收 {1}")
    @CsvSource({"0, 10", "99, 10", "100, 0", "-1, ERROR"})
    void checksBoundary(String amount, String expected) {
        var value = new java.math.BigDecimal(amount);
        if (expected.equals("ERROR")) {
            org.junit.jupiter.api.Assertions.assertThrows(
                    IllegalArgumentException.class, () -> Shipping.fee(value));
            return;                                   // 非法输入这条只看异常，不比较返回值
        }
        org.junit.jupiter.api.Assertions.assertEquals(
                new java.math.BigDecimal(expected), Shipping.fee(value));
    }

    static Stream<java.math.BigDecimal> hugeAmounts() {
        return Stream.of(java.math.BigDecimal.valueOf(9999999),
                         new java.math.BigDecimal("0.01"));
    }

    @ParameterizedTest
    @MethodSource("hugeAmounts")
    void neverNegativeFee(java.math.BigDecimal amount) {
        org.junit.jupiter.api.Assertions.assertTrue(
                Shipping.fee(amount).signum() >= 0);
    }
}
```

用 `BigDecimal` 而不是 `double` 处理金额是这里顺手带出的另一个习惯：二进制浮点表示不了 0.1，累加之后误差会显形。

### 防注入的两段对照

```java
// 错：输入里的引号会改写 SQL 结构
String sql = "SELECT id FROM orders WHERE mobile = '" + mobile + "'";

// 对：占位符只接受值，值不参与语法解析
String safe = "SELECT id FROM orders WHERE mobile = ?";
try (PreparedStatement ps = conn.prepareStatement(safe)) {
    ps.setString(1, mobile);
    try (ResultSet rs = ps.executeQuery()) {
        while (rs.next()) log.debug("命中订单 id={}", rs.getLong("id"));
    }
}
```

排序字段、表名这类结构无法用 `?` 替换，只能先在服务端做白名单映射（例如只允许 `id`、`created_at` 两个值），映射不到就直接拒绝请求。

### 练习

给上面 `Shipping.fee` 补一条 `@CsvSource` 数据：金额为空字符串。先猜它会抛什么异常，再跑测试验证，最后把这个「猜与验证」的过程写进提交说明。

## 时间/空间复杂度或性能分析

- **Gradle 增量构建**：只编译变化的文件，比 Maven 全量编译快很多
- **测试并行执行**：JUnit 5 支持 @Execution(CONCURRENT) 并行跑测试
- **连接池**：HikariCP 复用数据库连接，避免每次请求创建新连接的开销
- **日志占位符**：log.info("msg {}", arg) 比字符串拼接快，不抛异常时不拼接

### 构建耗时花在哪

一次全量构建的时间大致分成依赖解析、编译、测试、打包四块。依赖解析走网络，首次最慢，之后靠本地仓库缓存；编译随源码规模线性增长；测试通常是最贵的一块，所以先确认「是不是所有测试都被重跑」。Gradle 的增量能力来自它对任务输入输出的记录，任何一处写到构建脚本里的当前时间、随机数、绝对路径，都会让输入始终变化，增量收益当场归零——这类问题在 CI 上尤其常见。

### 并行与连接池要一起调

测试并行度提高后，如果用例都要连数据库或起本地服务，瓶颈会立刻从 CPU 转移到连接数。判断方法是把并行度改成 1 与 4 各跑一次：耗时几乎不变说明用例是 IO 受限，加线程没用，要先扩连接池或改用内存数据库；耗时明显下降才说明之前确实是 CPU 受限。连接池大小不是越大越好，池子超过数据库能承载的并发时，等待只是从应用侧挪到了数据库侧。

### 日志本身的开销

`log.debug` 在关闭 DEBUG 级别时几乎不产生成本，因为参数不会被格式化；一旦为了「保险」把所有日志都写成 info，磁盘写入和采集带宽就会变成可见开销，还会把真正的错误淹没。带异常对象时把 throwable 作为最后一个参数交给日志框架，别自己 `e.getMessage()` 拼字符串，那样会丢掉堆栈。

## 常见误区与易错点

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用 system 路径引本地 jar | 换机器就失败 | 装进私服或本地仓库 |
| 依赖版本冲突 | NoSuchMethodError | 用 dependency:tree 排查 |
| 忘提交 wrapper | 构建环境不一致 | 提交 mvnw / gradlew |
| 用 System.out.println 调试 | 生产日志无法统一收集 | 用日志框架并分级 |
| 测试依赖不标 test 范围 | 打包体积变大 | 测试依赖标 test scope |
| SQL 字符串拼接 | SQL 注入风险 | 用 PreparedStatement |
| 日志打印密码或令牌 | 安全事件 | 脱敏处理 |
| 测试之间共享静态状态 | 单跑通过一起跑失败 | 每个用例独立准备数据 |
| 只测正常输入就收工 | 版本差异与边界 bug 到线上才暴露 | 参数化测试里补空值、极值、非法值三类数据 |
| 表名或排序字段也想用占位符 | `?` 只接受值，SQL 结构替换不了 | 结构部分走服务端白名单映射 |
| 构建脚本里写当前时间或绝对路径 | Gradle 任务永远重跑，增量与缓存全部失效 | 输入只放源码与声明过的依赖 |
| 依赖版本写成范围或 LATEST | 今天能构建，明天换机器就复现不了 | 锁死具体版本，用 BOM 或 version catalog 统一管理 |
| 用 e.printStackTrace 代替日志 | 错误散落在标准错误流，采集不到也查不到上下文 | 把异常对象作为最后一个参数交给日志框架 |

### 三条验收口径

一份构建配置算不算「能用」，看这三条：换一台干净机器 clone 下来能一次构建成功；同一份代码跑两次结果字节一致或可解释；任何一条测试失败都能只凭测试报告定位到具体输入。这三条正好对应本课强调的「固定版本、覆盖边界、说明失败路径」。

## 与其他知识点的关系

- **先修**：前面所有 Java 课程
- **后续**：《实战：Spring Boot REST API》——本课工具链在实战中综合运用
- **关联**：《Lambda 与 Stream API》——测试数据准备常用 Stream

**这几个工具各自管哪一段**：构建工具管「源码怎么变成可运行的产物」，测试框架管「怎么证明产物行为符合预期」，日志门面管「运行期出了问题能不能查回来」，JDBC 管「怎么和数据库说话」。它们串成一条链，任何一段缺失都会在别的段留下症状：没有测试的构建只能靠线上验证，没有日志的测试失败在 CI 上就只剩一行堆栈。

**与其他语言生态的对照**：Maven 与 Gradle 相当于 Node 的 npm 加上打包工具、Python 的 pip 加上虚拟环境。差异在于 Java 的依赖解析发生在构建期且最终只保留一个版本，所以版本冲突表现为运行期报错，而不是像某些语言那样可以在同一进程里共存多个版本。

**与《实战：Spring Boot REST API》的接缝**：Spring Boot 的 starter 本质是一组预先对齐好版本的依赖集合，它替你解决了本课「依赖冲突」那一行的问题；但 wrapper、toolchain、日志分级和参数化测试这些做法不会因为你换了框架就失效，实战课里默认你已经把它们配好。

## 自测题与参考答案

1. **Maven 和 Gradle 有什么区别？** Maven 用 XML 配置，Gradle 用 Groovy/Kotlin DSL；Gradle 增量构建更快。
2. **JUnit 5 参数化测试用什么注解？** @ParameterizedTest 配合 @ValueSource 或 @CsvSource。
3. **为什么不该用 System.out.println 做日志？** 无法分级、无法统一收集、无法带上下文。用 SLF4J + Logback。
4. **怎么防止 SQL 注入？** 永远使用 PreparedStatement 参数占位符，不要拼接 SQL 字符串。
5. **settings.gradle 和 build.gradle 有什么区别？** settings 定义项目结构（包含哪些模块），build 定义构建逻辑和依赖。

## 考点精讲

`构建、测试与生态` 的题库有 6 道题，下面逐题给出题干、正确项与判断依据。

### 考点 1：第 1 题

- **题目**：围绕“构建、测试与生态”中的 Maven、Gradle、JUnit，下列哪两项是本课强调的实践判断？
- **正确项**：学习 Maven 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 Gradle 时要固定版本并覆盖边界输入，结论才可复现
- **判断依据**：按《构建、测试与生态》的正文口径，本题要同时选中「学习 Maven 时要同时说明输入、输出和失败路径，不能只看正常流程」、「验证 Gradle 时要固定版本并覆盖边界输入，结论才可复现」，漏掉任一项都算没答全。术语 JUnit（构建、测试与生态）：Java 常用的单元测试框架，用注解声明测试、断言和生命周期。易错点是用 system 路径引本地 jar，会造成换机器就失败，改法是装进私服或本地仓库。

### 考点 2：第 2 题

- **题目**：`构建、测试与生态` 的示例代码用于验证 `System.out.println`，其背景是Maven/Gradle、JUnit/Mockito、日志门面、JDBC 与常见框架选型。代码的真实内容是下面哪一项？
- **正确项**：出现字面量 `java`
- **判断依据**：本题正确项是「出现字面量 `java`」。术语 System.out.println（构建、测试与生态）：用 SLF4J 门面 + Logback/Log4j2 实现，避免直接使用 `System.out.println`，日志要带上下文，且不要输出密码、令牌等敏感信息，本题取「出现字面量 `java`」这条。易错点是依赖版本冲突，改法是用 dependency:tree 排查。本题干扰项「出现字面量 `出现禁止内容：{keyword}`」不成立：展示代码里找不到 `出现禁止内容：{keyword}`。

### 考点 3：第 3 题

- **题目**：防止 SQL 注入的正确做法是？
- **正确项**：使用 PreparedStatement 参数占位符
- **判断依据**：本题正确项是「使用 PreparedStatement 参数占位符」。术语 System.out.println（构建、测试与生态）：用 SLF4J 门面 + Logback/Log4j2 实现，避免直接使用 `System.out.println`，日志要带上下文，且不要输出密码、令牌等敏感信息，本题取「使用 PreparedStatement 参数占位符」这条。易错点是忘提交 wrapper，会造成构建环境不一致，改法是提交 mvnw / gradlew。

### 考点 4：第 4 题

- **题目**：JUnit 5 中编写参数化测试使用哪个注解？
- **正确项**：@ParameterizedTest
- **判断依据**：本题正确项是「@ParameterizedTest」。术语 JUnit（构建、测试与生态）：Java 常用的单元测试框架，用注解声明测试、断言和生命周期，本题取「@ParameterizedTest」这条。易错点是用 System.out.println 调试，会造成生产日志无法统一收集，改法是用日志框架并分级。

### 考点 5：第 5 题

- **题目**：Gradle 中 settings.gradle 与 build.gradle 的分工是？
- **正确项**：settings 定义项目结构（包含哪些模块）
- **判断依据**：本题正确项是「settings 定义项目结构（包含哪些模块）」。术语 System.out.println（构建、测试与生态）：用 SLF4J 门面 + Logback/Log4j2 实现，避免直接使用 `System.out.println`，日志要带上下文，且不要输出密码、令牌等敏感信息，本题取「settings 定义项目结构（包含哪些模块）」这条。易错点是测试依赖不标 test 范围，会造成打包体积变大，改法是测试依赖标 test scope。

### 考点 6：第 6 题

- **题目**：填空：补齐下面这段术语说明中的空缺。课程 `Maven/Gradle、JUnit/Mockito、日志门面、JDBC 与常见框架选型。`，这段说明是：`____`：Java 常用的单元测试框架，用注解声明测试、断言和生命周期。空缺处应填哪个术语？
- **正确项**：JUnit
- **判断依据**：《构建、测试与生态》这题的填空口径是「JUnit」或「junit」，正文写法与其中任一项一致即可。术语「JUnit」在本课里的界定是Java 常用的单元测试框架，用注解声明测试、断言和生命周期，题干问的就是这一条。常见错法是用 `system` 路径引本地 jar，其后果是换机器就失败。正确做法是装进私服或本地仓库。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| Maven | 基于 XML 的构建工具，pom.xml 管理依赖 |
| Gradle | 基于 DSL 的构建工具，增量构建更快 |
| JUnit | Java 单元测试框架，注解声明测试 |
| Mockito | 模拟依赖对象的测试框架 |
| SLF4J | 日志门面，搭配 Logback 使用 |
| PreparedStatement | 参数化 SQL 查询，防注入 |
| mvnw 与 gradlew | 随仓库提交的构建入口，锁定构建工具版本 |
| 依赖树 | dependency:tree 或 gradle dependencies 输出的版本仲裁结果 |
| toolchain | 声明工程所需的 JDK 版本，构建时自动匹配而不是沿用本机默认 |
| scope | 依赖的可见范围，test 依赖不进最终产物，provided 由运行容器提供 |
| version catalog | libs.versions.toml 集中管理版本号，多模块共用一套 |
| JaCoCo | 统计测试覆盖率的插件，覆盖率是线索不是目标 |

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-02-24
- 复核范围：版本兼容、API 行为、安全建议与工程实践

| 参考资料 | 本课用途 |
| --- | --- |
| [Maven 官方指南](https://maven.apache.org/guides/) | Maven 依赖与构建配置 |
| [Gradle 用户指南](https://docs.gradle.org/current/userguide/userguide.html) | Gradle 构建脚本与依赖管理 |
| [JUnit 5 用户指南](https://junit.org/junit5/docs/current/user-guide/) | 自动化测试与断言 |

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Java 21+ / Maven 或 Gradle；本课聚焦 Maven。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Maven、Gradle、JUnit、Mockito、SLF4J、JDBC
