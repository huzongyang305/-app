"""程序化生成教程配图（技术示意图）。

为什么用代码画图：
  · 结构与时序必须精确，AI 生成图容易画错
  · 改一处参数即可重绘，风格统一、可复现

用法：
    python tool/generate_diagrams.py            # 生成全部图
    python tool/generate_diagrams.py memory     # 只生成名字包含 memory 的图

输出目录：assets/content/images/（默认 WebP，避免仓库里出现 PNG 引用）
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUT_DIR = Path("assets/content/images")
FONT_PATH = r"C:\Windows\Fonts\msyh.ttc"
FONT_BOLD_PATH = r"C:\Windows\Fonts\msyhbd.ttc"

# 配色与 App 主题保持一致
INK = (31, 41, 55)
MUTED = (107, 114, 128)
PRIMARY = (108, 143, 248)
PRIMARY_SOFT = (231, 238, 255)
ACCENT = (14, 165, 233)
ACCENT_SOFT = (224, 242, 254)
WARN = (245, 158, 11)
WARN_SOFT = (254, 243, 199)
GREEN = (22, 163, 74)
GREEN_SOFT = (220, 252, 231)
LINE = (156, 163, 175)
SURFACE = (249, 250, 251)


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_BOLD_PATH if bold else FONT_PATH, size)


def new_canvas(width: int = 1200, height: int = 720) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGB", (width, height), (255, 255, 255))
    return image, ImageDraw.Draw(image)


def draw_title(draw: ImageDraw.ImageDraw, text: str, width: int = 1200) -> None:
    draw.text((40, 28), text, font=font(34, bold=True), fill=INK)
    draw.line([(40, 78), (width - 40, 78)], fill=(229, 231, 235), width=2)


def text_size(draw: ImageDraw.ImageDraw, text: str, use_font: ImageFont.FreeTypeFont) -> tuple[int, int]:
    left, top, right, bottom = draw.textbbox((0, 0), text, font=use_font)
    return right - left, bottom - top


def box(
    draw: ImageDraw.ImageDraw,
    xy: tuple[int, int, int, int],
    text: str,
    fill: tuple[int, int, int] = PRIMARY_SOFT,
    outline: tuple[int, int, int] = PRIMARY,
    size: int = 22,
    bold: bool = False,
    radius: int = 14,
    text_color: tuple[int, int, int] = INK,
) -> None:
    """圆角矩形 + 居中多行文字。"""
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=2)
    use_font = font(size, bold=bold)
    lines = text.split("\n")
    heights = [text_size(draw, line, use_font)[1] for line in lines]
    total = sum(heights) + (len(lines) - 1) * 8
    y = (xy[1] + xy[3]) / 2 - total / 2
    for line, line_height in zip(lines, heights):
        line_width, _ = text_size(draw, line, use_font)
        draw.text(((xy[0] + xy[2]) / 2 - line_width / 2, y), line, font=use_font, fill=text_color)
        y += line_height + 8


def arrow(
    draw: ImageDraw.ImageDraw,
    start: tuple[int, int],
    end: tuple[int, int],
    color: tuple[int, int, int] = LINE,
    width: int = 3,
    head: int = 14,
    label: str | None = None,
    label_size: int = 18,
) -> None:
    """带箭头的连线；可选在中点标注文字。"""
    draw.line([start, end], fill=color, width=width)
    x1, y1 = start
    x2, y2 = end
    if x2 == x1:  # 垂直
        direction = 1 if y2 > y1 else -1
        draw.polygon(
            [(x2, y2), (x2 - head * 0.6, y2 - direction * head), (x2 + head * 0.6, y2 - direction * head)],
            fill=color,
        )
    else:  # 水平
        direction = 1 if x2 > x1 else -1
        draw.polygon(
            [(x2, y2), (x2 - direction * head, y2 - head * 0.6), (x2 - direction * head, y2 + head * 0.6)],
            fill=color,
        )
    if label:
        use_font = font(label_size)
        label_width, label_height = text_size(draw, label, use_font)
        mid_x = (x1 + x2) / 2
        mid_y = (y1 + y2) / 2
        draw.rectangle(
            [mid_x - label_width / 2 - 6, mid_y - label_height / 2 - 4,
             mid_x + label_width / 2 + 6, mid_y + label_height / 2 + 4],
            fill=(255, 255, 255),
        )
        draw.text((mid_x - label_width / 2, mid_y - label_height / 2 - 2), label, font=use_font, fill=MUTED)


def caption(draw: ImageDraw.ImageDraw, text: str, y: int = 680, width: int = 1200) -> None:
    use_font = font(20)
    text_width, _ = text_size(draw, text, use_font)
    draw.text(((width - text_width) / 2, y), text, font=use_font, fill=MUTED)


def save(image: Image.Image, name: str, ext: str = "webp") -> None:
    """保存配图。默认输出 WebP；PNG 仅用于需要无损中间文件的场合。"""
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    path = OUT_DIR / f"{name}.{ext}"
    if ext.lower() == "webp":
        image.save(path, quality=92, method=6)
    else:
        image.save(path, optimize=True)
    print(f"  生成 {path}  ({path.stat().st_size // 1024} KB)")


# ---------------------------------------------------------------- 图解专题

def memory_layout() -> None:
    image, draw = new_canvas()
    draw_title(draw, "内存分区：栈、堆、静态区与常量区")
    box(draw, (70, 110, 470, 200), "栈 Stack\n局部变量 · 函数参数 · 返回地址\n自动分配，后进先出", fill=PRIMARY_SOFT, outline=PRIMARY, size=22)
    box(draw, (70, 220, 470, 330), "堆 Heap\n对象实例 · 数组 · 动态分配\n手动或 GC 管理", fill=ACCENT_SOFT, outline=ACCENT, size=22)
    box(draw, (70, 350, 470, 430), "静态区 / 全局区\n全局变量 · 静态变量", fill=GREEN_SOFT, outline=GREEN, size=22)
    box(draw, (70, 450, 470, 530), "常量区\n字符串字面量 · 常量", fill=WARN_SOFT, outline=WARN, size=22)
    draw.text((60, 560), "低地址", font=font(20), fill=MUTED)
    draw.text((60, 96), "高地址", font=font(20), fill=MUTED)

    draw.text((540, 120), "值类型赋值：各自一份", font=font(24, bold=True), fill=INK)
    box(draw, (560, 160, 700, 220), "a = 1", fill=SURFACE, outline=LINE, size=22)
    box(draw, (740, 160, 880, 220), "b = 1", fill=SURFACE, outline=LINE, size=22)
    draw.text((560, 240), "改 b 不影响 a", font=font(20), fill=MUTED)

    draw.text((540, 320), "引用类型赋值：两份引用指向同一对象", font=font(24, bold=True), fill=INK)
    box(draw, (560, 350, 700, 410), "arr1", fill=SURFACE, outline=LINE, size=22)
    box(draw, (560, 440, 700, 500), "arr2", fill=SURFACE, outline=LINE, size=22)
    box(draw, (940, 375, 1140, 475), "堆对象\n{99, 2}", fill=ACCENT_SOFT, outline=ACCENT, size=22)
    arrow(draw, (700, 380), (940, 400), color=ACCENT)
    arrow(draw, (700, 470), (940, 450), color=ACCENT)
    draw.text((540, 530), "改 arr2[0]，arr1 也会变", font=font(20), fill=MUTED)
    caption(draw, "栈放短期数据，堆放长生命周期对象；赋值复制的是值还是引用，决定了会不会互相影响")
    save(image, "memory_layout")


def call_stack() -> None:
    image, draw = new_canvas()
    draw_title(draw, "调用栈：栈帧的压入与弹出")
    box(draw, (90, 520, 520, 600), "main", fill=SURFACE, outline=LINE, size=24)
    box(draw, (90, 430, 520, 510), "a(n=5)", fill=PRIMARY_SOFT, outline=PRIMARY, size=24)
    box(draw, (90, 340, 520, 420), "b(n=5)", fill=PRIMARY_SOFT, outline=PRIMARY, size=24)
    box(draw, (90, 250, 520, 330), "c(n=5)  ← 栈顶", fill=ACCENT_SOFT, outline=ACCENT, size=24)
    arrow(draw, (620, 560), (620, 250), color=LINE, label="栈增长方向")

    draw.text((700, 200), "每帧包含", font=font(24, bold=True), fill=INK)
    for i, item in enumerate(["返回地址", "保存的寄存器", "函数参数", "局部变量"]):
        box(draw, (700, 250 + i * 70, 1130, 310 + i * 70), item, fill=SURFACE, outline=LINE, size=22)

    draw.text((700, 540), "返回顺序：c → b → a → main", font=font(22), fill=MUTED)
    caption(draw, "每次调用压入一帧，返回时弹出；每帧大小 × 递归深度 = 栈占用")
    save(image, "call_stack")


def event_loop() -> None:
    image, draw = new_canvas()
    draw_title(draw, "事件循环：同步 → 微任务 → 宏任务 → 渲染")
    box(draw, (80, 130, 400, 230), "调用栈\n同步代码在这里执行", fill=PRIMARY_SOFT, outline=PRIMARY, size=22)
    box(draw, (480, 130, 800, 230), "微任务队列\nPromise.then\nqueueMicrotask", fill=GREEN_SOFT, outline=GREEN, size=22)
    box(draw, (880, 130, 1140, 230), "宏任务队列\nsetTimeout\nDOM 事件", fill=WARN_SOFT, outline=WARN, size=22)
    arrow(draw, (400, 180), (480, 180), label="栈空")
    arrow(draw, (800, 180), (880, 180), label="清空后")

    box(draw, (300, 320, 900, 400), "渲染：样式计算 → 布局 → 绘制 → 合成", fill=ACCENT_SOFT, outline=ACCENT, size=24)
    arrow(draw, (1010, 230), (1010, 360), color=WARN)
    arrow(draw, (1010, 360), (900, 360), color=WARN)
    arrow(draw, (300, 360), (140, 360), color=ACCENT)
    arrow(draw, (140, 360), (140, 230), color=ACCENT, label="回到起点")

    draw.text((80, 450), "执行顺序", font=font(24, bold=True), fill=INK)
    for i, item in enumerate([
        "① 同步代码全部执行完",
        "② 清空微任务队列（期间新产生的也要清空）",
        "③ 取一个宏任务执行",
        "④ 再次清空微任务，然后渲染",
    ]):
        draw.text((90, 500 + i * 44), item, font=font(22), fill=INK)
    caption(draw, "微任务无限自我追加会饿死渲染，页面表现为完全无响应")
    save(image, "event_loop")


def concurrency_schedule() -> None:
    image, draw = new_canvas()
    draw_title(draw, "并发调度：线程、协程与 Goroutine 的切换代价")
    box(draw, (70, 120, 360, 200), "系统线程\n由操作系统调度", fill=PRIMARY_SOFT, outline=PRIMARY, size=22)
    box(draw, (70, 240, 360, 320), "协程 / goroutine\n由运行时调度", fill=GREEN_SOFT, outline=GREEN, size=22)
    box(draw, (70, 360, 360, 440), "事件循环回调\n单线程排队执行", fill=ACCENT_SOFT, outline=ACCENT, size=22)

    draw.text((430, 120), "切换代价对照", font=font(24, bold=True), fill=INK)
    rows = [
        ("进入内核态", "是", "否", "否"),
        ("单任务栈", "约 1 MB", "几 KB", "极小"),
        ("数量级", "千级", "十万级", "视队列"),
    ]
    draw.text((430, 170), "项目", font=font(20, bold=True), fill=INK)
    draw.text((620, 170), "线程", font=font(20, bold=True), fill=INK)
    draw.text((800, 170), "协程", font=font(20, bold=True), fill=INK)
    draw.text((980, 170), "事件循环", font=font(20, bold=True), fill=INK)
    for i, (label, a, b, c) in enumerate(rows):
        y = 215 + i * 55
        draw.line([(430, y - 12), (1150, y - 12)], fill=(229, 231, 235))
        draw.text((430, y), label, font=font(20), fill=INK)
        draw.text((620, y), a, font=font(20), fill=MUTED)
        draw.text((800, y), b, font=font(20), fill=MUTED)
        draw.text((980, y), c, font=font(20), fill=MUTED)

    draw.text((70, 490), "选型口诀", font=font(24, bold=True), fill=INK)
    for i, item in enumerate([
        "CPU 密集 → 线程池 / 多进程（需要真并行）",
        "大量网络等待 → 协程或事件循环（切换便宜）",
        "需要强隔离 → 多进程（一个崩溃不影响其他）",
    ]):
        draw.text((80, 540 + i * 44), item, font=font(22), fill=INK)
    caption(draw, "并发是交替推进，并行是真正同时执行；线程不是越多越好")
    save(image, "concurrency_schedule")


def http_timeline() -> None:
    image, draw = new_canvas()
    draw_title(draw, "一次网页请求的五段链路")
    stages = [
        ("① DNS 解析", "域名 → IP", PRIMARY_SOFT, PRIMARY),
        ("② TCP 握手", "三次握手 1 RTT", ACCENT_SOFT, ACCENT),
        ("③ TLS 握手", "证书校验与密钥交换", GREEN_SOFT, GREEN),
        ("④ HTTP 请求", "服务端处理与响应", WARN_SOFT, WARN),
        ("⑤ 解析渲染", "DOM/CSSOM\n布局 → 绘制", PRIMARY_SOFT, PRIMARY),
    ]
    for i, (title_text, sub, fill, outline) in enumerate(stages):
        x = 60 + i * 228
        box(draw, (x, 140, x + 200, 240), f"{title_text}\n{sub}", fill=fill, outline=outline, size=18)
        if i < len(stages) - 1:
            arrow(draw, (x + 200, 190), (x + 228, 190), color=LINE)

    draw.text((60, 290), "每一段都能单独测量", font=font(24, bold=True), fill=INK)
    metrics = [
        ("time_namelookup", "DNS 解析耗时"),
        ("time_connect", "TCP 握手耗时"),
        ("time_appconnect", "TLS 握手耗时"),
        ("time_starttransfer", "首字节时间 TTFB"),
        ("time_total", "总耗时"),
    ]
    for i, (key, desc) in enumerate(metrics):
        y = 345 + i * 55
        draw.text((70, y), key, font=font(22), fill=PRIMARY)
        draw.text((430, y), desc, font=font(22), fill=INK)
    draw.text((700, 345), "渲染五步", font=font(24, bold=True), fill=INK)
    for i, item in enumerate(["HTML → DOM", "CSS → CSSOM", "渲染树", "布局 Layout", "绘制与合成"]):
        draw.text((710, 395 + i * 50), item, font=font(22), fill=INK)
    caption(draw, "排障顺序：先测分段耗时，再优化最慢的那一段")
    save(image, "http_timeline")


def https_cert() -> None:
    image, draw = new_canvas(1100, 700)
    draw_title(draw, "HTTPS 证书链：从叶子到根逐级验签", 1100)
    box(draw, (330, 120, 770, 200), "根证书 Root CA\n内置在系统/浏览器，自签", fill=PRIMARY_SOFT, outline=PRIMARY, size=22)
    box(draw, (330, 270, 770, 350), "中间证书 Intermediate CA\n由根私钥签名，随服务端下发", fill=ACCENT_SOFT, outline=ACCENT, size=22)
    box(draw, (330, 420, 770, 500), "服务器证书 leaf\n含公钥、有效期、SAN 域名", fill=GREEN_SOFT, outline=GREEN, size=22)
    arrow(draw, (550, 200), (550, 270), label="用根私钥签名")
    arrow(draw, (550, 350), (550, 420), label="用中间私钥签名")
    draw.text((60, 150), "验证方向 ↑", font=font(22, bold=True), fill=MUTED)
    arrow(draw, (200, 500), (200, 130), color=MUTED)
    draw.text((60, 540), "下发内容：leaf + intermediate（不要下发根）", font=font(22), fill=INK)
    draw.text((60, 580), "SAN 覆盖所有域名；证书到期前 21 天开始告警", font=font(22), fill=INK)
    caption(draw, "信任的起点是内置根证书；缺中间证书会报 unable to get local issuer certificate", 660, 1100)
    save(image, "https_cert")


def kafka_partition() -> None:
    image, draw = new_canvas()
    draw_title(draw, "Kafka 主题：分区、副本与消费组")
    for i in range(3):
        x = 90 + i * 250
        box(draw, (x, 120, x + 200, 170), f"Partition {i}", fill=PRIMARY_SOFT, outline=PRIMARY, size=22, bold=True)
        for j in range(3):
            box(draw, (x, 180 + j * 60, x + 200, 230 + j * 60), f"offset {j}", fill=SURFACE, outline=LINE, size=20)
        draw.text((x + 20, 370), "Leader: B" + str(i + 1), font=font(20), fill=INK)
        draw.text((x + 20, 400), "Follower: B" + str((i + 1) % 3 + 1), font=font(20), fill=MUTED)

    box(draw, (90, 450, 740, 510), "Broker 1 / Broker 2 / Broker 3", fill=ACCENT_SOFT, outline=ACCENT, size=22)
    draw.text((90, 540), "同一 key 落同一分区 → 分区内有序", font=font(22), fill=INK)

    draw.text((820, 120), "消费组", font=font(24, bold=True), fill=INK)
    box(draw, (820, 170, 1120, 230), "Consumer A → P0 + P2", fill=GREEN_SOFT, outline=GREEN, size=20)
    box(draw, (820, 250, 1120, 310), "Consumer B → P1", fill=GREEN_SOFT, outline=GREEN, size=20)
    draw.text((820, 340), "P1 掉线触发再平衡", font=font(20), fill=MUTED)
    draw.text((820, 375), "期间消费暂停", font=font(20), fill=MUTED)
    caption(draw, "消费者数不超过分区数；可靠性三件套：副本因子 3、acks=all、手动提交 offset")
    save(image, "kafka_partition")


def consistent_hashing() -> None:
    image, draw = new_canvas(1100, 700)
    draw_title(draw, "一致性哈希：加节点只迁移一小段", 1100)
    for index, (cx, title_text, nodes) in enumerate([
        (280, "原有 3 个节点", [("N1", 270, 120), ("N2", 430, 250), ("N3", 300, 400)]),
        (800, "加入 N4 后", [("N1", 790, 120), ("N2", 950, 250), ("N3", 820, 400), ("N4", 690, 250)]),
    ]):
        draw.ellipse([cx - 130, 110, cx + 130, 470], outline=LINE, width=3)
        draw.text((cx - 70, 60), title_text, font=font(22, bold=True), fill=INK)
        for label, x, y in nodes:
            draw.ellipse([x - 34, y - 22, x + 34, y + 22], fill=PRIMARY_SOFT, outline=PRIMARY, width=2)
            draw.text((x - 18, y - 12), label, font=font(20), fill=INK)

    arrow(draw, (440, 290), (640, 290), color=MUTED, label="扩容")
    draw.text((640, 440), "只有 N4 逆时针区间需要迁移", font=font(20), fill=MUTED)
    draw.text((60, 520), "虚拟节点：每个物理节点映射 100~200 个虚拟节点，解决分布倾斜", font=font(22), fill=INK)
    draw.text((60, 560), "取模分片扩容几乎全量迁移；一致性哈希约迁移 1/N", font=font(22), fill=INK)
    caption(draw, "迁移四件套：双写 + 回退读 + 后台搬迁 + 抽样校验", 640, 1100)
    save(image, "consistent_hashing")


def btree_index() -> None:
    image, draw = new_canvas()
    draw_title(draw, "B+ 树：内部节点导航，叶子节点存数据并相连")
    box(draw, (450, 110, 750, 170), "根节点   30 | 80", fill=PRIMARY_SOFT, outline=PRIMARY, size=22, bold=True)
    box(draw, (120, 250, 400, 310), "内部节点  10 | 20", fill=ACCENT_SOFT, outline=ACCENT, size=22)
    box(draw, (800, 250, 1080, 310), "内部节点  60 | 70", fill=ACCENT_SOFT, outline=ACCENT, size=22)
    arrow(draw, (520, 170), (300, 250), color=LINE)
    arrow(draw, (690, 170), (900, 250), color=LINE)

    leaves = ["5, 12", "20, 25", "30, 45", "60, 66", "70, 75", "80, 95"]
    for i, text_value in enumerate(leaves):
        x = 60 + i * 185
        box(draw, (x, 400, x + 150, 460), text_value, fill=GREEN_SOFT, outline=GREEN, size=20)
        if i < len(leaves) - 1:
            arrow(draw, (x + 150, 430), (x + 185, 430), color=GREEN)
    arrow(draw, (250, 310), (150, 400), color=LINE)
    arrow(draw, (900, 310), (960, 400), color=LINE)
    draw.text((60, 500), "所有数据都在叶子层；叶子之间用链表相连 → 范围查询顺序扫描即可", font=font(22), fill=INK)
    draw.text((60, 540), "节点大小对齐磁盘页，扇出大 ⇒ 树高 3 层可索引千万级数据", font=font(22), fill=INK)
    draw.text((60, 580), "最左前缀原则：联合索引 (a,b,c) 必须从 a 开始连续匹配才能用上索引", font=font(22), fill=INK)
    caption(draw, "聚簇索引叶子存整行，二级索引叶子存主键（需要回表）")
    save(image, "btree_index")


def rate_limit_circuit() -> None:
    image, draw = new_canvas(1100, 700)
    draw_title(draw, "熔断器三态：闭合 → 打开 → 半开", 1100)
    box(draw, (120, 260, 380, 360), "闭合 Closed\n正常放行，统计失败率", fill=GREEN_SOFT, outline=GREEN, size=22)
    box(draw, (720, 260, 980, 360), "打开 Open\n直接快速失败", fill=(254, 226, 226), outline=(220, 38, 38), size=22)
    box(draw, (420, 480, 680, 580), "半开 Half-Open\n放少量请求试探", fill=WARN_SOFT, outline=WARN, size=22)
    arrow(draw, (380, 300), (720, 300), color=(220, 38, 38), label="失败率超阈值")
    arrow(draw, (850, 360), (680, 500), color=WARN, label="冷却时间到")
    arrow(draw, (420, 520), (250, 360), color=GREEN, label="试探成功")
    arrow(draw, (500, 480), (760, 360), color=(220, 38, 38), label="试探失败")
    draw.text((60, 620), "必须同时配置：超时（底线）· 有限重试 + 退避 · 降级兜底", font=font(22), fill=INK)
    caption(draw, "入口限流保护自己，出口熔断保护调用方，失败时降级保住核心链路", 660, 1100)
    save(image, "rate_limit_circuit")


def jvm_memory() -> None:
    image, draw = new_canvas(1150, 700)
    draw_title(draw, "JVM 运行时内存：共享区与线程私有区", 1150)
    draw.text((70, 110), "线程共享", font=font(24, bold=True), fill=INK)
    box(draw, (60, 150, 560, 420), "", fill=(255, 255, 255), outline=LINE, size=22)
    box(draw, (90, 180, 530, 250), "堆 Heap（GC 主战场）", fill=PRIMARY_SOFT, outline=PRIMARY, size=22, bold=True)
    box(draw, (110, 270, 250, 340), "Eden", fill=ACCENT_SOFT, outline=ACCENT, size=20)
    box(draw, (270, 270, 370, 340), "S0", fill=ACCENT_SOFT, outline=ACCENT, size=20)
    box(draw, (390, 270, 490, 340), "S1", fill=ACCENT_SOFT, outline=ACCENT, size=20)
    box(draw, (110, 355, 490, 400), "老年代 Old（长期存活对象）", fill=WARN_SOFT, outline=WARN, size=20)
    box(draw, (600, 180, 1090, 300), "方法区 / 元空间 Metaspace\n类元信息 · 常量池 · JDK 8 起用本地内存", fill=GREEN_SOFT, outline=GREEN, size=22)

    draw.text((70, 450), "线程私有", font=font(24, bold=True), fill=INK)
    box(draw, (60, 490, 380, 590), "程序计数器 PC\n当前字节码行号", fill=SURFACE, outline=LINE, size=22)
    box(draw, (410, 490, 730, 590), "虚拟机栈\n栈帧 · 局部变量", fill=SURFACE, outline=LINE, size=22)
    box(draw, (760, 490, 1090, 590), "本地方法栈\nnative 方法调用", fill=SURFACE, outline=LINE, size=22)
    draw.text((60, 620), "对象一生：Eden → S0/S1 →（多次幸存）→ 老年代；Eden 满触发 Young GC", font=font(22), fill=INK)
    caption(draw, "容器里用 -XX:MaxRAMPercentage 限制堆，避免被 OOM Kill", 660, 1150)
    save(image, "jvm_memory")


def llm_inference() -> None:
    image, draw = new_canvas(1150, 700)
    draw_title(draw, "大模型推理两阶段：预填充与解码", 1150)
    draw.text((70, 110), "① 预填充 Prefill（并行处理整个提示）", font=font(24, bold=True), fill=INK)
    for i in range(6):
        box(draw, (80 + i * 130, 150, 190 + i * 130, 210), f"token {i + 1}", fill=PRIMARY_SOFT, outline=PRIMARY, size=20)
    draw.text((80, 230), "计算密集：吃算力，决定首 token 延迟（TTFT）", font=font(22), fill=MUTED)

    draw.text((70, 300), "② 解码 Decode（逐 token 生成）", font=font(24, bold=True), fill=INK)
    for i in range(6):
        fill = GREEN_SOFT if i == 0 else (255, 255, 255)
        box(draw, (80 + i * 130, 340, 190 + i * 130, 400), "?" if i else "输出", fill=fill, outline=GREEN if i == 0 else LINE, size=20)
        if i < 5:
            arrow(draw, (190 + i * 130, 370), (210 + i * 130, 370), color=LINE)
    draw.text((80, 420), "依赖上一步结果，无法完全并行：吃显存带宽，决定每个 token 耗时（TPOT）", font=font(22), fill=MUTED)

    draw.text((70, 480), "显存三巨头", font=font(24, bold=True), fill=INK)
    for i, (label, desc) in enumerate([
        ("模型权重", "固定占用，量化可降 2~4 倍"),
        ("KV 缓存", "随上下文长度与并发线性增长"),
        ("激活值", "与批大小、序列长度相关"),
    ]):
        box(draw, (70 + i * 360, 530, 400 + i * 360, 620), f"{label}\n{desc}", fill=SURFACE, outline=LINE, size=20)
    caption(draw, "容量规划靠压测：留 15%~20% 显存余量，并限制单请求最大长度", 660, 1150)
    save(image, "llm_inference")


def rag_pipeline() -> None:
    image, draw = new_canvas(1200, 720)
    draw_title(draw, "RAG：离线建索引 + 在线检索生成")
    draw.text((70, 105), "离线：建立索引", font=font(24, bold=True), fill=INK)
    offline = ["文档解析\n与清洗", "分块\nChunking", "向量化\nEmbedding", "写入\n向量库"]
    for i, item in enumerate(offline):
        x = 70 + i * 285
        box(draw, (x, 145, x + 240, 235), item, fill=PRIMARY_SOFT, outline=PRIMARY, size=22)
        if i < len(offline) - 1:
            arrow(draw, (x + 240, 190), (x + 285, 190), color=LINE)

    draw.text((70, 285), "在线：回答问题", font=font(24, bold=True), fill=INK)
    online = ["问题\n改写", "检索召回\n向量+关键词", "重排序\nRerank", "组装提示\n问题+片段", "生成答案\n带引用"]
    for i, item in enumerate(online):
        x = 70 + i * 224
        box(draw, (x, 325, x + 190, 415), item, fill=ACCENT_SOFT, outline=ACCENT, size=20)
        if i < len(online) - 1:
            arrow(draw, (x + 190, 370), (x + 224, 370), color=LINE)

    draw.text((70, 460), "三个关键取舍", font=font(24, bold=True), fill=INK)
    box(draw, (70, 510, 400, 620), "分块\n300~800 字 + 10%~20% 重叠", fill=GREEN_SOFT, outline=GREEN, size=20)
    box(draw, (430, 510, 760, 620), "召回\n混合检索覆盖语义与精确匹配", fill=GREEN_SOFT, outline=GREEN, size=20)
    box(draw, (790, 510, 1130, 620), "生成\n只依据资料，无资料就拒答", fill=GREEN_SOFT, outline=GREEN, size=20)
    caption(draw, "质量取决于分块、召回、重排、提示四步；排查先看进入提示的片段对不对", 660, 1200)
    save(image, "rag_pipeline")


def dns_resolution() -> None:
    image, draw = new_canvas()
    draw_title(draw, "DNS 解析：从域名到 IP 的查询链")
    stages = [
        ("浏览器缓存\n命中即返回", PRIMARY_SOFT, PRIMARY),
        ("系统 DNS 缓存\n与 hosts 文件", ACCENT_SOFT, ACCENT),
        ("递归解析器\n代表客户端查询", GREEN_SOFT, GREEN),
        ("根 → 顶级域\n→ 权威服务器", WARN_SOFT, WARN),
    ]
    for index, (label, fill, outline) in enumerate(stages):
        x = 55 + index * 285
        box(draw, (x, 135, x + 235, 235), label, fill=fill, outline=outline, size=21)
        if index < len(stages) - 1:
            arrow(draw, (x + 235, 185), (x + 285, 185), color=LINE)
    draw.text((60, 300), "递归解析器的查询过程", font=font(24, bold=True), fill=INK)
    for index, label in enumerate(["根服务器\n返回 .com 的地址", "TLD 服务器\n返回权威服务器", "权威服务器\n返回 A/AAAA 记录"]):
        x = 70 + index * 370
        box(draw, (x, 355, x + 330, 465), label, fill=SURFACE, outline=LINE, size=21)
        if index < 2:
            arrow(draw, (x + 330, 410), (x + 370, 410), color=LINE)
    draw.text((60, 520), "缓存决定了真实延迟：TTL 越长越省查询，变更生效越慢。", font=font(22), fill=MUTED)
    draw.text((60, 565), "排查顺序：浏览器缓存 → 系统缓存 → 递归解析器 → 权威记录。", font=font(22), fill=MUTED)
    caption(draw, "用 dig +trace 观察每一跳，不要只看最终返回值", 660, 1200)
    save(image, "dns_resolution")


def tcp_handshake() -> None:
    image, draw = new_canvas()
    draw_title(draw, "TCP 三次握手与连接状态")
    box(draw, (90, 125, 360, 205), "客户端\nCLOSED → SYN_SENT", fill=PRIMARY_SOFT, outline=PRIMARY, size=21)
    box(draw, (840, 125, 1110, 205), "服务端\nLISTEN → SYN_RCVD", fill=GREEN_SOFT, outline=GREEN, size=21)
    draw.line([(225, 205), (225, 610)], fill=LINE, width=2)
    draw.line([(975, 205), (975, 610)], fill=LINE, width=2)
    arrow(draw, (225, 265), (975, 265), color=PRIMARY, label="SYN seq=x")
    arrow(draw, (975, 355), (225, 355), color=GREEN, label="SYN+ACK seq=y ack=x+1")
    arrow(draw, (225, 445), (975, 445), color=ACCENT, label="ACK ack=y+1")
    box(draw, (420, 500, 780, 600), "双方确认：\n发送与接收能力都可用，连接建立", fill=WARN_SOFT, outline=WARN, size=21)
    caption(draw, "为什么不是两次：第三次 ACK 才能确认服务端的 SYN 被收到", 660, 1200)
    save(image, "tcp_handshake")


def virtual_memory_paging() -> None:
    image, draw = new_canvas()
    draw_title(draw, "虚拟内存分页：页表负责地址翻译")
    box(draw, (60, 135, 300, 555), "虚拟地址空间\n\n页 0\n页 1\n页 2\n页 3\n…", fill=PRIMARY_SOFT, outline=PRIMARY, size=22)
    box(draw, (420, 180, 740, 510), "页表 Page Table\n\nVPN → PFN\n权限位 R/W/X\n有效位 valid\n脏位 dirty", fill=ACCENT_SOFT, outline=ACCENT, size=21)
    box(draw, (870, 135, 1130, 555), "物理内存\n\n帧 7\n帧 2\n未分配\n帧 9\n…", fill=GREEN_SOFT, outline=GREEN, size=22)
    arrow(draw, (300, 290), (420, 290), color=LINE, label="查表")
    arrow(draw, (740, 340), (870, 340), color=LINE, label="映射")
    box(draw, (300, 590, 900, 660), "TLB 命中直接得到物理地址；缺页时触发 page fault，由内核换入页面", fill=WARN_SOFT, outline=WARN, size=20)
    caption(draw, "局部性好 → 命中率高 → 真实程序不必把整个地址空间放进内存", 690, 1200)
    save(image, "virtual_memory_paging")


def cache_hierarchy() -> None:
    image, draw = new_canvas()
    draw_title(draw, "存储层次：速度、容量与成本的权衡")
    levels = [
        ("寄存器", "~1 周期 · 几十个", PRIMARY_SOFT, PRIMARY),
        ("L1 / L2 缓存", "~4~15 周期 · KB~MB", ACCENT_SOFT, ACCENT),
        ("L3 缓存", "~30~50 周期 · 几 MB~几十 MB", GREEN_SOFT, GREEN),
        ("主存 DRAM", "~100~300 周期 · GB 级", WARN_SOFT, WARN),
        ("SSD / 磁盘", "微秒~毫秒 · TB 级", SURFACE, LINE),
    ]
    for index, (label, desc, fill, outline) in enumerate(levels):
        left = 80 + index * 40
        right = 1120 - index * 40
        top = 125 + index * 100
        box(draw, (left, top, right, top + 76), f"{label}\n{desc}", fill=fill, outline=outline, size=21)
    caption(draw, "越往上越快越小越贵；缓存命中率决定程序是否被内存延迟拖住", 660, 1200)
    save(image, "cache_hierarchy")


def process_thread() -> None:
    image, draw = new_canvas()
    draw_title(draw, "进程与线程：资源所有权和执行流")
    box(draw, (70, 125, 560, 590), "进程 Process\n\n独立虚拟地址空间\n代码 / 数据 / 堆\n打开的文件与信号\n至少一个主线程", fill=PRIMARY_SOFT, outline=PRIMARY, size=23)
    for index, label in enumerate(["线程 1\n程序计数器\n栈 / 寄存器", "线程 2\n程序计数器\n栈 / 寄存器", "线程 3\n程序计数器\n栈 / 寄存器"]):
        y = 180 + index * 125
        box(draw, (650, y, 1120, y + 95), label, fill=GREEN_SOFT if index == 0 else ACCENT_SOFT, outline=GREEN if index == 0 else ACCENT, size=20)
    draw.text((70, 620), "线程共享代码、堆和文件；线程私有 PC、寄存器与栈。", font=font(22), fill=MUTED)
    caption(draw, "切换线程比切换进程轻，但共享数据必须同步", 660, 1200)
    save(image, "process_thread")


def deadlock() -> None:
    image, draw = new_canvas()
    draw_title(draw, "死锁四条件：循环等待一旦形成就无法推进")
    positions = [(210, 135), (790, 135), (790, 485), (210, 485)]
    labels = ["互斥\n资源不可共享", "占有并等待\n拿着 A 等 B", "不可抢占\n不能强行夺走", "循环等待\n互相等对方释放"]
    for (x, y), label in zip(positions, labels):
        box(draw, (x, y, x + 200, y + 120), label, fill=WARN_SOFT, outline=WARN, size=21)
    arrow(draw, (410, 195), (790, 195), color=WARN)
    arrow(draw, (890, 255), (890, 485), color=WARN)
    arrow(draw, (790, 545), (410, 545), color=WARN)
    arrow(draw, (310, 485), (310, 255), color=WARN)
    draw.text((60, 640), "破解任一条件即可预防：统一加锁顺序、超时回退、资源预分配。", font=font(22), fill=MUTED)
    caption(draw, "发现死锁后看重启成本：先止血，再补可观测性和锁顺序约束", 660, 1200)
    save(image, "deadlock")


def big_o() -> None:
    image, draw = new_canvas()
    draw_title(draw, "复杂度增长：输入变大后谁先失控")
    origin = (130, 590)
    draw.line([(origin[0], 110), origin], fill=INK, width=3)
    draw.line([origin, (1120, origin[1])], fill=INK, width=3)
    curves = [
        ("O(1)", (20, 140, 20, 30), GREEN),
        ("O(log n)", (20, 180, 180, 80), ACCENT),
        ("O(n)", (20, 250, 900, 250), PRIMARY),
        ("O(n log n)", (20, 300, 950, 420), WARN),
        ("O(n²)", (20, 360, 900, 560), (220, 38, 38)),
    ]
    for label, (x, y, w, h), color in curves:
        draw.line([(130 + x, 590 - y), (130 + x + w, 590 - y - h)], fill=color, width=5)
        draw.text((130 + x + w + 8, 590 - y - h - 10), label, font=font(20, bold=True), fill=color)
    draw.text((145, 620), "输入规模 n →", font=font(20), fill=MUTED)
    draw.text((45, 95), "运行时间", font=font(20), fill=MUTED)
    caption(draw, "复杂度只描述增长趋势；常数、缓存和实现细节决定同阶算法的实际差距", 660, 1200)
    save(image, "big_o")


def hash_table() -> None:
    image, draw = new_canvas()
    draw_title(draw, "哈希表：哈希函数把键映射到桶")
    box(draw, (60, 180, 310, 320), "键 key\nalice\nbob\ncarol", fill=PRIMARY_SOFT, outline=PRIMARY, size=23)
    box(draw, (410, 200, 650, 300), "哈希函数\nh(key) % N", fill=ACCENT_SOFT, outline=ACCENT, size=23)
    arrow(draw, (310, 250), (410, 250), color=LINE)
    for index in range(5):
        y = 130 + index * 100
        fill = GREEN_SOFT if index in (1, 3) else SURFACE
        box(draw, (760, y, 1120, y + 70), f"桶 {index}" + ("\n→ alice → carol" if index == 3 else ("\n→ bob" if index == 1 else "")), fill=fill, outline=GREEN if index in (1, 3) else LINE, size=20)
    arrow(draw, (650, 250), (760, 250), color=LINE, label="定位")
    draw.text((60, 400), "冲突处理：链地址法把同桶元素串成链表；开放寻址法按探测序列找下一个空位。", font=font(21), fill=INK)
    draw.text((60, 470), "负载因子升高会拉长查找链，通常需要在扩容和内存之间做取舍。", font=font(21), fill=MUTED)
    caption(draw, "平均 O(1) 的前提是哈希均匀、负载因子受控、键不可变", 660, 1200)
    save(image, "hash_table")


def acid_transaction() -> None:
    image, draw = new_canvas()
    draw_title(draw, "数据库事务：ACID 与提交边界")
    stages = [
        ("BEGIN", "开启事务\n记录起始点", PRIMARY),
        ("UPDATE", "写日志 WAL\n修改页缓存", ACCENT),
        ("CHECK", "约束与锁检查\n冲突等待/回滚", WARN),
        ("COMMIT", "日志落盘\n标记提交", GREEN),
    ]
    for index, (title, desc, color) in enumerate(stages):
        x = 60 + index * 290
        box(draw, (x, 150, x + 240, 300), f"{title}\n\n{desc}", fill=SURFACE, outline=color, size=22, bold=True)
        if index < len(stages) - 1:
            arrow(draw, (x + 240, 225), (x + 290, 225), color=color)
    box(draw, (60, 360, 1120, 465), "A 原子性：全做或全不做    C 一致性：约束始终成立\nI 隔离性：并发事务互不看到中间态    D 持久性：提交后故障不丢", fill=PRIMARY_SOFT, outline=PRIMARY, size=23)
    draw.text((60, 520), "隔离级别的本质：在并发异常和数据一致性之间选择代价。", font=font(22), fill=MUTED)
    draw.text((60, 570), "读未提交、读已提交、可重复读、串行化，越往后隔离越强、并发越低。", font=font(22), fill=MUTED)
    caption(draw, "先写日志再改数据：崩溃恢复靠 redo/undo 日志重放", 660, 1200)
    save(image, "acid_transaction")


def cap_theorem() -> None:
    image, draw = new_canvas()
    draw_title(draw, "CAP 与分布式取舍：网络分区时只能保两边")
    points = [(600, 130), (250, 560), (950, 560)]
    labels = ["C 一致性\n所有节点看到同一份数据", "A 可用性\n每个请求都能得到响应", "P 分区容忍\n网络断开仍能继续运行"]
    colors = [PRIMARY, GREEN, WARN]
    for (x, y), label, color in zip(points, labels, colors):
        box(draw, (x - 180, y - 60, x + 180, y + 60), label, fill=SURFACE, outline=color, size=21)
    draw.line([points[0], points[1]], fill=LINE, width=3)
    draw.line([points[1], points[2]], fill=LINE, width=3)
    draw.line([points[2], points[0]], fill=LINE, width=3)
    box(draw, (420, 300, 780, 400), "真实系统：\n分区期间在 C 与 A 之间取舍，恢复后再收敛", fill=WARN_SOFT, outline=WARN, size=21)
    draw.text((60, 640), "不要问“选哪两个”，先问：分区概率、业务能否降级、数据能否合并。", font=font(22), fill=MUTED)
    caption(draw, "大多数业务需要的是分区期间的可控降级，而不是口号式 CAP", 660, 1200)
    save(image, "cap_theorem")


def transformer_attention() -> None:
    image, draw = new_canvas()
    draw_title(draw, "Transformer 注意力：每个 token 重新分配关注")
    for index, token in enumerate(["我", "喜欢", "学习", "编程"]):
        box(draw, (60 + index * 135, 130, 175 + index * 135, 200), token, fill=PRIMARY_SOFT, outline=PRIMARY, size=23)
    draw.text((60, 245), "输入 token → 生成 Q / K / V 三组向量", font=font(22), fill=INK)
    for index, label in enumerate(["Q\n查询", "K\n键", "V\n值"]):
        box(draw, (90 + index * 340, 300, 360 + index * 340, 405), label, fill=ACCENT_SOFT, outline=ACCENT, size=24)
    box(draw, (100, 470, 1100, 570), "Attention(Q,K,V) = softmax(QKᵀ / √d) · V\n每个 token 根据相关性对其他 token 的 V 做加权求和", fill=GREEN_SOFT, outline=GREEN, size=22)
    draw.text((60, 610), "多头注意力让模型同时学习语法、指代、位置和语义等多组关系。", font=font(21), fill=MUTED)
    caption(draw, "上下文越长，注意力的计算与 KV 缓存成本越高", 660, 1200)
    save(image, "transformer_attention")


def agent_loop() -> None:
    image, draw = new_canvas()
    draw_title(draw, "AI Agent 循环：观察、计划、行动、反思")
    stages = [
        ("观察\n读取任务与工具结果", PRIMARY_SOFT, PRIMARY),
        ("计划\n拆解目标与下一步", ACCENT_SOFT, ACCENT),
        ("行动\n调用工具/执行代码", GREEN_SOFT, GREEN),
        ("反思\n校验结果与修正", WARN_SOFT, WARN),
    ]
    for index, (label, fill, outline) in enumerate(stages):
        x = 80 + index * 285
        box(draw, (x, 160, x + 235, 300), label, fill=fill, outline=outline, size=22)
        if index < len(stages) - 1:
            arrow(draw, (x + 235, 230), (x + 285, 230), color=LINE)
    arrow(draw, (1015, 300), (1015, 500), color=LINE)
    arrow(draw, (1015, 500), (195, 500), color=LINE)
    arrow(draw, (195, 500), (195, 300), color=LINE, label="未完成则继续")
    box(draw, (380, 390, 820, 465), "停止条件：任务完成 / 预算耗尽 / 需要人工确认", fill=SURFACE, outline=LINE, size=20)
    draw.text((60, 560), "记忆提供上下文，工具提供行动能力，护栏限制危险操作和无限循环。", font=font(22), fill=MUTED)
    caption(draw, "工程重点不是“会聊天”，而是可观测、可评测、可回滚的闭环", 660, 1200)
    save(image, "agent_loop")


DIAGRAMS = {
    "memory_layout": memory_layout,
    "call_stack": call_stack,
    "event_loop": event_loop,
    "concurrency_schedule": concurrency_schedule,
    "http_timeline": http_timeline,
    "https_cert": https_cert,
    "kafka_partition": kafka_partition,
    "consistent_hashing": consistent_hashing,
    "btree_index": btree_index,
    "rate_limit_circuit": rate_limit_circuit,
    "jvm_memory": jvm_memory,
    "llm_inference": llm_inference,
    "rag_pipeline": rag_pipeline,
    "dns_resolution": dns_resolution,
    "tcp_handshake": tcp_handshake,
    "virtual_memory_paging": virtual_memory_paging,
    "cache_hierarchy": cache_hierarchy,
    "process_thread": process_thread,
    "deadlock": deadlock,
    "big_o": big_o,
    "hash_table": hash_table,
    "acid_transaction": acid_transaction,
    "cap_theorem": cap_theorem,
    "transformer_attention": transformer_attention,
    "agent_loop": agent_loop,
}


def main() -> None:
    filters = sys.argv[1:]
    names = [name for name in DIAGRAMS if not filters or any(f in name for f in filters)]
    if not names:
        print(f"没有匹配的图；可用：{', '.join(DIAGRAMS)}")
        return
    print(f"生成 {len(names)} 张图：")
    for name in names:
        DIAGRAMS[name]()
    print("完成")


if __name__ == "__main__":
    main()
