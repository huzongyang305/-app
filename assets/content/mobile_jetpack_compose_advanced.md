# Android Jetpack Compose进阶

![Android Jetpack Compose进阶示意图](images/lesson_ai_realtime_api.webp)

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：45 分钟

## Chapter Overview

Jetpack Compose是Google推出的现代Android UI工具包，它用声明式的方式彻底改变了Android界面开发。就像从手绘地图升级到GPS导航，你不再需要手动管理View的生命周期、findViewById和复杂的Adapter，而是专注于描述"界面应该是什么样子"。本章将深入探讨Compose的核心概念、状态管理、布局系统、动画效果、与现有View系统的互操作，以及高级性能优化技巧。

## Learning Objectives

学完本章后，你将能够：

1. 理解Compose的声明式编程模型和重组（Recomposition）机制
2. 熟练使用State、remember、mutableStateOf等状态管理API
3. 掌握Column、Row、Box、LazyColumn等布局组件的使用
4. 创建流畅的动画效果和自定义绘制逻辑
5. 实现Material Design 3风格的现代化界面
6. 在Compose中集成传统View组件并处理性能优化

## Core Concepts with Life Analogies

### 重组机制：像翻新的房间布置

想象你的房间是一个UI界面，家具是各种组件。在传统Android开发中，如果你想换个沙发位置，你需要亲自搬动它（命令式）。而在Compose中，你只需要告诉设计师"我希望沙发在窗户旁边"（声明式），当你的需求变化时，设计师会自动重新布置整个房间（重组）。重组不是每次都从头开始，Compose足够聪明，只会更新变化的部分，就像设计师只移动需要调整的家具，其他保持不变。

### State Hoisting：像集中控制的智能家居

State Hoisting（状态提升）就像把家里所有电器的遥控器都集中到一个中央控制面板。以前每个房间都有自己的开关（状态分散在各个View中），现在所有控制都汇总到ViewModel或父Composable中。子组件通过参数接收状态（就像房间接收中央面板的指令），并通过回调函数上报事件（就像房间向中央面板发送请求）。这样使得状态流动清晰可预测，便于测试和维护。

### Modifier链：像给礼物层层包装

Compose的Modifier就像给礼物包装的多层包装纸。你可以先包一层红色包装纸（background），再加一个蝴蝶结（padding），最后贴上标签（clickable）。每一层Modifier都会改变组件的外观或行为，并且顺序很重要：先加padding再设背景，和先设背景再加padding，视觉效果完全不同。Modifier是不可变的，每次调用都返回一个新的Modifier实例，形成一条处理链。

## Progressive Code Examples

### 最小示例：基础Text显示

```kotlin
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun Greeting(name: String) {
    Text(
        text = "Hello, $name!",
        style = MaterialTheme.typography.headlineMedium,
        modifier = Modifier.padding(16.dp)
    )
}
```

### 完整示例：新闻列表应用

