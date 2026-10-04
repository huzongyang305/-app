# Let's go.

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: Advanced

## Learning objectives

- It is possible to explain, in its own words, what was solved by Spring Boot REST API rather than just the term.
- The relationship between "real battles", "spring Boot" and "re relying on injections" is clear, with one example.
- It's a way to put the knowledge back into Java, and it tells us how much of this is going on.
- It is possible to complete this course and check its results using acceptance standards.

> A summary of the sentence: layered structure, dependence on injections, validation and integration tests.

## Pre-knowledge

- One lesson, Building, Testing and Ecology, is completed; if available, self-measurement can be done directly through this course.
- This course stage: Advanced. It is recommended to have a complete basis in the same direction, reading longer code, configuration or system design instructions.
- Before we start, let's review: the battle, Spring Boot, RRT.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## Project structure

```text
src/main/java/com/example/demo/
├── DemoApplication.java
├── controller/UserController.java
├── service/UserService.java
├── repository/UserRepository.java
└── model/User.java
```

Layer duties: processing HTTP, service carrying operations, repository access data and model expression of data structure.

## Dependency and Configuration

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

## Data Model and Validation

```java
public record User(Long id, @NotBlank String name, @Min(0) int age) { }
```

⟦ Original API request/response model; 1 and 2 are automatically verified by Bean Validation at the entrance.

## Service and controller

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

## Test

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

## Check ahead.

1. Aligning abnormalities (⟦) to the same wrong structure.
2. Logs use SLF4J to prohibit the printing of sensitive fields.
3. Configure externalisation (0 + environment variable).
4. Use the Actuator to expose health, access surveillance.

## It's the end of this class.
The key to Spring Boot is** layer + relying on injection + engagement better than configuration**: controller thin, service thick, repository only for data.

<!-- appendix:v1 -->

## Spring Boot, quick check.

|Notes|Role|
| --- | --- |
| `@SpringBootApplication` |Start class, group configuration and component scan|
| `@RestController` |RET controller, return value to JSON|
| `@RequestMapping` / `@GetMapping` / `@PostMapping` |Route Map|
| `@PathVariable` / `@RequestParam` |Path variable/ query parameters|
| `@RequestBody` |Request to be bound.|
| `@Valid` / `@Validated` |Trigger Parameter Verification|
| `@Service` / `@Repository` / `@Component` |Component statement|
| `@Configuration` + `@Bean` |Manual declaration, Bean|
| `@Autowired` |Injection (recommended builder injection, omitted)|
| `@Transactional` |Service boundary|
| `@ControllerAdvice` + `@ExceptionHandler` |Global anomalies.|
| `@ConfigurationProperties` |Bind Configuration|

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

## Slitting duty.

|Layer|Duties|Something you shouldn't have done.|
| --- | --- | --- |
| Controller |Parameter binding, verification, return state code|Write business rules, spell SQL|
| Service |Operational rules, boundaries and organization|Directly dependent on HTTP objects|
| Repository |Data access|Write business judgement.|
| DTO |External data structure|Direct exposure of entities and sensitive fields|
| Entity |Endurance model|Take interface back to format|

JPA Quick Check:

|Purpose|Writing|
| --- | --- |
|Query individual|Zero, go back to one.|
|Conditional queries| `findByStatusAndCreatedAtAfter(...)` |
|Page Break| `PageRequest.of(page, size, Sort.by("createdAt").descending())` |
|Avoid N+1|Zero or one.|
|Read-only services| `@Transactional(readOnly = true)` |
|Update & Return|⟦0 or ⟦1 batch update|
|Optimus lock.|⟦ Fields + Capture Post-Conflict Retest|
|Migration|Flyway / Liquibase|

## Common Error Table

