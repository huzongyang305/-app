## 零基础详解：小程序开发要点

### 一句话说清它是什么

小程序是「运行在宿主 App 里的轻量应用」，用 **WXML + WXSS + JS/TS** 三件套编写。
它最大的特点是：**逻辑层与渲染层分离，数据通过 `setData` 单向传递**。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| WXML | 骨架 | 描述结构（类似 HTML） |
| WXSS | 皮肤 | 描述样式（类似 CSS） |
| JS/TS | 神经 | 逻辑与数据 |
| `setData` | 快递员 | 把数据从逻辑层送到渲染层 |
| 分包 | 分册装订 | 减小首屏体积 |

### 页面文件结构

```text
pages/orders/
  orders.wxml      结构
  orders.wxss      样式
  orders.ts        逻辑
  orders.json      页面配置
app.json           全局配置（页面注册、窗口、分包）
app.ts             应用生命周期
```

### 一个页面的完整写法

```xml
<!-- orders.wxml -->
<view class="page">
  <view wx:if="{{loading}}" class="tip">加载中…</view>
  <view wx:elif="{{error}}" class="tip error">{{error}}</view>
  <view wx:elif="{{orders.length === 0}}" class="tip">暂无订单</view>
  <view wx:else>
    <view
      wx:for="{{orders}}"
      wx:key="id"
      class="card"
      bindtap="onTapOrder"
      data-id="{{item.id}}"
    >
      <text class="title">{{item.title}}</text>
      <text class="amount">¥{{item.amount}}</text>
    </view>
  </view>
</view>
```

```typescript
// orders.ts
Page({
  data: {
    orders: [] as Order[],
    loading: true,
    error: "",
  },

  onLoad() {
    void this.loadOrders();
  },

  async loadOrders() {
    this.setData({ loading: true, error: "" });
    try {
      const res = await wx.request<{ items: Order[] }>({ url: "/api/orders" });
      this.setData({ orders: res.data.items, loading: false });
    } catch (e) {
      this.setData({ error: "加载失败，请稍后重试", loading: false });
    }
  },

  onTapOrder(e: WechatMiniprogram.TouchEvent) {
    const id = e.currentTarget.dataset.id as string;
    wx.navigateTo({ url: `/pages/detail/detail?id=${id}` });
  },
});
```

### setData 的三条纪律

```typescript
// 1. 只传变化的部分，不要整体传
this.setData({ "orders[0].title": "新标题" });

// 2. 高频更新要合并，别在循环里反复 setData
const patch: Record<string, unknown> = {};
for (const item of changed) patch[`orders[${item.index}].title`] = item.title;
this.setData(patch);

// 3. 不要传大对象或函数
this.setData({ list: hugeArray });        // 数据量大时会明显卡顿
```

| 原则 | 原因 |
| --- | --- |
| 最小化数据 | 跨线程通信成本高 |
| 合并更新 | 每次 setData 都是一次通信 |
| 不传函数 | 只支持可序列化数据 |

**长列表用 `recycle-view` 或虚拟列表组件**，直接 `wx:for` 上千条会卡。

### 分包与体积控制

```json
// app.json
{
  "pages": ["pages/index/index"],
  "subPackages": [
    {
      "root": "packageOrders",
      "pages": ["list/list", "detail/detail"]
    }
  ],
  "preloadRule": {
    "pages/index/index": { "network": "all", "packages": ["packageOrders"] }
  }
}
```

| 手段 | 效果 |
| --- | --- |
| 分包 | 首屏只加载主包 |
| 预加载规则 | 空闲时提前下载分包 |
| 图片放 CDN | 不占包体积 |
| 按需引入组件库 | 避免整库打包 |

### 常见 API 与能力

| 需求 | API |
| --- | --- |
| 请求 | `wx.request` |
| 存储 | `wx.setStorageSync` / `wx.getStorageSync` |
| 登录 | `wx.login` 换 code，服务端换 openid |
| 支付 | `wx.requestPayment` |
| 分享 | `onShareAppMessage` |
| 扫码 | `wx.scanCode` |

**敏感信息（如 session_key、密钥）只能放服务端**，小程序端一律不可信。

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 频繁 setData | 界面卡顿 | 合并更新、只传变化字段 |
| 传大数组 | 通信开销大 | 分页或虚拟列表 |
| `wx:for` 缺 `wx:key` | 列表状态错乱 | 用稳定唯一字段 |
| 把密钥放前端 | 泄露 | 放服务端 |
| 不处理请求失败 | 白屏 | 四态齐全 |
| 主包塞太多页面 | 首屏加载慢 | 分包 |
| 用 `data-*` 传复杂对象 | 序列化丢失 | 只传 id，自己查数据 |
| 忽略审核规范 | 上架被拒 | 提前查类目与内容要求 |

### 学完自测

- [ ] 能说出 WXML、WXSS、JS 各自负责什么。
- [ ] 知道 `setData` 为什么要注意性能。
- [ ] 能说出 `wx:key` 的作用。
- [ ] 知道为什么要分包。
- [ ] 能说出哪类信息绝不能放小程序端。