```kotlin
import android.graphics.BitmapFactory
import androidx.compose.animation.core.spring
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.painter.BitmapPainter
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.IOException
import java.net.URL

// 数据模型
data class NewsArticle(
    val id: Int,
    val title: String,
    val summary: String,
    val author: String,
    val publishDate: String,
    val imageUrl: String,
    val category: String,
    var isBookmarked: Boolean = false
)

// ViewModel
class NewsViewModel : androidx.lifecycle.ViewModel() {
    private val _newsList = mutableStateListOf<NewsArticle>()
    val newsList: List<NewsArticle> = _newsList
    
    private val _isLoading = mutableStateOf(false)
    val isLoading: Boolean get() = _isLoading.value
    
    init {
        loadNews()
    }
    
    private fun loadNews() {
        _isLoading.value = true
        // 模拟网络请求
        kotlinx.coroutines.GlobalScope.launch(Dispatchers.IO) {
            kotlinx.coroutines.delay(1500)
            val mockNews = listOf(
                NewsArticle(
                    id = 1,
                    title = "Jetpack Compose正式发布稳定版",
                    summary = "Google宣布Jetpack Compose 1.0正式发布，标志着Android UI开发进入声明式时代...",
                    author = "科技日报",
                    publishDate = "2026-10-15",
                    imageUrl = "",
                    category = "技术"
                ),
                NewsArticle(
                    id = 2,
                    title = "Android 15新特性全面解析",
                    summary = "最新版本的Android系统带来了隐私保护、性能优化和开发者体验的全面升级...",
                    author = "安卓中文网",
                    publishDate = "2026-10-12",
                    imageUrl = "",
                    category = "系统"
                ),
                NewsArticle(
                    id = 3,
                    title = "Kotlin Multiplatform移动开发实践",
                    summary = "使用Kotlin Multiplatform实现业务逻辑跨平台共享，减少代码重复...",
                    author = "开发者周刊",
                    publishDate = "2026-10-10",
                    imageUrl = "",
                    category = "开发"
                )
            )
            _newsList.addAll(mockNews)
            _isLoading.value = false
        }
    }
    
    fun toggleBookmark(articleId: Int) {
        val index = _newsList.indexOfFirst { it.id == articleId }
        if (index != -1) {
            _newsList[index] = _newsList[index].copy(isBookmarked = !_newsList[index].isBookmarked)
        }
    }
}

// 新闻卡片组件
@Composable
fun NewsCard(
    article: NewsArticle,
    onBookmarkClick: () -> Unit,
    onShareClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        shape = RoundedCornerShape(12.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            // 分类标签
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Chip(
                    onClick = {},
                    colors = ChipDefaults.chipColors(
                        containerColor = MaterialTheme.colorScheme.primaryContainer
                    )
                ) {
                    Text(
                        text = article.category,
                        style = MaterialTheme.typography.labelSmall
                    )
                }
                
                Row {
                    IconButton(onClick = onBookmarkClick) {
                        Icon(
                            imageVector = Icons.Default.Bookmark,
                            contentDescription = "收藏",
                            tint = if (article.isBookmarked) 
                                MaterialTheme.colorScheme.primary 
                            else 
                                MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    
                    IconButton(onClick = onShareClick) {
                        Icon(
                            imageVector = Icons.Default.Share,
                            contentDescription = "分享"
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // 标题
            Text(
                text = article.title,
                style = MaterialTheme.typography.titleLarge.copy(
                    fontWeight = FontWeight.Bold
                ),
                maxLines = 2
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // 摘要
            Text(
                text = article.summary,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 3
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // 作者和日期
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = article.author,
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.primary
                )
                
                Text(
                    text = article.publishDate,
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

// 主界面
@Composable
fun NewsListScreen(viewModel: NewsViewModel = NewsViewModel()) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("今日新闻") },
                colors = TopAppBarDefaults.mediumTopAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                )
            )
        }
    ) { paddingValues ->
        if (viewModel.isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentPadding = PaddingValues(vertical = 8.dp)
            ) {
                items(viewModel.newsList) { article ->
                    NewsCard(
                        article = article,
                        onBookmarkClick = { viewModel.toggleBookmark(article.id) },
                        onShareClick = { /* 分享逻辑 */ }
                    )
                }
            }
        }
    }
}
```

### 实践示例：自定义动画仪表盘

