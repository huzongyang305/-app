# React Native 跨平台开发

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：45 分钟

![React Native 新架构与性能优化](images/diagram_mobile_react_native.webp)

![React Native 跨平台开发](images/category_mobile_react_native.webp)

## 本节知识框架

**课程定位**：所属分类为「移动开发」，课程主题为「React Native 跨平台开发」，学习阶段为「进阶」，建议用时 45 分钟。

**本课要解决的主问题**：新架构 JSI/Fabric/Hermes、列表虚拟化与桥接性能优化。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「React Native 跨平台开发」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「React Native 跨平台开发」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「React Native」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《Swift 与 iOS 开发》

**学习位置**：本课位于《小程序开发要点》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《Jetpack Compose 声明式 UI》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释React Native 跨平台开发解决了什么问题，而不是只背术语。
- 能说清 「React Native」、「跨平台」、「Hermes」、「Fabric」 之间的关系，并分别举出一个例子。
- 能把 React Native 放回「React Native 跨平台开发」的知识体系，说明它和 跨平台 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：新架构 JSI/Fabric/Hermes、列表虚拟化与桥接性能优化。

**教材衔接：前置知识**

- 先完成上一课《Swift 与 iOS 开发》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先完成「Swift 与 iOS 开发」，或确认自己能独立跑通正文里的 ItemSeparatorComponent 示例。
- 开始前先复习：React Native、跨平台、Hermes。
- 卡在 React Native 上时不要跳过：把输入、预期和实际输出写成三行，再回头读正文。

**教材衔接：本课小结**

- 核心问题：React Native 跨平台开发不是孤立术语，而是在「移动开发」中解决一类具体问题。
- 关键关系：先分清「React Native」与「跨平台」的职责，再理解「Hermes」的适用边界。
- 判断标准：能举出 跨平台 的一个反例并解释原因。
- 下一步：把 ItemSeparatorComponent 的实验结论记成三句话，然后进入测验。

## 核心概念定义

> 阅读约定：本课先给「React Native 跨平台开发」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| Hooks | React 函数组件里管理状态与副作用的 API（useState、useEffect 等），依赖数组写错是常见 bug 来源。 | 仅在「React Native 跨平台开发」明确给出的输入、版本与资源条件下成立。 |
| 原生模块 | 用平台原生代码封装能力并暴露给 JavaScript 调用，用来抹平权限、组件与 API 差异。 | 仅在「React Native 跨平台开发」明确给出的输入、版本与资源条件下成立。 |
| 桥接 | JavaScript 与原生之间传递调用与数据的通道，跨线程通信是性能开销的主要来源。 | 仅在「React Native 跨平台开发」明确给出的输入、版本与资源条件下成立。 |
| 平台差异 | iOS 与 Android 在组件、权限、手势上的不一致，需要用 Platform 判断或平台后缀文件分别处理。 | 仅在「React Native 跨平台开发」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「React Native 跨平台开发」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「Hooks」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「原生模块」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「桥接」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「React Native 跨平台开发」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | Hooks | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | 原生模块 | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | 桥接 | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「React Native 跨平台开发」自己的示例验证。「React Native 跨平台开发」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：定位与原理**

React Native（RN）用 JavaScript/TypeScript 写业务，通过桥接调用原生组件渲染真实原生控件，而不是 WebView。它的价值是「一套业务代码 + 两种原生体验」，代价是需要理解 JS 线程与原生线程的通信边界。

| 方案 | 渲染方式 | 性能 | 生态 |
| --- | --- | --- | --- |
| React Native | 原生组件 | 接近原生 | JS 生态庞大 |
| Flutter | 自绘引擎 | 稳定高帧率 | Dart 生态 |
| WebView 混合 | 网页 | 较差 | 前端复用 |
| 原生开发 | 平台控件 | 最好 | 两套代码 |

**教材衔接：架构速查（新架构）**