|Easy to step on.|Actual|Reasons and correct practices|
| --- | --- | --- |
|Controller directly to the entity|Exposure sensitive fields, serialization|Convert with DTO|
|Field Injection|It's hard to test and hide.|Injecting with a constructor.|
|It's inside the service.|Business is not rolling back.|Only catch abnormalities that need to be handled, or manually mark back|
|Same internal approach to services|Not valid.|Call by proxy, or split Bean|
|Forget it.|Multiple semi-success|Declaring on Service level|
|It's not like I'm going to have a phone call.|Longer service, connected occupancy|External Call Out of Business|
|Entity Association Default Emergency Loading|Query slow, Carlyle.|Set up ⟦0 and use 1|
|Collapse SQL String|Infusion of risk|Named with arguments or Spring Data|
|Use the ⟦0 key|Leak.|Use environmental variables or configuration centres|
|Parameter verification handwritten if|Code repeat, missing.|Use ⟦0+Note|
|Use 500 to return business error|The client can't distinguish.|Use Zero to map the appropriate status code.|

## Self-Detected List

- [ ] The layers of responsibility are clear and Controller does not write business logic.
- [ ] Use a tectonic injection, relying on immutable.
- [ ] The service statement is on the Service level and does not contain a network call.
- [ ] Segregate entities with DTOs to avoid exposure of sensitive fields.
- [ ] The change in the database structure is managed by a migration script.

<!-- appendix:v3 -->

## Zero basic details: Java project skeletons

### What is it?

A deliverable Java service needs to be clearly structured, equipped with external features that can detect things and close them gracefully.
We're going to go through the whole skeleton with an order service.

### It's a life metaphor.

|Layer|A metaphor.|Duties|
| --- | --- | --- |
| Controller |Front desk.|Request accepted, verify and return|
| Service |The chef.|Operational rules and services|
| Repository |Warehouse|Only with the database.|
| DTO |Forms|External data structure|
| Entity |Inventory|Correspond to Table Structure|

### Package Structure

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

** Point: DTO separates from Entity and does not allow interface structures to follow the table structure.

### Layer

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

### Aligning anomalies: Do not return stacks to users

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

### Configure Externals and Verify

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

** Validation of configuration at startup** instead of running until half the missing variable is found.

### Health screening and indicators

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

### Three floors.

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

|Level|Tools|Overwrite|
| --- | --- | --- |
|Unit Test| JUnit 5 + Mockito |Operational rules|
|Slice test| `@WebMvcTest` |Controls and Sequencing|
|Integrated testing| `@SpringBootTest` + Testcontainers |Databases and external dependence|

### Pack it up as a mirror.

```dockerfile
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY target/app.jar app.jar
RUN useradd -r -u 1001 appuser && chown -R appuser /app
USER appuser
EXPOSE 8080
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-jar", "/app/app.jar"]
```

|Parameters|Role|
| --- | --- |
| `MaxRAMPercentage` |Scaled stacks in containers to avoid OOM Kill|
| `USER` |Not root running|
| `shutdown: graceful` |Request kept in motion for release|

### The eight most easy pits for freshmen.

|The pit.|phenomena|The right thing to do.|
| --- | --- | --- |
|Entity returns directly as interface|Disclosure Fields, Concord Table Structure|Convert with DTO|
|Injecting with Fields|Cyclical dependency, hard to test|Injecting with Constructive|
|Return the abnormal stack to the user|Discrepancies|Uniform abnormalities|
|Add business to Controller.|It's not clear.|Add to Service Method|
|Configure hard encoding|Change the code.|Use Environment Variables and Profile|
|Forget it.|On release 502|Turn on and set the timeout|
|Play the log with Zero.|Unable to rank and collect|SLF4J.|
|There's no limit to the contents.|By OOM Kill|Setup ⟦0|

### Learn how to measure yourself.

- [ Laughs ] Can you tell me what it is that Controller, Service and Repository are doing?
- [ Chuckles ] Know why DTO wants to be separated from Entity.
- [ ] The advantage of a tectonic injection compared to the field.
- [ Chuckles ] Know why it's opening.
- [ ] The parameters for limiting memory in the container can be stated.

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of this course: Repeating, experimenting and delivering around "The Field, Spring Boots," each result is subject to scrutiny.