```kotlin
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.Transition
import androidx.compose.animation.core.transitionFloat
import androidx.compose.animation.core.updateTransition
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

// 自定义圆形进度指示器
@Composable
fun CircularProgressIndicator(
    progress: Float,
    size: Float = 200f,
    strokeWidth: Float = 12f,
    backgroundColor: Color = Color.Gray.copy(alpha = 0.3f),
    progressColor: Color = MaterialTheme.colorScheme.primary,
    modifier: Modifier = Modifier
) {
    val sweepAngle = 360f * progress
    
    Canvas(
        modifier = modifier.size(size.dp)
    ) {
        val center = Offset(size / 2, size / 2)
        val radius = size / 2 - strokeWidth
        
        // 绘制背景圆环
        drawCircle(
            color = backgroundColor,
            radius = radius,
            center = center,
            style = Stroke(width = strokeWidth)
        )
        
        // 绘制进度圆弧
        drawArc(
            color = progressColor,
            startAngle = -90f,
            sweepAngle = sweepAngle,
            useCenter = false,
            topLeft = Offset(strokeWidth / 2, strokeWidth / 2),
            size = androidx.compose.ui.geometry.Size(size - strokeWidth, size - strokeWidth),
            style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
        )
        
        // 绘制中心百分比文字
        val textMeasurer = rememberTextMeasurer()
        val textLayoutResult = textMeasurer.measure(
            text = "${(progress * 100).toInt()}%",
            style = androidx.compose.ui.text.TextStyle(
                fontSize = androidx.compose.ui.unit.TextUnit.Companion.Sp(24),
                fontWeight = FontWeight.Bold,
                color = progressColor,
                textAlign = TextAlign.Center
            )
        )
        
        drawContext.canvas.nativeCanvas.apply {
            drawText(
                "${(progress * 100).toInt()}%",
                center.x - textLayoutResult.size.width / 2,
                center.y + textLayoutResult.size.height / 3,
                android.graphics.Paint().apply {
                    color = android.graphics.Color.parseColor(
                        String.format("#%06X", (0xFFFFFF and progressColor.toArgb()))
                    )
                    textSize = 48f
                    textAlign = android.graphics.Paint.Align.CENTER
                    isFakeBoldText = true
                }
            )
        }
    }
}

// 带动画的统计卡片
@Composable
fun StatCard(
    title: String,
    value: Int,
    targetValue: Int,
    icon: String,
    color: Color,
    modifier: Modifier = Modifier
) {
    var expanded by remember { mutableStateOf(false) }
    val animatedValue by animateIntAsState(
        targetValue = if (expanded) targetValue else 0,
        animationSpec = spring(dampingRatio = 0.8f, stiffness = 300f)
    )
    
    Card(
        modifier = modifier
            .fillMaxWidth()
            .animateContentSize()
            .pointerInput(Unit) {
                detectTapGestures { expanded = !expanded }
            },
        shape = MaterialTheme.shapes.medium,
        colors = CardDefaults.cardColors(
            containerColor = color.copy(alpha = 0.1f)
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = icon,
                fontSize = androidx.compose.ui.unit.TextUnit.Companion.Sp(32)
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium
            )
            
            Spacer(modifier = Modifier.height(4.dp))
            
            Text(
                text = "$animatedValue",
                style = MaterialTheme.typography.headlineLarge.copy(
                    fontWeight = FontWeight.Bold,
                    color = color
                )
            )
            
            if (expanded) {
                Spacer(modifier = Modifier.height(8.dp))
                
                LinearProgressIndicator(
                    progress = animatedValue.toFloat() / targetValue,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(8.dp),
                    color = color,
                    trackColor = color.copy(alpha = 0.3f)
                )
                
                Spacer(modifier = Modifier.height(4.dp))
                
                Text(
                    text = "目标: $targetValue",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

// 仪表盘主界面
@Composable
fun DashboardScreen() {
    var cpuProgress by remember { mutableStateOf(0f) }
    var memoryProgress by remember { mutableStateOf(0f) }
    
    // 模拟数据加载动画
    LaunchedEffect(Unit) {
        kotlinx.coroutines.delay(500)
        cpuProgress = 0.75f
        memoryProgress = 0.62f
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("系统仪表盘") },
                colors = TopAppBarDefaults.mediumTopAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // 圆形进度指示器
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(250.dp),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(
                    progress = cpuProgress,
                    progressColor = MaterialTheme.colorScheme.primary
                )
            }
            
            // 统计卡片
            StatCard(
                title = "CPU使用率",
                value = (cpuProgress * 100).toInt(),
                targetValue = 100,
                icon = "⚙️",
                color = Color.Blue
            )
            
            StatCard(
                title = "内存占用",
                value = (memoryProgress * 100).toInt(),
                targetValue = 100,
                icon = "💾",
                color = Color.Green
            )
            
            StatCard(
                title = "存储空间",
                value = 45,
                targetValue = 128,
                icon = "💿",
                color = Color.Magenta
            )
        }
    }
}
```

## Common Pitfalls Table

| 陷阱 | 表现 | 原因 | 解决方案 |
|------|------|------|----------|
| 忘记remember状态 | 重组后状态丢失 | Composable函数每次重组都会重新执行 | 使用remember { mutableStateOf(value) }保存状态 |
| Side Effect放在Composable顶层 | 无限重组循环 | 状态更新触发重组，重组又更新状态 | 将副作用放入LaunchedEffect、DisposableEffect等专用API |
| LazyColumn中item key缺失 | 滚动性能差和状态混乱 | Compose无法正确复用item | 为items提供key参数，如items(list, key = { it.id }) |
| Modifier顺序错误 | 点击区域或布局不符合预期 | Modifier按顺序应用，clickable应在padding之后 | 理解Modifier链式调用的顺序影响，通常padding在clickable之前 |
| 在Composable中进行耗时操作 | UI卡顿ANR | Composable应在主线程快速执行 | 将网络请求、文件IO等操作移到ViewModel或协程中 |
| 过度嵌套Column/Row | 性能下降 | 深层嵌套增加测量和布局成本 | 使用ConstraintLayout或Box简化布局层级 |
| 未处理Configuration Change | 屏幕旋转后状态丢失 | Activity重建导致状态重置 | 使用ViewModel保存状态，或使用rememberSaveable |
| Image加载未做缓存 | 内存溢出OOM | 大量图片直接加载到内存 | 使用Coil或Glide等图片加载库，启用内存和磁盘缓存 |
| Recomposition范围过大 | 不必要的性能开销 | 状态变化触发了过多组件重组 | 使用derivedStateOf优化计算，或将大Composable拆分为小组件 |
| 混淆StateFlow和mutableStateOf | 状态更新不触发UI刷新 | StateFlow需要在collectAsStateWithLifecycle中收集 | UI层使用mutableStateOf，数据层使用StateFlow，通过collectAsState桥接 |

