## 链接与加载速查

| 概念 | 作用 |
| --- | --- |
| 符号表 | 记录已定义与未定义的符号 |
| 重定位 | 修正代码与数据中的地址引用 |
| 静态链接 | 库代码复制进可执行文件 |
| 动态链接 | 运行时由动态链接器加载共享库 |
| PLT | 过程链接表，实现延迟绑定 |
| GOT | 全局偏移表，存放外部符号地址 |
| ASLR | 地址空间布局随机化，提升安全性 |
| PIC | 位置无关代码，可加载到任意地址 |
| 装载器 | 把可执行文件与依赖映射进内存 |

常见错误与含义：

| 错误 | 含义 | 处理方式 |
| --- | --- | --- |
| `undefined reference to foo` | 符号未定义（未链接实现或库） | 补实现或加 `-l` |
| `multiple definition of x` | 同一符号重复定义 | 头文件放声明、源文件放定义 |
| `cannot open shared object file` | 运行时找不到共享库 | 设置 rpath 或检查安装路径 |
| `symbol lookup error` | 运行时符号缺失 | 检查版本与依赖库 |
| `undefined symbol: _Z...` | C++ 名字修饰不匹配 | 用 `extern "C"` 或统一编译器 |

```bash
# 静态库：归档一组目标文件
gcc -c util.c -o util.o
ar rcs libutil.a util.o
gcc main.c -L. -lutil -o app

# 共享库：编译为位置无关代码再打包
gcc -fPIC -c util.c -o util.o
gcc -shared -o libutil.so util.o
gcc main.c -L. -lutil -Wl,-rpath,'$ORIGIN' -o app

# 常用诊断命令
nm -C app | head                 # 查看符号（C++ 名字还原）
ldd app                          # 查看动态依赖
readelf -d app | grep -i rpath   # 查看 rpath
objdump -d -M intel app | head   # 反汇编
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 库顺序写反 | `undefined reference` | 被依赖的库放在依赖者后面 |
| 在头文件定义全局变量 | 多重定义 | 用 `extern` 声明或 `inline` 变量 |
| 共享库未加 `-fPIC` | 链接或加载失败 | 编译共享库必须加 `-fPIC` |
| 用绝对路径设置 rpath | 换环境后失效 | 用 `$ORIGIN` 相对路径 |
| 直接依赖 `LD_LIBRARY_PATH` | 部署易遗漏 | 用 rpath 或标准库目录 |
| C++ 库给 C 调用不加 `extern "C"` | 符号找不到 | 用 `extern "C"` 包裹声明 |
| 静态与动态库同名混用 | 链接到意外版本 | 明确指定路径与链接方式 |
| 忘记 `-lm` 等系统库 | 数学函数未定义 | 补齐所需库 |
| 认为 `ldd` 列出的是全部依赖 | 分析偏差 | 只列直接依赖，间接依赖需逐层看 |
| 关闭 ASLR 调试后忘记恢复 | 安全性下降 | 用调试器临时设置，不改系统默认 |

## 自测清单

- [ ] 能说清静态链接与动态链接的取舍。
- [ ] 知道 PLT 与 GOT 的作用（延迟绑定）。
- [ ] 会用 `nm`、`ldd`、`readelf` 排查符号与依赖问题。
- [ ] 共享库编译一定加 `-fPIC`。
- [ ] 部署时用 rpath 或标准目录而不是临时环境变量。
