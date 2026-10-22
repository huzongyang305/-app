## 状态分类速查

| 状态类型 | 生命周期 | 推荐方案 |
| --- | --- | --- |
| 局部 UI 状态 | 单页面 | `StatefulWidget` + `setState` |
| 跨组件共享 | 多个页面 | Provider / Riverpod |
| 全局配置 | 应用级 | Provider + 持久化 |
| 派生状态 | 由其他状态计算 | 直接计算，不额外存 |
| 异步数据 | 网络请求 | `FutureBuilder` 或状态管理的异步封装 |

## 重建范围优化速查

| 手段 | 效果 |
| --- | --- |
| `const` 构造 | 跳过不必要的重建 |
| `Consumer` 包裹最小范围 | 只重建依赖部分 |
| `Selector` / `context.select` | 只在特定字段变化时重建 |
| `ValueListenableBuilder` | 精准监听单值变化 |
| `RepaintBoundary` | 减少重绘区域（与重建不同） |
| `ListView.builder` | 只构建可见项 |
| 拆分组件 | 缩小重建边界 |

```dart
class CartModel extends ChangeNotifier {
  final List<String> _items = [];
  List<String> get items => List.unmodifiable(_items);

  double get total => _items.length * 9.9;

  void add(String item) {
    _items.add(item);
    notifyListeners();          // 只通知一次，避免多次重建
  }

  void removeAt(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    notifyListeners();
  }
}

// 只重建总数文本，而不是整页
class CartTotal extends StatelessWidget {
  const CartTotal({super.key});

  @override
  Widget build(BuildContext context) {
    final total = context.select<CartModel, double>((model) => model.total);
    return Text('合计：${total.toStringAsFixed(2)}');
  }
}

// 列表项单独订阅，避免父级重建带动整列
class CartItemTile extends StatelessWidget {
  const CartItemTile({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<CartModel>();
    final title = model.items[index];
    return ListTile(
      title: Text(title),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => model.removeAt(index),
      ),
    );
  }
}
```

## 生命周期速查

| 阶段 | 时机 | 典型用途 |
| --- | --- | --- |
| `initState` | 组件插入树后 | 初始化控制器、首次请求 |
| `didChangeDependencies` | 依赖变化 | 读取 `InheritedWidget` 或主题 |
| `build` | 每次需要渲染 | 只做构建，不放副作用 |
| `didUpdateWidget` | 父级传入参数变化 | 对比新旧参数做响应 |
| `dispose` | 组件移除 | 取消订阅、释放控制器 |
| `deactivate` | 从树中暂时移除 | 少见，谨慎使用 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 在 `build` 里发请求或改状态 | 无限重建或报错 | 副作用放 `initState` 或事件回调 |
| 忘记 `notifyListeners` | 界面不刷新 | 状态变更后显式通知 |
| 一次变更多次通知 | 重建次数翻倍 | 合并为一次通知 |
| 用全局状态存临时输入 | 状态混乱 | 局部状态用 `setState` |
| 忘记 `dispose` | 内存泄漏、回调仍在跑 | 释放控制器与订阅 |
| `setState` 后使用旧值 | 界面与数据不一致 | 用函数式更新或读取最新状态 |
| 在 `dispose` 后调用 `setState` | 运行时报错 | 异步回调中先判断 `mounted` |
| 把所有状态都提到全局 | 耦合严重、难测试 | 就近管理，按需共享 |
| 依赖派生状态另存一份 | 两份数据不同步 | 直接计算派生值 |
| 大对象频繁 `notifyListeners` | 卡顿 | 拆分模型或精细订阅 |

## 自测清单

- [ ] 能判断状态应放在局部还是全局。
- [ ] 会用 `select` 或 `Consumer` 缩小重建范围。
- [ ] 副作用不写在 `build` 中。
- [ ] 控制器与订阅在 `dispose` 中释放。
- [ ] 派生状态直接计算，不额外存储。