## Self-Test Questions

### 问题1

在Jetpack Compose中，remember函数的主要作用是什么？

A. 在重组过程中保持状态不丢失  
B. 将数据保存到磁盘  
C. 记忆用户的操作历史  
D. 缓存网络请求结果  

**正确答案：A**

**详细解释：** remember是Compose中用于在重组（Recomposition）过程中保持状态的关键API。每次Composable函数重组时，函数体都会重新执行，如果没有remember，局部变量会被重新初始化。remember会将值存储在Composition中，确保即使重组发生，状态也能保持不变。通常与mutableStateOf配合使用：`val count = remember { mutableStateOf(0) }`。对于需要持久化的数据，应使用rememberSaveable或ViewModel。

### 问题2

关于Jetpack Compose的重组（Recomposition）机制，以下说法正确的是？

A. 每次状态变化都会重新创建整个UI树  
B. Compose会智能地只重组受影响的组件  
C. 重组等同于Activity的重建  
D. 重组会导致所有remember的状态丢失  

**正确答案：B**

**详细解释：** Compose的重组是智能且高效的。当状态发生变化时，Compose会通过快照系统追踪哪些Composable读取了该状态，然后只重组那些直接或间接依赖该状态的组件，而不是重建整个UI树。这种细粒度的重组机制是Compose高性能的关键。选项A错误，因为不是全量重建；选项C错误，重组是Composable级别的，不涉及Activity生命周期；选项D错误，remember的状态在重组中会保留。

### 问题3

在LazyColumn中使用items时，为什么要提供key参数？

A. 为了帮助Compose正确识别和复用列表项，提升性能  
B. 为了让列表项可以排序  
C. 为了加密列表数据  
D. 为了支持离线缓存  

**正确答案：A**

**详细解释：** 在LazyColumn中，key参数用于唯一标识每个列表项。当列表数据发生变化（添加、删除、移动）时，Compose使用key来追踪哪些项发生了变化，从而正确地复用现有的Composable实例，而不是重新创建所有项。这类似于RecyclerView中的ViewHolder机制。如果没有提供key，Compose会使用项的索引作为默认key，这在列表项顺序变化时会导致状态混乱和性能问题。最佳实践是使用数据的唯一ID作为key。

### 问题4

以下哪种方式最适合在Compose中执行网络请求等异步操作？

A. 直接在Composable函数中调用网络API  
B. 在remember块中执行网络请求  
C. 在ViewModel中使用协程，然后通过State暴露结果  
D. 在Modifier中发起网络请求  

**正确答案：C**

**详细解释：** Compose遵循单向数据流原则，UI层（Composable）应该尽量保持纯净，只负责展示和响应用户交互。网络请求、数据库操作等副作用应该在ViewModel中通过协程执行，然后将结果封装为State或StateFlow暴露给UI层。Composable通过collectAsStateWithLifecycle或collectAsState来观察这些数据变化。这样可以确保职责分离、易于测试，并且避免在重组过程中意外触发多次网络请求。

### 问题5

关于Compose的Modifier，以下说法错误的是？

A. Modifier是不可变的，每次调用都返回新实例  
B. Modifier的顺序会影响最终效果  
C. 可以使用then()方法链式组合多个Modifier  
D. Modifier可以直接修改Composable的内部状态  

**正确答案：D**

**详细解释：** Modifier是Compose中用于修饰组件外观和行为的不可变对象。每次调用Modifier的方法（如padding、background、clickable）都会返回一个新的Modifier实例，形成一条处理链。顺序确实很重要，例如`.padding(16.dp).background(Color.Red)`和`.background(Color.Red).padding(16.dp)`会产生不同的视觉效果。然而，Modifier不能直接修改Composable的内部状态，它只能影响组件的绘制、布局和输入处理。状态的修改需要通过状态管理API（如mutableStateOf）来完成。

