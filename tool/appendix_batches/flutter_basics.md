## Widget 分类速查

| 类型 | 特点 | 典型组件 |
| --- | --- | --- |
| 无状态 | 不可变、由父级控制 | `StatelessWidget`、`Text`、`Icon` |
| 有状态 | 自身持有并修改状态 | `StatefulWidget`、`TextField`、`AnimationController` |
| 布局 | 控制子组件位置与尺寸 | `Row`、`Column`、`Stack`、`Wrap` |
| 容器与装饰 | 背景、边框、尺寸约束 | `Container`、`DecoratedBox`、`Card` |
| 滚动 | 提供滚动能力 | `ListView`、`GridView`、`CustomScrollView` |
| 交互 | 手势与命中测试 | `GestureDetector`、`InkWell`、`Dismissible` |

## 布局速查

| 需求 | 写法 |
| --- | --- |
| 主轴铺满 | `Expanded(child: ...)` 或 `flex: n` |
| 主轴居中 | `mainAxisAlignment: MainAxisAlignment.center` |
| 交叉轴拉伸 | `crossAxisAlignment: CrossAxisAlignment.stretch` |
| 固定间距 | `SizedBox(height: 12)` 或 `gap` 风格封装 |
| 等分网格 | `GridView.builder` + `SliverGridDelegateWithFixedCrossAxisCount` |
| 层叠 | `Stack` + `Positioned` |
| 溢出换行 | `Wrap` 或 `SingleChildScrollView` |
| 长列表 | `ListView.builder`（不要用 `Column` 堆） |

```dart
// 卡片列表：固定高度 + builder 懒加载，避免一次性构建全部子项
class LessonList extends StatelessWidget {
  const LessonList({super.key, required this.titles});

  final List<String> titles;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: titles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            title: Text(titles[index]),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        );
      },
    );
  }
}

// 自适应两列：用 LayoutBuilder 按可用宽度决定列数
Widget adaptiveGrid(BuildContext context, List<Widget> items) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900 ? 4 : (constraints.maxWidth >= 600 ? 3 : 2);
      return GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: items,
      );
    },
  );
}
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `Column` 里放长列表 | 溢出或性能差 | 改用 `ListView` / `CustomScrollView` |
| 只给子组件 `Container` 设宽高却期望撑满 | 尺寸不符合预期 | 用 `Expanded` 或 `SizedBox.expand` |
| 忘记 `const` | 无谓重建 | 能加的地方都加 `const` |
| 在 `Column` 里用 `Expanded` 但父级无限高 | 运行报错 | 用 `mainAxisSize` 或固定高度 |
| 用 `Container` 只为了 padding | 层次冗余 | 直接用 `Padding` |
| 直接改 Widget 字段期望刷新 | 界面不更新 | 状态改变要走 `setState` 或状态管理 |
| 大列表用 `Column` + `map` | 内存与首帧慢 | 用 `builder` 懒加载 |
| 不处理安全区域 | 内容被刘海或手势条遮挡 | 用 `SafeArea` |
| 硬编码尺寸 | 小屏溢出 | 用相对尺寸与 `LayoutBuilder` |
| 忘记 `dispose` 控制器 | 内存泄漏 | 在 `dispose` 中释放 |

## 自测清单

- [ ] 能说出无状态与有状态组件的使用边界。
- [ ] 会用 `Row`、`Column`、`Stack`、`Expanded` 完成常见布局。
- [ ] 长列表使用 `builder` 懒加载。
- [ ] 尺寸适配使用 `LayoutBuilder` 与相对单位。
- [ ] 控制器与监听在 `dispose` 中释放。
