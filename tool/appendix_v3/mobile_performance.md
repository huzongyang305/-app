## 零基础详解：移动端性能优化

### 一句话说清它是什么

移动端性能只看三件事：**启动要快、滑动要顺、耗电要少**。
再加上两条底线：**不崩、不占爆内存**。所有优化都围绕「测量 → 定位 → 改一处 → 复测」。

### 用生活比喻理解

| 指标 | 比喻 | 用户感受 |
| --- | --- | --- |
| 启动时间 | 开门速度 | 等久了就退出 |
| 帧率 | 翻页流畅度 | 掉帧就是卡顿 |
| 内存 | 桌面空间 | 不够就杀后台 |
| 包体积 | 行李箱重量 | 太重就不愿下载 |
| 耗电 | 手机发热 | 费电就被卸载 |

### 五个核心指标与参考值

| 指标 | 定义 | 参考目标 |
| --- | --- | --- |
| 冷启动 | 进程从零到首帧 | 控制在 1 秒内（越高越好） |
| 帧率 | 每秒绘制帧数 | 60fps 机型稳定不掉帧 |
| 卡顿率 | 超过 16.7ms 的帧占比 | 越低越好 |
| 内存峰值 | 前台占用峰值 | 避免被系统杀进程 |
| 崩溃率 | 崩溃会话占比 | 低于 0.1% |

**Android 看 Perfetto、Android Studio Profiler；iOS 看 Instruments（Time Profiler、Allocations）；跨端再加一个端内埋点统计。**

### 启动优化：先看三段耗时

```text
1. 进程创建 → Application.onCreate：主要看 SDK 初始化
2. Activity 或 UIAbility 创建 → 首帧绘制：主要看布局复杂度
3. 首帧之后 → 可交互：主要看数据加载与网络请求
```

| 常见问题 | 对策 |
| --- | --- |
| 启动时初始化大量 SDK | 延迟到用的时候再初始化 |
| 同步读数据库或文件 | 移到后台线程，先展示骨架屏 |
| 首屏布局层级过深 | 减少嵌套，用约束布局或 Compose |
| 首页请求阻塞渲染 | 先渲染骨架，数据到了再填 |
| 启动时加载大图 | 用合适分辨率或占位图 |

```kotlin
// Android：把非关键初始化延后
class App : Application() {
    override fun onCreate() {
        super.onCreate()
        initCrashReporter()                 // 必须最早
        // 其余 SDK 延后到首帧之后
        ProcessLifecycleOwner.get().lifecycleScope.launch {
            delay(1_000)
            initAnalytics()
            initPushService()
        }
    }
}
```

### 渲染优化：掉帧的四个原因

| 原因 | 现象 | 对策 |
| --- | --- | --- |
| 主线程耗时 | 计算或 IO 阻塞 | 移到后台线程 |
| 布局层级过深 | 每次测量都很慢 | 扁平化、用约束 |
| 过度绘制 | 同一像素画多次 | 减少背景叠加 |
| 频繁创建对象 | GC 引发卡顿 | 复用、预分配 |

```kotlin
// 列表项复用 + 只更新变化部分
class ItemAdapter : ListAdapter<Item, VH>(DIFF) {
    companion object {
        private val DIFF = object : DiffUtil.ItemCallback<Item>() {
            override fun areItemsTheSame(a: Item, b: Item) = a.id == b.id
            override fun areContentsTheSame(a: Item, b: Item) = a == b
        }
    }
}
```

**用「只更新变化项」代替 `notifyDataSetChanged()`**，是列表流畅度的第一大功臣。

### 内存优化：三条纪律

```text
1. 及时释放：监听器、订阅、Bitmap、Cursor 都要在生命周期结束时清理
2. 避免泄漏：长生命周期对象不能持有 Activity 或 View
3. 控制峰值：大图按需降采样，列表用分页加载
```

```kotlin
// 泄漏的典型与修复
object Singleton {
    var activity: Activity? = null       // 错误：静态持有 Activity
}

class Screen : Fragment() {
    private val observer = Observer<Data> { render(it) }
    override fun onStart() { super.onStart(); store.observe(observer) }
    override fun onStop() { store.removeObserver(observer); super.onStop() }
}
```

**检测方式**：Android Studio Memory Profiler 抓堆快照，找「本该被回收却还在」的对象。

### 包体积优化

| 手段 | 效果 |
| --- | --- |
| 开启代码与资源压缩 | 去掉未使用代码与资源 |
| 按 ABI 拆分 | 用户只下载对应架构 |
| 图片转 WebP | 体积显著下降 |
| 移除未使用语言资源 | 减少资源体积 |
| 大资源走 CDN | 不占安装包 |

```bash
# Android 查看体积构成
./gradlew :app:analyzeReleaseBundle
```

### 网络与电量优化

| 原则 | 做法 |
| --- | --- |
| 减少请求数 | 合并接口、批量查询 |
| 减少数据量 | 只请求需要的字段 |
| 合理缓存 | 内存 + 磁盘两层，设过期时间 |
| 避免轮询 | 用推送或长连接 |
| 批量上报埋点 | 攒批后一次发送 |
| 后台任务延迟 | 用系统的延迟队列 |

### 监控：没有数据就没有优化

```text
必须采集的指标：
  · 冷启动耗时（分位数，不只看平均）
  · 卡顿与掉帧率
  · 内存峰值与 OOM 次数
  · 崩溃与 ANR 率
  · 关键页面加载耗时
```

**看 P95、P99 而不是平均值**：平均值会把最差的那部分用户体验完全掩盖。

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 凭感觉优化 | 改了没效果 | 先测量再改 |
| 只看平均值 | 长尾用户仍卡 | 看 P95 与 P99 |
| 在主线程做 IO | 掉帧、ANR | 移到后台线程 |
| 列表用 notifyDataSetChanged | 整表重建 | 用 DiffUtil |
| 大图不降采样 | 内存暴涨 | 按显示尺寸解码 |
| 监听器不注销 | 内存泄漏 | 生命周期配对注销 |
| 只优化 Release | 掩盖问题 | Debug 与 Release 都测 |
| 只在高端机测 | 低端机卡顿 | 用低端设备或限频测试 |

### 学完自测

- [ ] 能说出启动的三个阶段各自优化什么。
- [ ] 能说出掉帧的四个常见原因。
- [ ] 知道内存泄漏最典型的一类成因。
- [ ] 能说出三条减包体积的手段。
- [ ] 知道为什么性能指标要看分位数。