---

**章节小结：**

恭喜！你已经掌握了Jetpack Compose的核心技能：声明式UI思维、智能重组机制、灵活的状态管理和强大的布局系统。Compose不仅简化了Android UI开发，更提供了一种现代化的编程范式。记住，Compose的精髓在于"描述而非命令"——告诉系统你想要什么界面，让它来处理如何实现。下一章我们将深入React Native的世界，探索如何用JavaScript构建真正的原生移动应用。

## 本节知识框架

**课程定位**：分类「android_development」· 学习阶段 进阶 · 建议用时 50 分钟。

本课主线：掌握Compose布局系统、副作用处理和Material Design 3组件。

### 复习清单

- [ ] 能不看正文复述本课核心术语，并指出一个边界或反例。
- [ ] 能运行或推演本课示例，记录输入、输出与失败现象。
- [ ] 能完成一次自测，并把错题对照考点精讲定位原因。

## 核心概念定义

| 术语 | 一句话说明 |
| --- | --- |
| Jetpack Compose | 掌握Compose布局系统、副作用处理和Material Design 3组件。相关：正文给出可操作定义与适用边界。 |
| Android | 掌握Compose布局系统、副作用处理和Material Design 3组件。相关：正文给出可操作定义与适用边界。 |
| 布局系统 | 掌握Compose布局系统、副作用处理和Material Design 3组件。相关：正文给出可操作定义与适用边界。 |
| 副作用 | 掌握Compose布局系统、副作用处理和Material Design 3组件。相关：正文给出可操作定义与适用边界。 |
| Material 3 | 掌握Compose布局系统、副作用处理和Material Design 3组件。相关：正文给出可操作定义与适用边界。 |

## 原理与运行机制

正文各章按「输入是什么 → 中间如何转换 → 输出到哪 → 失败时怎样表现」四问展开；复习时给每个机制补一句自己的复述，再回到对应章节核对。

## 典型应用场景

- 结合「Android Jetpack Compose进阶」的常见落地场景与选型边界，详见正文各章节的对比讨论。
- 迁移到新项目时，先明确输入规模、失败代价与可观测手段，再决定采用深度。

## 代码/协议/SQL 示例

正文首个示例可作为最小验证起点（原样保留在上方章节）：先跑通，再改一个输入观察输出变化。

```kotlin
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun Greeting(name: String) {
    Text(
        text = "Hello, $name!",
        style = MaterialTheme.typography.headlineMedium,
        modifier = Modifier.padding(16.dp)
    )
}
```

## 时间/空间复杂度或性能分析

- 用本课方案处理规模 n 时，先估计主循环与嵌套层数，再决定优化方向；小样本上的耗时读数不能外推。
- 性能结论要绑定输入分布：换数据规模、并发度或缓存命中情况后须重新测量。

## 常见误区与易错点

| 错误做法 | 典型现象 | 修复方向 |
| --- | --- | --- |
| 只验证正常输入 | 边界数据触发时才暴露问题 | 为每个结论补一个空值/极值/重复值用例 |
| 背结论不跑实验 | 换个输入就失效 | 按「预测—实测—差异归因」三步复盘 |
| 忽略环境与版本差异 | 本机可用线上报错 | 把版本、配置与依赖写入复现步骤 |

## 与其他知识点的关系

本课与分类「android_development」内相邻课程互为补充，建议按清单顺序学完再做综合练习。

## 自测题与参考答案

以下题目与题库同源，作答后再看解析；错误项要能说出错在哪一步。

## 考点精讲

### 考点 1

在Jetpack Compose中，remember函数的主要作用是什么？

A. 在重组过程中保持状态不丢失 ✅  
B. 将数据保存到磁盘  
C. 记忆用户的操作历史  
D. 缓存网络请求结果  

**正确答案：** A

**解析：** remember是Compose中用于在重组（Recomposition）过程中保持状态的关键API。每次Composable函数重组时，函数体都会重新执行，如果没有remember，局部变量会被重新初始化。remember会将值存储在Composition中，确保即使重组发生，状态也能保持不变。通常与mutableStateOf配合使用：`val count = remember { mutableStateOf(0) }`。对于需要持久化的数据，应使用rememberSaveable或ViewModel。

### 考点 2

