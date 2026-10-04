# 代码块验证报告

生成时间：2026-10-05T00:14:58.254547

| 语言 | 通过 | 失败 |
| --- | ---: | ---: |
| `markdown | 1 | 0 |
| asm | 6 | 0 |
| awk | 1 | 0 |
| bash | 225 | 9 |
| c | 10 | 0 |
| cmake | 6 | 0 |
| cpp | 107 | 2 |
| cron | 1 | 0 |
| csharp | 106 | 0 |
| css | 7 | 0 |
| dart | 16 | 0 |
| dockerfile | 7 | 0 |
| gitignore | 1 | 0 |
| go | 89 | 0 |
| groovy | 1 | 0 |
| hcl | 1 | 0 |
| html | 9 | 0 |
| http | 7 | 0 |
| java | 122 | 1 |
| javascript | 126 | 0 |
| js | 8 | 0 |
| json | 91 | 0 |
| jsonc | 3 | 0 |
| jsx | 1 | 0 |
| kotlin | 23 | 0 |
| lua | 3 | 0 |
| markdown | 1 | 0 |
| nginx | 3 | 0 |
| powershell | 2 | 0 |
| properties | 5 | 0 |
| protobuf | 4 | 0 |
| python | 488 | 0 |
| rust | 63 | 3 |
| sql | 45 | 0 |
| swift | 12 | 0 |
| text | 1048 | 2 |
| toml | 4 | 0 |
| ts | 9 | 0 |
| tsx | 7 | 0 |
| typescript | 70 | 0 |
| xml | 13 | 0 |
| yaml | 38 | 0 |

## 依赖/片段提示

- cross_cli_args:98 java C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_3bd02520\App.java:1: 错误: 程序包picocli不存在 import picocli.CommandLine;               ^ C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_3bd02520\App.java:2: 错误: 程序包picocli.CommandLine不存在 import picocli.CommandLine.Option;                           ^ C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_3bd02520\App.java:3: 错误: 程序包picocli.CommandLine不存在 import picocli.CommandLine.Parameters;                           ^ C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_3bd02520\App.java:6: 错误: 找不到符号     @Parameters(index = "0", description = "输入文件")      ^   符号:   类 Parameters   位置: 类 App C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_3bd02520\App.java:8: 错误: 找不到符号     @Option(names = {"-o", "--output"}, description = "输出路径")      ^   符号:   类 Option   位置: 类 App C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_3bd02520\App.java:10: 错误: 找不到符号     @Option(names = {"-v", "--verbose"}, description = "输出详细日志")      ^   符号:   类 Option   位置: 类 App C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_3bd02520\App.java:14: 错误: 找不到符号         new CommandLine(new App()).execute(args);             ^   符号:   类 CommandLine   位置: 类 App 7 个错误 
- cross_cli_args:186 bash 结构不平衡
- programming_rust_basics:251 rust 结构不平衡
- programming_rust_types_traits:72 rust 结构不平衡
- programming_rust_types_traits:263 rust 结构不平衡
- programming_shell_flow:90 bash 结构不平衡
- programming_shell_flow:193 bash 结构不平衡
- programming_shell_flow:248 bash 结构不平衡
- programming_shell_flow:280 bash 结构不平衡
- programming_shell_script_engineering:182 bash 结构不平衡
- shell_json_yaml:258 bash 结构不平衡
- shell_security:48 bash 结构不平衡
- shell_security:243 bash 结构不平衡
- visual_concurrency_schedule:31 text 结构不平衡
- visual_git_states:94 text 结构不平衡

## 失败明细

无