| 组成 | 作用 |
| --- | --- |
| JSI | 让 JS 直接调用 C++ 层，替代异步桥接 |
| Fabric | 新渲染器，支持同步布局与并发渲染 |
| TurboModules | 按需加载原生模块 |
| Hermes | 默认 JS 引擎，启动更快、内存更低 |
| Codegen | 由类型定义生成桥接代码 |

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 React Native、跨平台 | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「React Native 跨平台开发」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「React Native 跨平台开发」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《React Native 跨平台开发》原文中的最小示例。先预测《React Native 跨平台开发》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```tsx
import React from "react";
import { FlatList, Pressable, StyleSheet, Text, View } from "react-native";

type Lesson = { id: string; title: string; minutes: number };

export function LessonList({ lessons }: { lessons: Lesson[] }) {
  return (
    <FlatList
      data={lessons}
      keyExtractor={(item) => item.id}
      // 只渲染可见行，避免一次性创建全部子组件
      initialNumToRender={8}
      windowSize={5}
      removeClippedSubviews
      ItemSeparatorComponent={() => <View style={styles.gap} />}
      renderItem={({ item }) => (
        <Pressable
          style={({ pressed }) => [styles.card, pressed && styles.cardPressed]}
          onPress={() => undefined}
        >
          <Text style={styles.title} numberOfLines={1}>
            {item.title}
          </Text>
          <Text style={styles.meta}>{item.minutes} 分钟</Text>
        </Pressable>
      )}
    />
  );
}

const styles = StyleSheet.create({
  card: { padding: 16, borderRadius: 8, backgroundColor: "#fff" },
  cardPressed: { opacity: 0.7 },
  title: { fontSize: 16, fontWeight: "600" },
  meta: { marginTop: 4, color: "#64748b" },
  gap: { height: 8 },
});
```

**教材衔接：常用组件与 API**

| 需求 | 写法 |
| --- | --- |
| 基础容器 | `View`、`ScrollView`、`SafeAreaView` |
| 文本 | `Text`、`TextInput` |
| 列表 | `FlatList`（大数据）、`SectionList` |
| 图片 | `Image`（需显式宽高或 `aspectRatio`） |
| 触摸 | `Pressable`、`TouchableOpacity` |
| 样式 | `StyleSheet.create`，单位是无量纲的 dp |
| 平台差异 | `Platform.select({ ios: ..., android: ... })` |
| 存储 | `AsyncStorage` / MMKV |
| 导航 | React Navigation |

```tsx
import React from "react";
import { FlatList, Pressable, StyleSheet, Text, View } from "react-native";

type Lesson = { id: string; title: string; minutes: number };

export function LessonList({ lessons }: { lessons: Lesson[] }) {
  return (
    <FlatList
      data={lessons}
      keyExtractor={(item) => item.id}
      // 只渲染可见行，避免一次性创建全部子组件
      initialNumToRender={8}
      windowSize={5}
      removeClippedSubviews
      ItemSeparatorComponent={() => <View style={styles.gap} />}
      renderItem={({ item }) => (
        <Pressable
          style={({ pressed }) => [styles.card, pressed && styles.cardPressed]}
          onPress={() => undefined}
        >
          <Text style={styles.title} numberOfLines={1}>
            {item.title}
          </Text>
          <Text style={styles.meta}>{item.minutes} 分钟</Text>
        </Pressable>
      )}
    />
  );
}

const styles = StyleSheet.create({
  card: { padding: 16, borderRadius: 8, backgroundColor: "#fff" },
  cardPressed: { opacity: 0.7 },
  title: { fontSize: 16, fontWeight: "600" },
  meta: { marginTop: 4, color: "#64748b" },
  gap: { height: 8 },
});
```

**教材衔接：零基础详解：React Native 跨平台开发**

### 一句话说清它是什么

React Native 用 JavaScript/TypeScript 写界面，再通过「桥」或 JSI 调用原生控件渲染。
它的核心心智是：**UI 是状态的函数，改状态就自动重建界面**。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 组件 | 积木 | 可复用的界面单元 |
| props | 传入的参数 | 只读，父传子 |
| state | 组件自己的记忆 | 改了就重建 |
| Hooks | 给函数组件装能力 | 状态、副作用、缓存 |
| 桥 / JSI | 翻译通道 | JS 与原生互相调用 |

### 用 Hooks 写一个页面

```tsx
import { useCallback, useEffect, useState } from "react";
import { ActivityIndicator, FlatList, Pressable, Text, View } from "react-native";

type Item = { id: string; title: string };

export function ItemListScreen() {
  const [items, setItems] = useState<Item[]>([]);
  const [status, setStatus] = useState<"loading" | "ready" | "error">("loading");

  const load = useCallback(async () => {
    setStatus("loading");
    try {
      const res = await fetch("https://example.com/api/items");
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      setItems(await res.json());
      setStatus("ready");
    } catch {
      setStatus("error");
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  if (status === "loading") return <ActivityIndicator />;
  if (status === "error") {
    return (
      <View>
        <Text>加载失败</Text>
        <Pressable onPress={load}><Text>重试</Text></Pressable>
      </View>
    );
  }
  if (items.length === 0) return <Text>暂无数据</Text>;

  return (
    <FlatList
      data={items}
      keyExtractor={(item) => item.id}
      renderItem={({ item }) => <Text>{item.title}</Text>}
    />
  );
}
```

