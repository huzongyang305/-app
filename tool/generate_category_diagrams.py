"""为缺少配图的分类生成专属结构图。

用法：
    python tool/generate_category_diagrams.py

输出：assets/content/images/category_<lesson_id>.png
      tool/image_batches/p3_categories.json
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import generate_diagrams as base  # noqa: E402
from PIL import ImageDraw  # noqa: E402

MANIFEST = Path("assets/content/manifest.json")
BATCH = Path("tool/image_batches/p3_categories.json")
TARGETS = {
    "flutter",
    "html_css",
    "toolchain",
    "distributed",
    "software_engineering",
    "math",
    "cross_language",
    "project_practice",
}


def wrap(text: str, width: int) -> list[str]:
    return [text[i : i + width] for i in range(0, len(text), width)] or [""]


def header(draw: ImageDraw.ImageDraw, title: str, category: str) -> None:
    size = 30 if len(title) > 22 else 34
    draw.text((40, 24), title, font=base.font(size, bold=True), fill=base.INK)
    draw.text((40, 68), category, font=base.font(18), fill=base.MUTED)
    draw.line([(40, 94), (1160, 94)], fill=(229, 231, 235), width=2)


def flow(draw: ImageDraw.ImageDraw, stages: list[str], y: int = 150) -> None:
    count = len(stages)
    gap = 22
    width = int((1120 - gap * (count - 1)) / count)
    for index, stage in enumerate(stages):
        x = 40 + index * (width + gap)
        base.box(
            draw,
            (x, y, x + width, y + 110),
            stage,
            fill=base.PRIMARY_SOFT if index % 2 == 0 else base.ACCENT_SOFT,
            outline=base.PRIMARY if index % 2 == 0 else base.ACCENT,
            size=18,
        )
        if index < count - 1:
            base.arrow(draw, (x + width, y + 55), (x + width + gap, y + 55), color=base.LINE)


def notes(draw: ImageDraw.ImageDraw, items: list[str], start_y: int = 330) -> None:
    for index, item in enumerate(items[:5]):
        y = start_y + index * 58
        draw.ellipse((54, y + 8, 70, y + 24), fill=base.GREEN)
        draw.text((86, y), item, font=base.font(20), fill=base.INK)


def flutter_diagram(name: str, title: str, keywords: list[str]) -> None:
    image, draw = base.new_canvas(1200, 720)
    header(draw, title, "移动开发")
    base.box(draw, (60, 130, 300, 240), "Widget\n不可变配置", fill=base.PRIMARY_SOFT, outline=base.PRIMARY, size=20)
    base.box(draw, (450, 130, 690, 240), "Element\n位置与生命周期", fill=base.ACCENT_SOFT, outline=base.ACCENT, size=20)
    base.box(draw, (840, 130, 1140, 240), "RenderObject\n布局与绘制", fill=base.GREEN_SOFT, outline=base.GREEN, size=20)
    base.arrow(draw, (300, 185), (450, 185), color=base.LINE)
    base.arrow(draw, (690, 185), (840, 185), color=base.LINE)
    notes(draw, ["约束向下传递，尺寸向上汇报", "父节点决定子节点位置", "状态变化只重建依赖它的子树", f"关键词：{', '.join(keywords[:3])}"], 330)
    base.caption(draw, "排查顺序：Widget 树 → Element 身份 → RenderObject 约束", width=1200)
    base.save(image, name)


def html_diagram(name: str, title: str, keywords: list[str]) -> None:
    image, draw = base.new_canvas(1200, 720)
    header(draw, title, "HTML 与 CSS")
    flow(draw, ["HTML", "DOM", "CSSOM", "渲染树", "布局/绘制/合成"])
    notes(draw, ["语义结构先于样式", "盒模型决定尺寸与间距", "动画优先 transform/opacity", f"关键词：{', '.join(keywords[:3])}"], 330)
    base.caption(draw, "排查顺序：元素是否命中 → 盒模型 → 层叠/优先级 → 布局与绘制", width=1200)
    base.save(image, name)


def toolchain_diagram(name: str, title: str, keywords: list[str]) -> None:
    image, draw = base.new_canvas(1200, 720)
    header(draw, title, "工具链")
    flow(draw, ["检出代码", "安装依赖", "检查/测试", "构建制品", "发布/回滚"])
    notes(draw, ["所有步骤可复现且无手工依赖", "缓存键包含锁文件和工具链版本", "制品使用不可变 SHA 标签", f"关键词：{', '.join(keywords[:3])}"], 330)
    base.caption(draw, "CI 的目标：尽早失败、制品可追溯、回滚可执行", width=1200)
    base.save(image, name)


def distributed_diagram(name: str, title: str, keywords: list[str]) -> None:
    image, draw = base.new_canvas(1200, 720)
    header(draw, title, "分布式与架构")
    flow(draw, ["客户端", "网关/负载", "服务副本", "数据副本", "监控/补偿"])
    notes(draw, ["超时、幂等和重试必须一起设计", "多数派提交避免脑裂", "缓存与数据库之间要有一致性策略", f"关键词：{', '.join(keywords[:3])}"], 330)
    base.caption(draw, "设计顺序：边界 → 数据所有权 → 一致性 → 故障恢复", width=1200)
    base.save(image, name)


def software_diagram(name: str, title: str, keywords: list[str]) -> None:
    image, draw = base.new_canvas(1200, 720)
    header(draw, title, "软件工程")
    flow(draw, ["需求", "设计", "编码", "评审/测试", "发布/复盘"])
    notes(draw, ["每阶段必须有可验证产出", "小步提交降低回滚成本", "质量门禁自动执行且不可绕过", f"关键词：{', '.join(keywords[:3])}"], 330)
    base.caption(draw, "质量不是最后一步，而是贯穿需求、设计、实现和发布", width=1200)
    base.save(image, name)


def math_diagram(name: str, title: str, keywords: list[str]) -> None:
    image, draw = base.new_canvas(1200, 720)
    header(draw, title, "数学基础")
    base.box(draw, (80, 150, 330, 260), "输入空间\n向量/集合", fill=base.PRIMARY_SOFT, outline=base.PRIMARY, size=20)
    base.box(draw, (460, 150, 740, 260), "变换/模型\n矩阵/函数", fill=base.ACCENT_SOFT, outline=base.ACCENT, size=20)
    base.box(draw, (870, 150, 1120, 260), "结果/误差\n输出与评估", fill=base.GREEN_SOFT, outline=base.GREEN, size=20)
    base.arrow(draw, (330, 205), (460, 205), color=base.LINE)
    base.arrow(draw, (740, 205), (870, 205), color=base.LINE)
    notes(draw, ["先手算小例子，再用程序验证", "检查条件数、误差和边界", "假设成立范围比公式本身更重要", f"关键词：{', '.join(keywords[:3])}"], 340)
    base.caption(draw, "数学复习闭环：定义 → 手算 → 验证 → 解释边界", width=1200)
    base.save(image, name)


def cross_language_diagram(name: str, title: str, keywords: list[str]) -> None:
    image, draw = base.new_canvas(1200, 720)
    header(draw, title, "跨语言对照")
    stages = ["语法", "类型", "内存", "并发", "错误/生态"]
    for index, stage in enumerate(stages):
        x = 70 + index * 220
        base.box(draw, (x, 150, x + 180, 250), stage, fill=base.PRIMARY_SOFT if index % 2 == 0 else base.ACCENT_SOFT, outline=base.PRIMARY if index % 2 == 0 else base.ACCENT, size=19)
    notes(draw, ["同一种行为在九种语言中的写法不同", "错误处理和内存模型差异最大", "性能比较必须固定环境与数据", f"关键词：{', '.join(keywords[:3])}"], 330)
    base.caption(draw, "对照目标：理解共性，识别语言/运行时边界，避免机械翻译", width=1200)
    base.save(image, name)


def project_diagram(name: str, title: str, keywords: list[str]) -> None:
    image, draw = base.new_canvas(1200, 720)
    header(draw, title, "项目实战")
    flow(draw, ["需求/验收", "设计/拆分", "实现/提交", "测试/发布", "复盘/改进"])
    notes(draw, ["先写可验证的完成标准", "小步交付并保持可回滚", "复盘行动项有负责人和期限", f"关键词：{', '.join(keywords[:3])}"], 330)
    base.caption(draw, "项目闭环：目标 → 交付 → 证据 → 复盘 → 下一轮改进", width=1200)
    base.save(image, name)


GENERATORS = {
    "flutter": flutter_diagram,
    "html_css": html_diagram,
    "toolchain": toolchain_diagram,
    "distributed": distributed_diagram,
    "software_engineering": software_diagram,
    "math": math_diagram,
    "cross_language": cross_language_diagram,
    "project_practice": project_diagram,
}


def main() -> None:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    batch = {}
    count = 0
    for category in manifest["categories"]:
        category_id = category["id"]
        if category_id not in TARGETS:
            continue
        generator = GENERATORS[category_id]
        for lesson in category["lessons"]:
            name = f"category_{lesson['id']}"
            generator(
                name,
                lesson["title"]["zh"],
                lesson.get("keywords", []),
            )
            batch[lesson["id"]] = {
                "image": f"images/{name}.png",
                "alt": lesson["title"]["zh"],
            }
            count += 1
    BATCH.parent.mkdir(parents=True, exist_ok=True)
    BATCH.write_text(json.dumps(batch, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"生成分类专属图 {count} 张，批次：{BATCH}")


if __name__ == "__main__":
    main()
