## 全生命周期排查速查

| 阶段 | 关注点 | 常用工具 |
| --- | --- | --- |
| 源码 | 语法、类型、静态缺陷 | 编译器告警、linter、静态分析 |
| 编译 | 优化与生成 | `gcc -S`、`objdump`、LLVM 优化记录 |
| 链接 | 符号与依赖 | `nm`、`ldd`、`readelf` |
| 加载 | 依赖库、地址布局 | `strace`、`/proc/<pid>/maps` |
| 运行 | 系统调用、资源占用 | `strace`、`perf`、`top`、`pidstat` |
| 内存 | 泄漏、越界 | ASan、Valgrind、`pmap` |
| IO | 磁盘与网络 | `iostat`、`iotop`、`tcpdump` |
| 崩溃 | 堆栈与转储 | gdb、core dump、`dmesg` |

```bash
# 一条命令串起常见排查动作（示例：程序启动失败）
file ./app                          # 确认架构与动态链接类型
ldd ./app                           # 检查依赖库是否齐全
nm -C ./app | grep -i main          # 确认入口符号存在
strace -f -e trace=openat,execve ./app 2>&1 | tail -n 30   # 看加载与失败点

# 运行期观察
./app & pid=$!
cat /proc/$pid/maps | head          # 虚拟内存布局
cat /proc/$pid/status | grep -E 'VmRSS|Threads'
perf stat -p $pid sleep 5           # 硬件事件统计

# 崩溃后分析（需先开启 core dump）
ulimit -c unlimited
gdb -batch -ex run -ex bt ./app
```

```python
import subprocess

def run_diagnostics(binary: str) -> dict:
    """收集一个可执行文件的基础诊断信息。"""
    def capture(args):
        try:
            result = subprocess.run(args, capture_output=True, text=True, timeout=10)
            return result.stdout.strip()
        except (OSError, subprocess.SubprocessError) as exc:
            return f"执行失败：{exc}"

    return {
        "file": capture(["file", binary]),
        "deps": capture(["ldd", binary]),
        "missing_symbols": capture(["nm", "-u", binary]),
    }


info = run_diagnostics("/bin/ls")     # 换成自己的产物路径即可
print(info["file"])
```

## 问题定位顺序速查

| 现象 | 先查什么 | 再看什么 |
| --- | --- | --- |
| 启动即退出 | 退出码、依赖库 | `strace` 打开的文件 |
| 运行崩溃 | 堆栈、core dump | ASan 报告 |
| 内存持续增长 | RSS 曲线 | 分配热点、泄漏检测 |
| CPU 高但吞吐低 | 火焰图 | 锁竞争、系统调用 |
| IO 等待高 | `iostat`、`iotop` | 缓存命中率、文件访问模式 |
| 网络超时 | `ss`、`tcpdump` | DNS、TLS、重传 |
| 偶发错误 | 日志与追踪 ID | 复现条件与并发场景 |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 不确认错误就动手改 | 修错地方 | 先看错误信息与日志 |
| 只看应用日志 | 错过系统层面原因 | 结合 `dmesg`（OOM、IO 错误） |
| 用 `strace` 直接在生产跑全量 | 性能严重下降 | 限定系统调用与时长，或用采样工具 |
| 不看退出码 | 无法判断失败原因 | 记录并解释每个非零码 |
| 关闭优化靠猜 bug | 掩盖真实问题 | 用 ASan、UBSan 定位 UB |
| 只压测不监控 | 压塌了才发现 | 同步观察资源与错误率 |
| 无 core dump 就分析崩溃 | 只能猜 | 提前开启 core dump 并保留符号 |
| 忽略构建一致性 | 本地与线上行为不同 | 固定工具链与依赖版本 |
| 改动多个变量同时验证 | 无法归因 | 一次只改一个变量 |
| 排查完不沉淀 | 同类问题重复排查 | 写成 runbook 与自动化脚本 |

## 自测清单

- [ ] 能按「源码、编译、链接、加载、运行」逐层定位问题。
- [ ] 会用 `file`、`ldd`、`nm`、`strace` 排查启动失败。
- [ ] 会用 `/proc` 查看内存与线程信息。
- [ ] 崩溃分析前准备好 core dump 与符号。
- [ ] 结论会沉淀为可复用的排查脚本。
