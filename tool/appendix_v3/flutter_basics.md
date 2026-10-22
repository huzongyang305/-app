## 零基础详解：Widget、约束与布局

### 一句话说清它是什么

Flutter 里「一切皆 Widget」。理解布局只需记住三条：
**约束向下传递、尺寸向上汇报、父节点决定子节点位置**。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| Widget | 图纸 | 描述界面长什么样，本身不可变 |
| Element | 现场施工记录 | 连接 Widget 与真实渲染对象 |
| RenderObject | 实际建筑 | 负责测量、布局与绘制 |
| 约束 | 房间尺寸限制 | 父节点告诉子节点可用空间 |
| setState | 重新装修 | 标记需要重建的部分 |

### 三条布局规则

```text
1. 约束向下：父节点给出 minWidth/maxWidth/minHeight/maxHeight
2. 尺寸向上：子节点在约束内决定自己的大小并汇报
3. 父定位置：父节点决定把子节点放在哪
```

**看到 `RenderFlex overflowed` 就是子节点要的空间超过了父节点给的约束。**

### 最常用的五个布局组件

| 组件 | 作用 | 典型场景 |
| --- | --- | --- |
| `Row` / `Column` | 一维排列 | 横向或纵向组合 |
| `Expanded` / `Flexible` | 按比例分配剩余空间 | 让某个子项撑满 |
| `Stack` | 层叠定位 | 角标、悬浮按钮 |
| `ListView.builder` | 懒加载列表 | 长列表 |
| `Padding` / `SizedBox` | 留白与固定尺寸 | 间距控制 |

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Text('标题', style: TextStyle(fontSize: 20)),
    const SizedBox(height: 8),                 // 用 SizedBox 控制间距
    Row(
      children: [
        const Icon(Icons.person),
        const SizedBox(width: 8),
        Expanded(                              // 占满剩余宽度
          child: Text(
            '很长的说明文字会自动换行，不会溢出',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  ],
)
```

### 长列表一定用 builder

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    final item = items[index];
    return ListTile(
      title: Text(item.title),
      subtitle: Text(item.subtitle),
      onTap: () => _open(context, item),
    );
  },
)
```

**不要用 `SingleChildScrollView` + `Column` 渲染几百条数据**，那样会一次性构建全部子项。

### 四类常见溢出与修法

| 报错 | 原因 | 修法 |
| --- | --- | --- |
| 横向溢出 | Row 内子项太宽 | 用 `Expanded` 或 `Flexible` 包住 |
| 纵向溢出 | Column 高度不够 | 用 `SingleChildScrollView` 或 `ListView` |
| 文本溢出 | 文字太长 | `maxLines` 加 `TextOverflow.ellipsis` |
| 无限高度约束 | ListView 套在 Column 里 | 给 `shrinkWrap` 或加 `Expanded` |

### 状态与重建

```dart
class Counter extends StatefulWidget {
  const Counter({super.key});

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('计数：$_count'),
        FilledButton(
          onPressed: () => setState(() => _count++),   // 只在必要时重建
          child: const Text('加一'),
        ),
      ],
    );
  }
}
```

三条性能习惯：

```dart
1. 能加 const 就加：const 组件不会因父级重建而重建
2. setState 范围尽量小：把状态下沉到最小的 StatefulWidget
3. 高频重绘用 RepaintBoundary 隔离
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 忘记 dispose 控制器 | 内存泄漏 | `dispose()` 里释放 |
| 在 build 里发请求 | 反复请求 | 放 `initState` 或状态管理 |
| setState 后已卸载 | 报「setState called after dispose」 | 加 `if (!mounted) return;` |
| ListView 套 Column | 高度约束冲突 | 用 `Expanded` 包 ListView |
| 用 `Container` 加宽高又不用 | 多余层级 | 用 `SizedBox` 更轻 |
| 列表 key 缺失 | 元素错位 | 用 `ValueKey(item.id)` |
| 硬编码尺寸 | 小屏溢出 | 用比例或 `LayoutBuilder` |
| 忽略 `SafeArea` | 内容被刘海遮挡 | 顶部或底部包 `SafeArea` |

### 手把手练习：一个可滚动的卡片列表

```dart
class ItemList extends StatelessWidget {
  const ItemList({super.key, required this.items});
  final List<Item> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          key: ValueKey(item.id),
          child: ListTile(
            title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DetailPage(item: item)),
            ),
          ),
        );
      },
    );
  }
}
```

### 学完自测

- [ ] 能背出布局三条规则。
- [ ] 知道 `Expanded` 与 `Flexible` 的区别。
- [ ] 能说出长列表为什么必须用 builder。
- [ ] 知道 `const` 组件为什么能减少重建。
- [ ] 能说出 `dispose` 里必须释放哪些东西。