Run through the smallest class and test, then make up for anomalies and parallel borders, and finally observe changes in wiring and resources.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the problem with Spring Boot API?
2. Without it, what concrete consequences would there be?
3. What does it have to do with Spring Boot?

**Standard of acceptance: at least one keyword appears and a reverse example, boundary conditions or lapse scenario is written.

### Practice 2: A controlled experiment (20 minutes)

Select a minimum example from the text to do the following:

1. Forecasts the result of a modification of an parameter, input or step.
2. It's actually being implemented or progressively, and the results are going to be real.
3. If results differ from projections, the reasons for differences are stated.

**Receiving standard**: leave a five-step record of "Previously changing the predictions and causes".

### Practice 3: Delivery of a small result (30 minutes)

Writes a runable subcategory, adds an ordinary test and a border input test.

Mission requests:

- The result must be checked, not just “I understand”.
- At least cover the key words "real battle" and "spring Boot."
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- project-verification:v1 -->

## Validation command and expected output

The project code does not read only " Compilable " , but repeats the results by a fixed command.

|Phase|Command|Expected output|
| --- | --- | --- |
|Compile| `./mvnw -q -DskipTests package` |Generate JAR and compile without error|
|Run Test| `./mvnw test` |The junit test is passed.|
|Start Service| `java -jar target/app.jar` |Port listen successfully and output startup log|

### Evidence of acceptance

- [ ] Save the complete output relying on installation and start-up orders.
- [ ] Run at least 3 tests containing an illegal input or failure path.
- [ ] Repeat the same operation twice and confirm that there are no duplicates or side effects.
- [ ] Record a failure code, wrong log and recovery steps.
- [ ] Provide an environmental version, start-up and rollback in README.

### Return and Roll

1. Start with an abandoned directory or temporary database to avoid contamination of real data.
2. Rerun all authentication orders after a logical change to confirm that they are not returned.
3. If you fail, roll back to the previous runable version and keep the failed log.
4. The reason for the location is supplemented by an automated test and re-execution process.
5. The lessons are included in the project ' s repertoire or in a note, which will form the next inspection.

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Project: Spring Boot API

**Summary:** Layering, DI, validation and integration tests.

**Category:** Java  
**Level:** Advanced
**Key terms:** field, Spring Boot, RST, relying on injection, testing

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: advanced
- Applicable context: Java 21+ / Maven or Gradle
- Source: Internal structured curriculum and engineering practices
- Related topics: fieldwork, Spring Boots, RET dependence on injection, testing
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

## Specifications for the project: fielding Boot REST API

### Core scene

The goal of the project is to translate "activism, Spring Boot, RET, relying on injections, testing" into operational, testable and rolling deliverables.

### Structures and data flows

```text
用户/输入 → 接口或命令 → 领域逻辑 → 存储/外部依赖 → 输出与监控
                         ↘ 失败分类 → 重试/补偿 → 回滚
```

### Minimum Data Model

|Object|Key Fields|Constraints|
| --- | --- | --- |
|Enter entity|Actual, time and source|Keys to verify, limit the length, etc.|
|Task entity|Status, priority, creation|It's legal, it can't be repeated|
|Result entity|Output, Error Code, Time|Sequencable. Errors.|
|Audit records|Operator, action, result, time|It's unmovable, searchable and dissensitive.|

### Receiving scenes

1. Normal path: The minimum input receives the expected output, leaving a log and an indicator.
2. Boundary path: Empty, maximum, duplicated data and super-long content are explicitly addressed.
3. Failed path: fast failure, retest or downgrade if you rely on excess time.
4. Paths, etc.: The execution of the same request will not have repeated side effects.
5. Rollback path: Backroll data are consistent and indicate recovery time and impact.

