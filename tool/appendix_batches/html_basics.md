## 语义标签速查

| 标签 | 用途 | 注意 |
| --- | --- | --- |
| `header` / `footer` | 页头与页脚 | 可出现在 section 内 |
| `nav` | 导航链接区 | 主要导航用一次为主 |
| `main` | 页面唯一主体 | 一页只应有一个 |
| `section` | 有主题的内容块 | 通常带标题 |
| `article` | 可独立分发的内容 | 文章、卡片、评论 |
| `aside` | 侧边或补充内容 | 与主体相关但可独立 |
| `figure` / `figcaption` | 图与说明 | 图片加题注的标准写法 |
| `button` | 可点击操作 | 非跳转一律用按钮 |
| `a` | 跳转链接 | 必须有有效 `href` |

## 表单与可访问性速查

| 需求 | 写法 |
| --- | --- |
| 关联标签 | `<label for="email">邮箱</label><input id="email">` |
| 输入类型 | `type="email"`、`tel`、`number`、`date` |
| 必填与校验 | `required`、`minlength`、`pattern` |
| 提示说明 | `aria-describedby` 指向说明元素 |
| 错误提示 | `aria-invalid` 与错误文本容器 |
| 图片替代文本 | `alt` 描述内容；纯装饰用 `alt=""` |
| 按钮语义 | `<button type="button">` 避免误提交 |
| 跳过导航 | 页首提供「跳到主内容」链接 |
| 键盘可达 | 保留可见焦点样式，不设 `outline: none` |

```html
<!DOCTYPE html>
<html lang="zh-CN">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>课程详情</title>
    <meta name="description" content="离线可用的计算机与编程学习课程" />
  </head>
  <body>
    <a class="skip-link" href="#main">跳到主内容</a>
    <header>
      <nav aria-label="主导航">
        <a href="/">首页</a>
        <a href="/learn" aria-current="page">学习</a>
      </nav>
    </header>
    <main id="main">
      <article>
        <h1>Flutter 基础</h1>
        <figure>
          <img src="widget-tree.png" alt="Widget 树从根到叶的层级示意" />
          <figcaption>Widget 树结构示意</figcaption>
        </figure>
        <form>
          <label for="note">学习笔记</label>
          <textarea id="note" name="note" aria-describedby="note-hint"></textarea>
          <p id="note-hint">最多 200 字，保存在本机。</p>
          <button type="submit">保存</button>
        </form>
      </article>
    </main>
    <footer><p>© 2025 计算机与编程学习</p></footer>
  </body>
</html>
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用 `div` 做所有结构 | 屏幕阅读器无法理解 | 用语义标签 |
| 用 `<a href="#">` 当按钮 | 键盘与语义异常 | 用 `<button>` |
| 图片不写 `alt` | 无障碍不达标 | 内容图描述，装饰图留空 |
| 多个 `<h1>` 或跳级标题 | 结构混乱 | 按层级递进，一页一个主标题 |
| 缺少 `lang` 属性 | 朗读与断词异常 | `<html lang="zh-CN">` |
| 忘记 `viewport` | 移动端缩放异常 | 加标准 viewport meta |
| 表单元素没有 `label` | 点击区域小、可访问性差 | 用 `for` 关联 |
| `outline: none` 去焦点 | 键盘用户无法定位 | 保留或用 `:focus-visible` 自定义 |
| 用表格做布局 | 语义错误、响应式差 | 用 Flex 或 Grid |
| 纯图标按钮无 `aria-label` | 读屏无法识别 | 加可访问名称 |

## 自测清单

- [ ] 页面结构使用语义标签，`main` 唯一。
- [ ] 所有表单控件都有 `label`。
- [ ] 图片有恰当的 `alt`。
- [ ] 键盘可完整操作且焦点可见。
- [ ] 有 `lang`、`viewport`、`title` 与 `description`。
