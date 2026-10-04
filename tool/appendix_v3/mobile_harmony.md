## 零基础详解：鸿蒙 ArkTS 与 ArkUI

### 一句话说清它是什么

鸿蒙应用用 **ArkTS**（TypeScript 的超集）编写，界面用 **ArkUI 声明式语法**描述。
心智与 Compose、SwiftUI 一致：**状态驱动界面**，改状态就自动刷新。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| ArkTS | 带类型的安全版 TS | 语法近似 TypeScript |
| ArkUI | 声明式画布 | 用代码描述界面 |
| 装饰器 | 贴标签 | `@State`、`@Prop` 标明数据角色 |
| Ability | 应用的一个能力入口 | UIAbility 对应一个界面容器 |
| 页面路由 | 导航员 | 页面之间跳转与传参 |

### 一个页面的基本结构

```typescript
@Entry
@Component
struct CounterPage {
  @State count: number = 0;

  build() {
    Column({ space: 12 }) {
      Text(`计数：${this.count}`)
        .fontSize(20)
        .fontWeight(FontWeight.Medium)

      Button('加一')
        .onClick(() => { this.count += 1; })
        .width('60%')
    }
    .padding(16)
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

| 关键点 | 说明 |
| --- | --- |
| `@Entry` | 标记为页面入口 |
| `@Component` | 标记为可复用组件 |
| `build()` | 描述界面结构 |
| `@State` | 组件内部状态，变化触发刷新 |

### 五个常用状态装饰器

| 装饰器 | 作用 | 数据流向 |
| --- | --- | --- |
| `@State` | 组件自己的状态 | 组件内部 |
| `@Prop` | 父传子的单向数据 | 父 → 子 |
| `@Link` | 与父组件双向同步 | 双向 |
| `@Provide` / `@Consume` | 跨层共享 | 祖先 → 后代 |
| `@Observed` / `@ObjectLink` | 观察对象内部变化 | 对象属性级 |

```typescript
@Component
struct Child {
  @Prop title: string;              // 只读，父组件传入
  @Link count: number;              // 双向，可直接改

  build() {
    Row({ space: 8 }) {
      Text(this.title)
      Button('+1').onClick(() => { this.count += 1; })
    }
  }
}
```

**要点**：`@State` 只能观察第一层变化；对象内部属性变化要用 `@Observed` 与 `@ObjectLink`。

### 页面跳转与传参

```typescript
import { router } from '@kit.ArkUI';

// 跳转并传参
router.pushUrl({
  url: 'pages/DetailPage',
  params: { id: 42, title: '订单详情' },
});

// 目标页面接收
const params = router.getParams() as Record<string, Object>;
const id = params?.id as number;

// 返回
router.back();
```

更推荐用 **Navigation 组件**管理多级页面与返回栈，能力比 `router` 更完整。

### 应用模型：Stage 模型

```text
entry/                      应用入口模块（HAP）
  src/main/ets/
    entryability/           UIAbility：界面入口与生命周期
    pages/                  页面
    components/             可复用组件
    model/                  数据模型
    viewmodel/              状态与业务编排
  resources/                字符串、图片、颜色
```

| 目录 | 职责 |
| --- | --- |
| `entryability` | 应用启动、前台后台切换 |
| `pages` | 页面级组件 |
| `components` | 通用组件 |
| `viewmodel` | 状态与数据编排 |

**资源统一放 `resources`**：多语言与深色模式都靠它切换，不要在代码里写死文案。

### 生命周期要处理的四件事

```typescript
export default class EntryAbility extends UIAbility {
  onCreate() { /* 初始化资源 */ }
  onWindowStageCreate(windowStage: window.WindowStage) {
    windowStage.loadContent('pages/Index');    // 加载首页
  }
  onForeground() { /* 恢复刷新 */ }
  onBackground() { /* 暂停轮询、保存草稿 */ }
}
```

| 时机 | 该做什么 |
| --- | --- |
| `onCreate` | 初始化全局资源 |
| `onWindowStageCreate` | 加载首页 |
| `onForeground` | 恢复定时器与刷新 |
| `onBackground` | 暂停任务、保存状态 |
| `onDestroy` | 释放资源 |

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 用普通变量存状态 | 界面不刷新 | 用 `@State` |
| 修改对象内部属性 | 界面不更新 | 用 `@Observed` 与 `@ObjectLink` |
| 文案写死在代码里 | 无法多语言 | 放 `resources` |
| 忽略 `onBackground` | 后台仍在轮询耗电 | 暂停任务 |
| 列表项缺 key | 刷新后状态错位 | 提供稳定 key |
| 把业务写在 `build()` 里 | 重复执行 | 放生命周期或 ViewModel |
| 不处理权限申请 | 功能静默失败 | 运行时申请并处理拒绝 |
| 忘记适配深色模式 | 界面刺眼 | 用资源颜色变量 |

### 学完自测

- [ ] 能说出 `@State`、`@Prop`、`@Link` 的差别。
- [ ] 知道对象内部属性变化要用什么装饰器。
- [ ] 能说出 Stage 模型里 `entryability` 的职责。
- [ ] 知道为什么文案要放 `resources`。
- [ ] 能说出 `onBackground` 里应该做什么。
