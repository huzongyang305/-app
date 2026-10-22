## 补充：SSA、循环优化与优化级别的取舍

### IR 的三种常见形态

| 形态 | 特点 | 典型用途 |
| --- | --- | --- |
| 三地址码 | 每条指令一个运算，结构简单 | 教学与基础优化 |
| SSA | 每个变量只赋值一次，带 φ 函数 | 现代编译器主力形式 |
| 控制流图 CFG | 基本块 + 跳转边 | 数据流分析与循环优化 |

```text
一段分支代码的 SSA 形式

原始代码
  if (cond) x = 1; else x = 2;
  use(x);

SSA 形式（φ 表示「依控制流从哪个分支来选哪个值」）
  if (cond) goto L1; else goto L2;
  L1: x1 = 1; goto L3;
  L2: x2 = 2; goto L3;
  L3: x3 = φ(x1, x2);
      use(x3);
```

**为什么要 φ**：SSA 要求每个变量只定义一次，分支汇合点必须显式表示
「值从哪里来」，这样后续分析不必再做复杂的到达定值计算。

### 六种优化的前后对比

```text
① 常量折叠与传播
   const int N = 4; int a[N * 2];
   → int a[8];

② 公共子表达式消除
   x = (a + b) * c; y = (a + b) / c;
   → t = a + b; x = t * c; y = t / c;

③ 死代码消除
   int unused = compute();   // compute 无副作用
   → 整行删除

④ 循环不变量外提
   for (i...) { sum += a[i] * len; }      // len 不变
   → const L = len; for (i...) { sum += a[i] * L; }

⑤ 强度削减
   for (i...) { x = i * 4; }
   → for (i...) { x += 4; }                // 乘法换成加法

⑥ 内联
   int getX() { return _x; }
   obj.getX() * 2  → obj._x * 2
```

### 循环优化为何最重要

```text
经验规律：程序 90% 的时间花在 10% 的循环上

因此编译器在循环上投入的优化最多：
  · 循环展开：减少循环控制开销，增加指令级并行
  · 循环融合/分裂：改善缓存局部性
  · 循环交换：让内存访问更连续（矩阵遍历的经典优化）
  · 向量化：一次处理多个数据（SIMD），-O3 常见

矩阵遍历示例（行优先存储）
  for i: for j: sum += m[i][j]     ← 连续访问，快
  for j: for i: sum += m[i][j]     ← 跨行跳跃，慢（可能差数倍）
```

### 优化级别与「未定义行为」的坑

| 级别 | 会做的事 | 风险 |
| --- | --- | --- |
| `-O0` | 不做优化，便于调试 | 性能差 |
| `-O1` | 基础优化，编译快 | 少 |
| `-O2` | 绝大多数安全优化 | 少（仍可能暴露 UB） |
| `-O3` | 激进向量化与展开 | 代码膨胀、可能暴露 UB |
| `-Ofast` | 放宽浮点语义 | **数值结果可能变化** |

```text
UB（未定义行为）为什么危险
  编译器假设 UB 不会发生，据此做优化。
  例：有符号溢出是 UB → 编译器可能认为「i + 1 > i 恒成立」，
      从而删掉本该存在的边界检查。

实践建议
  · 用 -fsanitize=undefined 在测试时捕获 UB
  · 浮点敏感场景不用 -Ofast，改用 -O2
  · 关键代码对比不同优化级别的输出，确认结果一致
```

### 怎么观察优化是否生效

```bash
# C/C++：输出汇编或 IR 对比
g++ -O0 -S demo.cpp -o demo_O0.s
g++ -O2 -S demo.cpp -o demo_O2.s
diff demo_O0.s demo_O2.s | head -40

# LLVM：看优化后的 IR
clang -O2 -S -emit-llvm demo.cpp -o demo.ll

# Rust：直接看 MIR 与汇编
cargo rustc --release -- --emit asm

# Java：JIT 打印内联与编译决策
java -XX:+PrintCompilation -XX:+UnlockDiagnosticVMOptions -XX:+PrintInlining App
```

### 自查清单

- [ ] 能说出 SSA 与 φ 函数的作用
- [ ] 能举出四种优化并写出前后对比
- [ ] 知道为什么会话循环是优化重点
- [ ] 理解 UB 如何导致「反直觉」的优化结果
- [ ] 会用 `-S` 或 IR 输出验证优化是否生效