关于Jetpack Compose的重组（Recomposition）机制，以下说法正确的是？

A. 每次状态变化都会重新创建整个UI树  
B. Compose会智能地只重组受影响的组件 ✅  
C. 重组等同于Activity的重建  
D. 重组会导致所有remember的状态丢失  

**正确答案：** B

**解析：** Compose的重组是智能且高效的。当状态发生变化时，Compose会通过快照系统追踪哪些Composable读取了该状态，然后只重组那些直接或间接依赖该状态的组件，而不是重建整个UI树。这种细粒度的重组机制是Compose高性能的关键。选项A错误，因为不是全量重建；选项C错误，重组是Composable级别的，不涉及Activity生命周期；选项D错误，remember的状态在重组中会保留。

### 考点 3

在LazyColumn中使用items时，为什么要提供key参数？

A. 为了帮助Compose正确识别和复用列表项，提升性能 ✅  
B. 为了让列表项可以排序  
C. 为了加密列表数据  
D. 为了支持离线缓存  

**正确答案：** A

**解析：** 在LazyColumn中，key参数用于唯一标识每个列表项。当列表数据发生变化（添加、删除、移动）时，Compose使用key来追踪哪些项发生了变化，从而正确地复用现有的Composable实例，而不是重新创建所有项。这类似于RecyclerView中的ViewHolder机制。如果没有提供key，Compose会使用项的索引作为默认key，这在列表项顺序变化时会导致状态混乱和性能问题。最佳实践是使用数据的唯一ID作为key。

### 考点 4

以下哪种方式最适合在Compose中执行网络请求等异步操作？

A. 直接在Composable函数中调用网络API  
B. 在remember块中执行网络请求  
C. 在ViewModel中使用协程，然后通过State暴露结果 ✅  
D. 在Modifier中发起网络请求  

**正确答案：** C

**解析：** Compose遵循单向数据流原则，UI层（Composable）应该尽量保持纯净，只负责展示和响应用户交互。网络请求、数据库操作等副作用应该在ViewModel中通过协程执行，然后将结果封装为State或StateFlow暴露给UI层。Composable通过collectAsStateWithLifecycle或collectAsState来观察这些数据变化。这样可以确保职责分离、易于测试，并且避免在重组过程中意外触发多次网络请求。

### 考点 5

关于Compose的Modifier，以下说法错误的是？

A. Modifier是不可变的，每次调用都返回新实例  
B. Modifier的顺序会影响最终效果  
C. 可以使用then()方法链式组合多个Modifier  
D. Modifier可以直接修改Composable的内部状态 ✅  

**正确答案：** D

**解析：** Modifier是Compose中用于修饰组件外观和行为的不可变对象。每次调用Modifier的方法（如padding、background、clickable）都会返回一个新的Modifier实例，形成一条处理链。顺序确实很重要，例如`.padding(16.dp).background(Color.Red)`和`.background(Color.Red).padding(16.dp)`会产生不同的视觉效果。然而，Modifier不能直接修改Composable的内部状态，它只能影响组件的绘制、布局和输入处理。状态的修改需要通过状态管理API（如mutableStateOf）来完成。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| Jetpack Compose | 定位线索见正文小节；速查表只保留名称，避免脱离上下文使用。 |
| Android | 定位线索见正文小节；速查表只保留名称，避免脱离上下文使用。 |
| 布局系统 | 定位线索见正文小节；速查表只保留名称，避免脱离上下文使用。 |
| 副作用 | 定位线索见正文小节；速查表只保留名称，避免脱离上下文使用。 |
| Material 3 | 定位线索见正文小节；速查表只保留名称，避免脱离上下文使用。 |

## 参考资料与复核

- [本课资料锚点 mobile_jetpack_compose_advanced](https://zh.wikipedia.org/w/index.php?search=mobile_jetpack_compose_advanced)

- 官方/权威资料：[Android 开发者站](https://developer.android.com/develop)
- 主题延伸：[关于「Android」的检索页](https://zh.wikipedia.org/w/index.php?search=Android)
- 本课索引词：[锚点 mobile_jetpack_compose_advanced](https://developer.android.com/develop#Jetpack%20Compose)
- 最后复核：2026-10-04
- 下次复核：2027-01-08

## 内容元数据

- 内容更新时间：2026-10-06

- 内容版本：v2.0
- 课程标识：mobile_jetpack_compose_advanced
- 所属分类：android_development
- 学习阶段：进阶
- 建议用时：50 分钟