<!-- project-delivery:v1 -->

## Project delivery

### Suggested warehouse structure

```text
src/main/java/
src/main/resources/
src/test/java/
pom.xml
README.md
```

### Test Matrix

|Level|Overwrite|Minimum|Adoption of standards|
| --- | --- | ---: | --- |
|Unit Test|Field rules, boundaries and misclassification| 8 |It's normal. The border, the path to failure.|
|Integrated testing|Database, network, document or platform boundary| 3 |Use real boundaries and run again|
|End-to-end testing|Core User Path| 1 |Full run from input to output|
|Manually.|5 scenes listed in the document| 5 |Orders, output and conclusion records|

### Receiving and Inspection Data

```json
{
  "project": "java_project",
  "input": {"case": "normal", "value": 5},
  "expected": {"ok": true, "result": 5},
  "failure_case": {"value": -1, "error": "validation_error"},
  "idempotency_key": "demo-001"
}
```

### Duplicate Template

|Problem|Records|
| --- | --- |
|What was the original target?|I'll give you a description of the acceptable target.|
|What's going on?|Timeline, indicators and key logs|
|Which assumption was overturned?|Root causes and contributing factors|
|How do you roll back?|Steps, time-consuming and data validation|
|What's next?|Responsible persons, duration and certification|

> Project acceptance revolved around "Performance, Spring Boot, REST": at least one normal route, one border entry, one failed recovery and one swirl check.

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**Project: Spring Boot API** focuses on Layering, DI, validation and integration tests.

### Learning Outcomes

- Explain what **Project: Spring Boot API** solves and when it should be used.
- Identify inputs, outputs, state and failure boundaries.
- Build a minimal reproducible example and observe the real result.
- Test normal, boundary and failure paths.
- Measure performance, resource cost or security impact before optimizing.
- Document the decision, rollback path and remaining uncertainty.

### Core Mental Model

1. **Problem first:** define the exact problem before choosing a tool or pattern.
2. **Smallest example:** reduce the system to one input and one observable output.
3. **State and flow:** trace how data, control or responsibility moves through the system.
4. **Boundaries:** identify invalid input, resource limits, timeouts and permission edges.
5. **Evidence:** use tests, logs, metrics or reproductions instead of intuition.
6. **Trade-offs:** compare correctness, latency, cost, complexity and operability.

### Step-by-step Study Plan

1. Read the Chinese lesson once and write down the main problem in one sentence.
2. Run the smallest example and save the exact command and output.
3. Change only one input or parameter and predict the result before running it.
4. Introduce one failure and record how the system detects, reports and recovers.
5. Write one test or checklist item for the normal, boundary and failure paths.
6. Complete the quiz and explain every wrong answer in your own words.

### Practice Tasks

- Rebuild the minimal example from an empty directory.
- Add one boundary test and one failure test.
- Produce a short report containing the baseline, change, result and rollback.

### Common Failure Modes

- Treating a happy-path demo as production readiness.
- Skipping boundary values and invalid inputs.
- Optimizing before establishing a measurable baseline.
- Hiding errors, permissions or resource limits.

### Self-check Questions

1. What is the smallest observable result that proves this lesson works?
2. What input or state is most likely to break it?
3. Which metric or test would reveal a regression?
4. What is the rollback path?
5. What is the cost of using this approach at 10x scale?
6. Which adjacent topic is most often confused with this one?

### Glossary

- Topic: **Project: Spring Boot API**
- Relaid terms: actual, Spring Boot, RET, dependent on injection
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning objectives |
|Pre-knowledge| Prerequisites |
|Project structure|Project structure|
|Dependency and Configuration|Dependency and Configuration|
|Data Model and Validation|DataModel and Verify|
|Service and controller|Service and controller|
|Test| Testing |
|Check ahead.|Check ahead.|
|It's the end of this class.| Summary |
|Spring Boot, quick check.|Spring Boot, quick check.|

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