**关键点**：长列表必须用 `FlatList` 或 `FlashList`，`ScrollView` 会一次性渲染全部子项。

### 四个最容易出 bug 的 Hooks 用法

| 问题 | 现象 | 正确做法 |
| --- | --- | --- |
| `useEffect` 缺依赖 | 用到旧值 | 把依赖写全，或用函数式更新 |
| 每次渲染新建函数 | 子组件无谓重建 | 用 `useCallback` |
| 每次渲染新建对象 | `memo` 失效 | 用 `useMemo` |
| 组件卸载后 setState | 警告或异常 | 用标志位或取消请求 |

```tsx
// 依赖数组写全的正确姿势
useEffect(() => {
  const controller = new AbortController();
  void (async () => {
    try {
      const res = await fetch(url, { signal: controller.signal });
      setData(await res.json());
    } catch (error) {
      if ((error as Error).name !== "AbortError") setError("加载失败");
    }
  })();
  return () => controller.abort();      // 清理函数：组件卸载时取消
}, [url]);
```

### 平台差异与原生能力

```tsx
import { Platform, StyleSheet } from "react-native";

const styles = StyleSheet.create({
  card: {
    padding: 16,
    shadowOpacity: Platform.OS === "ios" ? 0.1 : 0,
    elevation: Platform.OS === "android" ? 2 : 0,
  },
});

// 分平台文件：Button.ios.tsx 与 Button.android.tsx 会被自动选用
```

| 需求 | 方式 |
| --- | --- |
| 平台差异样式 | `Platform.OS` 或分平台文件 |
| 需要原生能力 | 社区库或自己写 Native Module |
| 频繁通信的性能问题 | 用 JSI 或新架构 Fabric |
| 本地存储 | AsyncStorage、MMKV |
| 导航 | React Navigation |

### 性能四原则

