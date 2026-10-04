## 补充：指令分类、寄存器与调用约定

### 四类基础指令

| 类别 | 作用 | 典型指令（x86-64 / ARM64） |
| --- | --- | --- |
| 数据传送 | 在寄存器与内存间搬数据 | `mov` / `ldr`、`str` |
| 算术逻辑 | 加减乘除与位运算 | `add`、`sub`、`and` / `add`、`and` |
| 控制流 | 跳转、条件分支 | `jmp`、`je` / `b`、`b.eq` |
| 函数调用 | 调用与返回 | `call`、`ret` / `bl`、`ret` |

```asm
# 一段可读的汇编骨架（伪代码风格）
main:
    mov  eax, 5          ; 把 5 放进寄存器 eax
    mov  ebx, 3          ; 把 3 放进 ebx
    add  eax, ebx        ; eax = eax + ebx = 8
    cmp  eax, 10         ; 比较 eax 与 10
    jl   smaller         ; 若小于则跳转
    mov  eax, 0
    ret
smaller:
    mov  eax, 1
    ret
```

### 寄存器的分工

| 用途 | x86-64 | ARM64 |
| --- | --- | --- |
| 返回值 | `rax` | `x0` |
| 函数参数 | `rdi, rsi, rdx, rcx, r8, r9` | `x0 ~ x7` |
| 栈指针 | `rsp` | `sp` |
| 帧指针 | `rbp` | `x29` |
| 被调用者保存 | `rbx, rbp, r12-r15` | `x19 ~ x28` |
| 调用者保存（易失） | `rax, rcx, rdx, rsi, rdi, r8-r11` | `x0 ~ x18` |

```text
「调用者保存」与「被调用者保存」的意义
  · 易失寄存器：函数可以随意用，调用方若要保留需自己先保存
  · 非易失寄存器：被调函数若要用，必须先保存并在返回前恢复
  · 违反约定会导致「上一个函数的值莫名改变」这类诡异 bug
```

### 从 C 到汇编：三个对照

```c
// ① 简单加法：参数用寄存器传入，返回值放 rax/x0
int add(int a, int b) { return a + b; }
```

```asm
add:
    lea  eax, [rdi + rsi]    ; x86-64：结果直接算进 eax
    ret
```

```c
// ② 局部变量：可能被放在栈上，也可能被优化进寄存器
int calc(int x) { int y = x * 2; return y + 1; }
```

```asm
calc:
    lea  eax, [rdi*2 + 1]    ; -O2 下直接被折叠成一条指令
    ret
```

```c
// ③ 函数调用：参数入寄存器，call 压入返回地址
int main(void) { return add(1, 2); }
```

```asm
main:
    mov  edi, 1
    mov  esi, 2
    sub  rsp, 8              ; 对齐栈（ABI 要求 16 字节对齐）
    call add
    add  rsp, 8
    ret
```

### 栈帧的建立与销毁

```text
典型函数序言（prologue）
  push rbp            ; 保存调用者的帧指针
  mov  rbp, rsp       ; 建立自己的帧
  sub  rsp, 32        ; 为局部变量预留空间

典型函数尾声（epilogue）
  mov  rsp, rbp       ; 释放局部变量
  pop  rbp            ; 恢复帧指针
  ret                 ; 弹出返回地址并跳回

-O2 常把「只用到少量寄存器」的函数优化成无帧指针（frame pointer omission），
此时调试器读栈会困难一些，可用 -fno-omit-frame-pointer 保留
```

### 怎么自己看懂汇编

```bash
# 1. 生成汇编
gcc -S -O2 -masm=intel demo.c -o demo.s

# 2. 反汇编已有二进制
objdump -d --demangle ./app | less
objdump -d -M intel ./app | grep -A 20 "<main>:"

# 3. 交叉调试：看某行 C 对应的汇编
gdb ./app
(gdb) disassemble /m main
```

### 自查清单

- [ ] 能说出四类基础指令各自的作用
- [ ] 知道 x86-64 与 ARM64 的参数寄存器
- [ ] 能解释「调用者保存」与「被调用者保存」
- [ ] 能看懂函数序言与尾声
- [ ] 会用 `objdump` 或 `gcc -S` 查看汇编

