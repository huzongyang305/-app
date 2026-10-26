# 代码块验证报告

生成时间：2026-10-26T12:59:33.738728

> 片段是课程里有意截取、无法独立编译的示例，不计入硬失败；
> 排错练习是课程里有意保留错误的代码，同样不计入硬失败；
> 告警多为多行 Shell 命令或依赖演示环境导致的结构提示，
> 硬失败为 0 表示所有可执行代码块都能通过验证或已明确标注为片段。

| 语言 | 通过 | 片段 | 排错练习 | 失败 |
| --- | ---: | ---: | ---: | ---: |
| `markdown | 1 | 0 | 0 | 0 |
| asm | 5 | 1 | 0 | 0 |
| awk | 1 | 0 | 0 | 0 |
| bash | 328 | 1 | 0 | 0 |
| c | 38 | 0 | 0 | 0 |
| cmake | 3 | 0 | 0 | 0 |
| cpp | 242 | 1 | 0 | 0 |
| cron | 1 | 0 | 0 | 0 |
| csharp | 118 | 0 | 0 | 0 |
| css | 42 | 0 | 0 | 0 |
| dart | 53 | 0 | 0 | 0 |
| dockerfile | 19 | 0 | 0 | 0 |
| dockerignore | 2 | 0 | 0 | 0 |
| gitignore | 1 | 0 | 0 | 0 |
| glsl | 1 | 0 | 0 | 0 |
| go | 96 | 0 | 0 | 0 |
| gotemplate | 1 | 0 | 0 | 0 |
| graphql | 19 | 0 | 0 | 0 |
| groovy | 2 | 0 | 0 | 0 |
| hcl | 24 | 0 | 0 | 0 |
| html | 22 | 0 | 0 | 0 |
| http | 6 | 0 | 0 | 0 |
| ini | 1 | 0 | 0 | 0 |
| java | 314 | 12 | 0 | 7 |
| javascript | 247 | 1 | 0 | 0 |
| js | 7 | 0 | 0 | 0 |
| json | 84 | 0 | 0 | 0 |
| jsonc | 3 | 0 | 0 | 0 |
| jsp | 2 | 0 | 0 | 0 |
| jsx | 35 | 0 | 0 | 0 |
| kotlin | 103 | 0 | 0 | 0 |
| lua | 4 | 0 | 0 | 0 |
| markdown | 2 | 0 | 0 | 0 |
| nginx | 1 | 0 | 0 | 0 |
| objc | 1 | 0 | 0 | 0 |
| powershell | 4 | 0 | 0 | 0 |
| prisma | 1 | 0 | 0 | 0 |
| proguard | 1 | 0 | 0 | 0 |
| promql | 15 | 0 | 0 | 0 |
| properties | 5 | 0 | 0 | 0 |
| protobuf | 4 | 0 | 0 | 0 |
| python | 886 | 5 | 0 | 0 |
| ruby | 2 | 0 | 0 | 0 |
| rust | 68 | 1 | 0 | 0 |
| shell | 1 | 0 | 0 | 0 |
| solidity | 6 | 0 | 0 | 0 |
| sql | 55 | 1 | 0 | 0 |
| svelte | 9 | 0 | 0 | 0 |
| swift | 80 | 0 | 0 | 0 |
| text | 1378 | 0 | 0 | 0 |
| toml | 5 | 0 | 0 | 0 |
| ts | 9 | 0 | 0 | 0 |
| tsx | 2 | 0 | 0 | 0 |
| typescript | 83 | 0 | 0 | 0 |
| verilog | 1 | 0 | 0 | 0 |
| vue | 9 | 0 | 0 | 0 |
| xml | 29 | 0 | 0 | 0 |
| yaml | 176 | 1 | 0 | 0 |

## 片段与依赖提示

- cross_cli_args:132 java 已标注片段
- database_olap:260 sql 已标注片段
- de_data_contract:173 python 已标注片段
- fundamentals_assembly:168 asm 已标注片段
- gamedev_2d_rendering:102 python 已标注片段
- gamedev_2d_rendering:183 python 已标注片段
- gamedev_animation_fsm:124 python 已标注片段
- gamedev_asset_pipeline:213 python 已标注片段
- go_testing:290 yaml 已标注片段
- javaweb_mybatis:264 java 已标注片段
- javaweb_spring_cloud:137 java 已标注片段
- java_data_access:111 java 已标注片段
- java_data_access:331 java 已标注片段
- java_data_access:424 java 已标注片段
- java_microservices:298 java 已标注片段
- java_modern_features:49 java 已标注片段
- java_project_ecommerce:307 java 已标注片段
- java_restful_api:169 java 已标注片段
- java_spring_security:81 java 已标注片段
- java_virtual_threads:108 java 已标注片段
- programming_cpp_project:299 cpp 已标注片段
- programming_rust_cli_project:287 rust 已标注片段
- shell_ci_templates:145 bash 已标注片段
- web_pwa_offline:149 javascript 已标注片段
- 未找到 Python 解释器，Python 代码块降级为结构校验（可设置 PYTHON 环境变量）
- ai_engineering:197 python 结构不平衡
- ai_multimodal:163 python 结构不平衡
- ai_vlm:130 python 结构不平衡
- algorithms_probabilistic_structures:114 python 结构不平衡
- algorithms_sorting_advanced:94 python 结构不平衡
- cross_collections:183 bash 结构不平衡
- devops_logging_tracing:181 ruby 结构不平衡
- devops_logging_tracing:269 ini 结构不平衡
- discrete_number_theory:232 python 结构不平衡
- fundamentals_assembly:259 bash 结构不平衡
- fundamentals_storage_stack:129 python 结构不平衡
- go_pprof:229 bash 结构不平衡
- java_spring_boot_intro:166 java C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\DemoApplication.java:3: 错误: 程序包org.springframework.boot不存在 import org.springframework.boot.SpringApplication;                                ^ C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\DemoApplication.java:4: 错误: 程序包org.springframework.boot.autoconfigure不存在 import org.springframework.boot.autoconfigure.SpringBootApplication;                                              ^ C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\DemoApplication.java:6: 错误: 找不到符号 @SpringBootApplication  // 一个注解搞定：配置 + 自动配置 + 组件扫描  ^   符号: 类 SpringBootApplication C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\DemoApplication.java:10: 错误: 找不到符号         SpringApplication.run(DemoApplication.class, args);         ^   符号:   变量 SpringApplication   位置: 类 DemoApplication 4 个错误 
- ml_recommendation_systems:609 python 结构不平衡
- ml_time_series_prediction:365 python 结构不平衡
- mobile_ios_appstore:279 bash 结构不平衡
- mobile_ios_testing:328 bash 结构不平衡
- programming_python_basics:268 python 结构不平衡
- programming_python_basics:576 python 结构不平衡
- programming_shell_flow:176 bash 结构不平衡
- python_first_script:268 python 结构不平衡
- se_test_design:140 python 结构不平衡
- shell_json_yaml:140 bash 结构不平衡
- shell_json_yaml:178 bash 结构不平衡
- shell_json_yaml:249 bash 结构不平衡
- shell_ops_scripts:149 bash 结构不平衡
- shell_ops_scripts:371 bash 结构不平衡
- shell_security:181 bash 结构不平衡
- shell_security:282 bash 结构不平衡
- visual_concurrency_schedule:209 bash 结构不平衡

## 失败明细

- java_microservices:174 java C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\EurekaServerApplication.java:1: 错误: 找不到符号 @SpringBootApplication  ^   符号: 类 SpringBootApplication C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\EurekaServerApplication.java:2: 错误: 找不到符号 @EnableEurekaServer  // 标记为注册中心  ^   符号: 类 EnableEurekaServer C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\EurekaServerApplication.java:5: 错误: 找不到符号         SpringApplication.run(EurekaServerApplication.class, args);         ^   符号:   变量 SpringApplication   位置: 类 EurekaServerApplication 3 个错误 
- java_microservices:204 java C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\ConfigServerApplication.java:1: 错误: 找不到符号 @SpringBootApplication  ^   符号: 类 SpringBootApplication C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\ConfigServerApplication.java:2: 错误: 找不到符号 @EnableConfigServer  // 标记为配置中心  ^   符号: 类 EnableConfigServer C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\ConfigServerApplication.java:5: 错误: 找不到符号         SpringApplication.run(ConfigServerApplication.class, args);         ^   符号:   变量 SpringApplication   位置: 类 ConfigServerApplication 3 个错误 
- java_microservices:235 java C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\GatewayApplication.java:1: 错误: 找不到符号 @SpringBootApplication  ^   符号: 类 SpringBootApplication C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\GatewayApplication.java:2: 错误: 找不到符号 @EnableDiscoveryClient  ^   符号: 类 EnableDiscoveryClient C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\GatewayApplication.java:5: 错误: 找不到符号         SpringApplication.run(GatewayApplication.class, args);         ^   符号:   变量 SpringApplication   位置: 类 GatewayApplication 3 个错误 
- java_microservices:278 java C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\UserServiceApplication.java:1: 错误: 找不到符号 @SpringBootApplication  ^   符号: 类 SpringBootApplication C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\UserServiceApplication.java:2: 错误: 找不到符号 @EnableDiscoveryClient  ^   符号: 类 EnableDiscoveryClient C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\UserServiceApplication.java:3: 错误: 找不到符号 @RestController  ^   符号: 类 RestController C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\UserServiceApplication.java:7: 错误: 找不到符号     public User getUser(@PathVariable Long id) {            ^   符号:   类 User   位置: 类 UserServiceApplication C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\UserServiceApplication.java:7: 错误: 找不到符号     public User getUser(@PathVariable Long id) {                          ^   符号:   类 PathVariable   位置: 类 UserServiceApplication C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\UserServiceApplication.java:6: 错误: 找不到符号     @GetMapping("/api/users/{id}")      ^   符号:   类 GetMapping   位置: 类 UserServiceApplication C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\UserServiceApplication.java:9: 错误: 找不到符号         return new User(id, "张三", "zhangsan@example.com");                    ^   符号:   类 User   位置: 类 UserServiceApplication C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\UserServiceApplication.java:13: 错误: 找不到符号         SpringApplication.run(UserServiceApplication.class, args);         ^   符号:   变量 SpringApplication   位置: 类 UserServiceApplication 8 个错误 
- java_microservices:335 java C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\OrderServiceApplication.java:1: 错误: 找不到符号 @SpringBootApplication  ^   符号: 类 SpringBootApplication C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\OrderServiceApplication.java:2: 错误: 找不到符号 @EnableDiscoveryClient  ^   符号: 类 EnableDiscoveryClient C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\OrderServiceApplication.java:3: 错误: 找不到符号 @EnableFeignClients  // 启用 Feign 远程调用  ^   符号: 类 EnableFeignClients C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\OrderServiceApplication.java:4: 错误: 找不到符号 @RestController  ^   符号: 类 RestController C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\OrderServiceApplication.java:8: 错误: 找不到符号     private UserClient userClient;  // Feign 客户端             ^   符号:   类 UserClient   位置: 类 OrderServiceApplication C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\OrderServiceApplication.java:11: 错误: 找不到符号     public OrderDetail getOrder(@PathVariable Long orderId) {            ^   符号:   类 OrderDetail   位置: 类 OrderServiceApplication C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\OrderServiceApplication.java:7: 错误: 找不到符号     @Autowired      ^   符号:   类 Autowired   位置: 类 OrderServiceApplication C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\OrderServiceApplication.java:11: 错误: 找不到符号     public OrderDetail getOrder(@PathVariable Long orderId) {                                  ^   符号:   类 PathVariable   位置: 类 OrderServiceApplication C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\OrderServiceApplication.java:10: 错误: 找不到符号     @GetMapping("/api/orders/{orderId}")      ^   符号:   类 GetMapping   位置: 类 OrderServiceApplication C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\OrderServiceApplication.java:13: 错误: 找不到符号         Order order = new Order(orderId, 1L, "iPhone 16", 5999.0);         ^   符号:   类 Order   位置: 类 OrderServiceApplication C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\OrderServiceApplication.java:13: 错误: 找不到符号         Order order = new Order(orderId, 1L, "iPhone 16", 5999.0);                           ^   符号:   类 Order   位置: 类 OrderServiceApplication C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\OrderServiceApplication.java:15: 错误: 找不到符号         User user = userClient.getUser(order.getUserId());         ^   符号:   类 User   位置: 类 OrderServiceApplication C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\OrderServiceApplication.java:16: 错误: 找不到符号         return new OrderDetail(order, user);                    ^   符号:   类 OrderDetail   位置: 类 OrderServiceApplication C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\OrderServiceApplication.java:20: 错误: 找不到符号         SpringApplication.run(OrderServiceApplication.class, args);         ^   符号:   变量 SpringApplication   位置: 类 OrderServiceApplication 14 个错误 
- java_project_ecommerce:811 java C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\EcommerceDemo.java:8: 错误: 找不到符号         Product product = productService.getProduct(100L);         ^   符号:   类 Product   位置: 类 EcommerceDemo C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\EcommerceDemo.java:8: 错误: 找不到符号         Product product = productService.getProduct(100L);                           ^   符号:   变量 productService   位置: 类 EcommerceDemo C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\EcommerceDemo.java:12: 错误: 找不到符号         CartItem cartItem = new CartItem(product.getId(), 2);         ^   符号:   类 CartItem   位置: 类 EcommerceDemo C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\EcommerceDemo.java:12: 错误: 找不到符号         CartItem cartItem = new CartItem(product.getId(), 2);                                 ^   符号:   类 CartItem   位置: 类 EcommerceDemo C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\EcommerceDemo.java:15: 错误: 找不到符号         Order order = orderService.createOrder(userId, List.of(         ^   符号:   类 Order   位置: 类 EcommerceDemo C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\EcommerceDemo.java:15: 错误: 找不到符号         Order order = orderService.createOrder(userId, List.of(                       ^   符号:   变量 orderService   位置: 类 EcommerceDemo C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\EcommerceDemo.java:16: 错误: 找不到符号             new OrderItemRequest(product.getId(), 2, product.getPrice())                 ^   符号:   类 OrderItemRequest   位置: 类 EcommerceDemo C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\EcommerceDemo.java:15: 错误: 找不到符号         Order order = orderService.createOrder(userId, List.of(                                                        ^   符号:   变量 List   位置: 类 EcommerceDemo C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\EcommerceDemo.java:21: 错误: 找不到符号         paymentService.handlePaymentCallback("PAY" + System.currentTimeMillis(), true);         ^   符号:   变量 paymentService   位置: 类 EcommerceDemo C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\EcommerceDemo.java:25: 错误: 找不到符号         Order completedOrder = orderService.getOrder(order.getId());         ^   符号:   类 Order   位置: 类 EcommerceDemo C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\EcommerceDemo.java:25: 错误: 找不到符号         Order completedOrder = orderService.getOrder(order.getId());                                ^   符号:   变量 orderService   位置: 类 EcommerceDemo 11 个错误 
- java_spring_core:299 java C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\Main.java:4: 错误: 找不到符号         ApplicationContext context = new AnnotationConfigApplicationContext(AppConfig.class);         ^   符号:   类 ApplicationContext   位置: 类 Main C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\Main.java:4: 错误: 找不到符号         ApplicationContext context = new AnnotationConfigApplicationContext(AppConfig.class);                                          ^   符号:   类 AnnotationConfigApplicationContext   位置: 类 Main C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\Main.java:4: 错误: 找不到符号         ApplicationContext context = new AnnotationConfigApplicationContext(AppConfig.class);                                                                             ^   符号:   类 AppConfig   位置: 类 Main C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\Main.java:7: 错误: 找不到符号         Chef chef = context.getBean(Chef.class);         ^   符号:   类 Chef   位置: 类 Main C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_493efd8c\Main.java:7: 错误: 找不到符号         Chef chef = context.getBean(Chef.class);                                     ^   符号:   类 Chef   位置: 类 Main 5 个错误 