```tsx
// 1. 长列表用虚拟化并给出稳定 key
<FlatList keyExtractor={(i) => i.id} ... />

// 2. 列表项用 memo 包裹，避免整表重建
const Row = memo(function Row({ item }: { item: Item }) {
  return <Text>{item.title}</Text>;
});

// 3. 回调与对象用 useCallback / useMemo 稳定引用
const renderItem = useCallback(({ item }: { item: Item }) => <Row item={item} />, []);

// 4. 图片给定尺寸，避免布局跳动
<Image source={{ uri }} style={{ width: 64, height: 64 }} />
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 用 ScrollView 渲染长列表 | 内存暴涨、卡顿 | 用 FlatList |
| `useEffect` 依赖不全 | 数据不更新 | 补全依赖 |
| 卸载后 setState | 警告与异常 | 清理函数里取消 |
| 内联对象传子组件 | memo 失效 | 用 useMemo |
| 图片不给尺寸 | 布局跳动 | 固定宽高或比例 |
| 在主线程做重计算 | 掉帧 | 拆分或移到原生 |
| 直接改 state 数组 | 界面不刷新 | 返回新数组 |
| 忽略安全区 | 内容被遮挡 | 用 `SafeAreaView` |

### 学完自测

- [ ] 能说出 props 与 state 的区别。
- [ ] 知道 `useEffect` 的清理函数有什么用。
- [ ] 能说出长列表为什么必须虚拟化。
- [ ] 知道 `useCallback` 与 `useMemo` 各自稳定什么。
- [ ] 能说出至少两种处理平台差异的方式。

## 时间/空间复杂度或性能分析

**复杂度证据**：「React Native 跨平台开发」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「React Native 跨平台开发」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「React Native 跨平台开发」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

**教材衔接：性能要点速查**

| 问题 | 手段 |
| --- | --- |
| 长列表卡顿 | `FlatList` 虚拟化 + `keyExtractor` + `getItemLayout` |
| 频繁重渲染 | `React.memo`、`useCallback`、`useMemo` |
| 启动慢 | 开启 Hermes、减少启动期初始化、延迟加载模块 |
| 桥接开销 | 合并调用、避免每帧跨桥传输大数据 |
| 图片内存 | 按需缩放、使用缓存库、及时释放 |
| 动画掉帧 | 用 `Animated`/`Reanimated` 走原生线程，避免 JS 逐帧改样式 |

## 常见误区与易错点

> 复核《React Native 跨平台开发》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「React Native 跨平台开发」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用 `ScrollView` 渲染长列表 | 内存暴涨、卡顿 | 改用 `FlatList` 虚拟化 |
| 内联箭头函数当 `renderItem` | 每次渲染都新建函数与组件 | 提到组件外或用 `useCallback` |
| 图片不设宽高 | 布局错乱或空白 | 显式设置尺寸或 `aspectRatio` |
| 在 JS 线程做重计算 | 动画与交互卡顿 | 移到原生模块或 Worker |
| 直接用 `console.log` 排查线上问题 | 性能下降、无日志留存 | 用日志库并按级别控制 |
| 把原生差异写死在业务里 | 维护成本高 | 抽平台适配层 |
| 忽略返回键与安全区域 | Android 与刘海屏体验异常 | 处理 `BackHandler` 与安全区 |

**教材衔接：故障现场**

### 现场 1：用 ScrollView 渲染长列表

**症状**：在《React Native 跨平台开发》的复现场景中，内存暴涨、卡顿。

**根因**：“内存暴涨、卡顿”只是表层结果。向上追溯会落到“用 ScrollView 渲染长列表”这一步，因为它省略了《React Native 跨平台开发》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《React Native 跨平台开发》的问题，改用 FlatList 虚拟化。

**验证**：保留《React Native 跨平台开发》里触发“内存暴涨、卡顿”的输入、版本和日志，按“改用 FlatList 虚拟化”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 2：内联箭头函数当 renderItem

**症状**：在《React Native 跨平台开发》的复现场景中，每次渲染都新建函数与组件。

**根因**：“每次渲染都新建函数与组件”只是表层结果。向上追溯会落到“内联箭头函数当 renderItem”这一步，因为它省略了《React Native 跨平台开发》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《React Native 跨平台开发》的问题，提到组件外或用 useCallback。

**验证**：保留《React Native 跨平台开发》里触发“每次渲染都新建函数与组件”的输入、版本和日志，按“提到组件外或用 useCallback”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 3：图片不设宽高

**症状**：在《React Native 跨平台开发》的复现场景中，布局错乱或空白。

**根因**：当出现“图片不设宽高”时，执行路径已经绕过了《React Native 跨平台开发》的关键约束，最终以“布局错乱或空白”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《React Native 跨平台开发》的问题，显式设置尺寸或 aspectRatio。

**验证**：在《React Native 跨平台开发》中按“显式设置尺寸或 aspectRatio”调整后，从“图片不设宽高”的触发条件重放同一条路径，确认“布局错乱或空白”不再出现，并补一个相邻边界用例检查没有引入新问题。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《Swift 与 iOS 开发》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《Jetpack Compose 声明式 UI》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《小程序开发要点》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《Jetpack Compose 声明式 UI》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「React Native 跨平台开发」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《React Native 跨平台开发》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

按“React Native 跨平台开发”中 React Native、跨平台、Hermes 的实践顺序，把四个步骤排成从准备到复盘的合理顺序。

A. 固定版本与证据，把“React Native 跨平台开发”的结论写成可复现记录
B. 先明确 React Native 的输入、输出与约束
C. 写出最小示例并核对 跨平台 的基线结果
D. 只改一个变量，记录边界与失败路径的变化

**参考答案**：先明确 React Native 的输入、输出与约束 → 写出最小示例并核对 跨平台 的基线结果 → 只改一个变量，记录边界与失败路径的变化 → 固定版本与证据，把“React Native 跨平台开发”的结论写成可复现记录

**解析**：题干的正确项是固定版本与证据，把“React Native 跨平台开发”的结论写成可复现记录。在「React Native 跨平台开发」里，在本课的练习里，顺序应当是：先明确 React Native 的输入、输出与约束 → 写出最小示例并核对 跨平台 的基线结果 → 只改一个变量，记录边界与失败路径的变化 → 固定版本与证据，把本课的结论写成可复现记录。这个顺序把 React Native 的输入、输出和约束放在最前面，在React Native 跨平台开发里避免概念没对齐就开始调参。第二步用 跨平台 建立可核对的基线，在React Native 跨平台开发里第三步才允许改变一个变量并观察失败路径。

### 自测 2

围绕“React Native 跨平台开发”中的 React Native、跨平台、Hermes，下列哪两项是本课强调的实践判断？

A. 验证 跨平台 时要固定版本并覆盖边界输入，结论才可复现
B. 把 跨平台 的单次运行结果当成所有版本和规模都成立
C. 学习 React Native 时要同时说明输入、输出和失败路径，不能只看正常流程
D. 只要 React Native 的常规示例通过，就可以跳过边界与异常路径

**参考答案**：验证 跨平台 时要固定版本并覆盖边界输入，结论才可复现；学习 React Native 时要同时说明输入、输出和失败路径，不能只看正常流程

**解析**：本课把React Native 跨平台开发拆成概念、示例与故障现场三部分，因此判断 React Native 时必须同时交代输入、输出和失败路径，这使“学习 React Native 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在React Native 跨平台开发里，判断 跨平台 时要固定版本与边界输入，所以“验证 跨平台 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 自测 3

Hermes 引擎带来的主要收益是？

A. 提升启动速度并降低内存占用
B. 取代原生模块
C. 让 JavaScript 支持多线程
D. 提升图片解码速度

**参考答案**：提升启动速度并降低内存占用

**解析**：在「React Native 跨平台开发」里，提升启动速度并降低内存占用。Hermes 为移动端优化，通过预编译字节码减少启动解析时间并降低内存，是 RN 默认引擎。把“提升启动速度并降低内存占用”代回「React Native 跨平台开发」里“Hermes 引擎带来的主要收益是”的例子核对，条件一旦改变，结论就要用React Native、跨平台、Hermes重新推导。

**教材衔接：复习与自测**

- [ ] 能说清 RN 与 Flutter、原生、WebView 的取舍。
- [ ] 知道 JSI、Fabric、TurboModules、Hermes 各自解决什么。
- [ ] 长列表使用虚拟化并提供 `keyExtractor`。
- [ ] 用 `React.memo` 与 hooks 控制重渲染范围。
- [ ] 动画走原生线程，避免 JS 逐帧驱动。

**教材衔接：动手练习**

> 本课练习重点：围绕「React Native、跨平台、Hermes」完成复述、实验和交付，每个结果都要能被别人检查。

把 ItemSeparatorComponent 的布局放进窄屏与深色模式各检查一次。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. React Native 跨平台开发解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「跨平台」是什么关系？

验收标准：说明 React Native 与 跨平台 的分工，并写出一个失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：把 ItemSeparatorComponent 当作原例，改动一次跨平台的取值，记录命令、输出与差异原因；五步里缺任意一步都算未完成。

### 练习 3：交付一个小结果（30 分钟）

创建一个最小 Widget 展示 React Native，分别验证正常、空数据和超长文本三种状态。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「React Native」和「跨平台」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

本节围绕React Native 跨平台开发安排 3 个可交付任务，每个任务都要求留下可以复查的记录。

### 任务 1：用自己的话画出结构

不看书，用一张图说清「React Native 跨平台开发」的结构，画完再对照骨架：

- 主干：定位与原理 → 架构速查（新架构） → 常用组件与 API → 性能要点速查
- 连接线：在每条边上标出输入、输出与失败路径。
- 自检：能否用一句话说明React Native与跨平台的关系？

### 任务 2：做一次对比实验

**验收标准**：对照表两列都要有证据（命令、输出或数据），并注明React Native与跨平台哪一个才是决定性变量。

### 任务 3：迁移到自己的场景

**验收标准**：至少给出一个命令或数据样例，让读者能独立复现 跨平台 的结论。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「React Native 与 WebView 混合方案的关键区别是？」的判断依据。
- [ ] 不看解析，能说出「列表数据量大时应该使用哪个组件？」的判断依据。
- [ ] 不看解析，能说出「Hermes 引擎带来的主要收益是？」的判断依据。
- [ ] 不看解析，能说出「关于 RN 中的动画性能，正确做法是？」的判断依据。
- [ ] 不看解析，能说出「图片在 RN 布局中不设置宽高会出现什么？」的判断依据。
- [ ] 跑通「React Native 跨平台开发」的最小示例，并记录一次失败输入的处理方式。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

---

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `Hooks` | React 函数组件里管理状态与副作用的 API（useState、useEffect 等），依赖数组写错是常见 bug 来源。 |
| `原生模块` | 用平台原生代码封装能力并暴露给 JavaScript 调用，用来抹平权限、组件与 API 差异。 |
| `桥接` | JavaScript 与原生之间传递调用与数据的通道，跨线程通信是性能开销的主要来源。 |
| `平台差异` | iOS 与 Android 在组件、权限、手势上的不一致，需要用 Platform 判断或平台后缀文件分别处理。 |

## 考点精讲

### 考点 1：顺序排列·React Native

- **题目**：按“React Native 跨平台开发”中 React Native、跨平台、Hermes 的实践顺序，把四个步骤排成从准备到复盘的合理顺序。
- **判断依据**：题干的正确项是固定版本与证据，把“React Native 跨平台开发”的结论写成可复现记录。在「React Native 跨平台开发」里，在本课的练习里，顺序应当是：先明确 React Native 的输入、输出与约束 → 写出最小示例并核对 跨平台 的基线结果 → 只改一个变量，记录边界与失败路径的变化 → 固定版本与证据，把本课的结论写成可复现记录。这个顺序把 React Native 的输入、输出和约束放在最前面，在React Native 跨平台开发里避免概念没对齐就开始调参。第二步用 跨平台 建立可核对的基线，在React Native 跨平台开发里第三步才允许改变一个变量并观察失败路径。

### 考点 2：多选辨析·React Native

- **题目**：围绕“React Native 跨平台开发”中的 React Native、跨平台、Hermes，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把React Native 跨平台开发拆成概念、示例与故障现场三部分，因此判断 React Native 时必须同时交代输入、输出和失败路径，这使“学习 React Native 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在React Native 跨平台开发里，判断 跨平台 时要固定版本与边界输入，所以“验证 跨平台 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 3：概念判断·React Native

- **题目**：Hermes 引擎带来的主要收益是？
- **判断依据**：在「React Native 跨平台开发」里，提升启动速度并降低内存占用。Hermes 为移动端优化，通过预编译字节码减少启动解析时间并降低内存，是 RN 默认引擎。把“提升启动速度并降低内存占用”代回「React Native 跨平台开发」里“Hermes 引擎带来的主要收益是”的例子核对，条件一旦改变，结论就要用React Native、跨平台、Hermes重新推导。

### 考点 4：概念判断·React Native

- **题目**：关于 RN 中的动画性能，正确做法是？
- **判断依据**：在「React Native 跨平台开发」里，结论应落在「用 Animated 或 Reanimated 让动画在原生线程执行」。动画在原生线程执行可以绕开 JS 线程繁忙导致的掉帧，这是 RN 动画的主流做法。这道题的关键在「React Native 跨平台开发」的React Native、跨平台、Hermes：先确认题干“关于 RN 中的动画性能”问的是哪一步，再排除偷换前提的选项。

### 考点 5：概念判断·React Native

- **题目**：图片在 RN 布局中不设置宽高会出现什么？
- **判断依据**：在「React Native 跨平台开发」里，可能不显示或导致布局异常。RN 的 Image 没有像浏览器那样的固有尺寸，必须显式给出宽高或 aspectRatio，否则可能渲染不出或造成布局跳动。回到「React Native 跨平台开发」的正文示例，用“图片在 RN 布局中不设置宽高会出现”走一遍React Native、跨平台、Hermes的完整流程，能复现的结论才可以保留。

### 考点 6：排错·React Native

- **题目**：阅读「React Native 跨平台开发」的代码片段，下面哪项判断是正确的？
- **判断依据**：在「React Native 跨平台开发」里，RN 通过桥接渲染真实原生组件，不是网页。这道题的关键在「React Native 跨平台开发」的React Native、跨平台、Hermes：先确认题干“阅读React Native 跨平台”问的是哪一步，再排除偷换前提的选项。

## English Overview

**Title:** React Native

**Summary:** JSI, Fabric, Hermes and list virtualization.

**Category:** Mobile Development
**Level:** 进阶
**Key terms:** React Native, 跨平台, Hermes, Fabric, FlatList

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Flutter 3.x / Dart 3.x
；本课聚焦 React Native。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：React Native、跨平台、Hermes、Fabric、FlatList
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-08-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Flutter 性能最佳实践](https://docs.flutter.dev/perf/best-practices) | 帧率、构建与内存优化 |
| [Dart 异步编程](https://dart.dev/libraries/async/async-await) | Future、Stream 与事件循环 |
| [Flutter 状态管理](https://docs.flutter.dev/data-and-backend/state-mgmt/intro) | 状态分层与重建范围 |

> 「React Native 跨平台开发」的链接用于离线阅读后的延伸核对；App 不会自动联网。
