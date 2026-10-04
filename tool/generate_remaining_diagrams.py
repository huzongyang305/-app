"""为剩余无图课程生成分类专属 WebP 示意图。

用法：
    python tool/generate_remaining_diagrams.py

输出：assets/content/images/remaining_<id>.webp
      tool/image_batches/p4.json
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import generate_diagrams as base  # noqa: E402
from PIL import ImageDraw  # noqa: E402

ROOT = Path(".")
CONTENT = ROOT / "assets" / "content"
MANIFEST = CONTENT / "manifest.json"
BATCH = ROOT / "tool" / "image_batches" / "p4.json"


def wrap(text: str, width: int) -> list[str]:
    return [text[i : i + width] for i in range(0, len(text), width)] or [""]


def header(draw: ImageDraw.ImageDraw, title: str, category: str) -> None:
    size = 28 if len(title) > 24 else 32
    draw.text((40, 24), title, font=base.font(size, bold=True), fill=base.INK)
    draw.text((40, 66), category, font=base.font(17), fill=base.MUTED)
    draw.line([(40, 92), (1160, 92)], fill=(229, 231, 235), width=2)


def flow(draw: ImageDraw.ImageDraw, stages: list[str], y: int = 130) -> None:
    count = len(stages)
    gap = 20
    width = int((1120 - gap * (count - 1)) / count)
    for index, stage in enumerate(stages):
        x = 40 + index * (width + gap)
        base.box(
            draw,
            (x, y, x + width, y + 105),
            stage,
            fill=base.PRIMARY_SOFT if index % 2 == 0 else base.ACCENT_SOFT,
            outline=base.PRIMARY if index % 2 == 0 else base.ACCENT,
            size=17,
        )
        if index < count - 1:
            base.arrow(draw, (x + width, y + 52), (x + width + gap, y + 52), color=base.LINE)


def bullets(draw: ImageDraw.ImageDraw, items: list[str], start_y: int = 300) -> None:
    for index, item in enumerate(items[:5]):
        y = start_y + index * 62
        draw.ellipse((54, y + 9, 70, y + 25), fill=base.GREEN)
        draw.text((86, y), item, font=base.font(19), fill=base.INK)


GROUPS = {
    "language": ["语法/类型", "运行/编译", "测试/调试", "工程/发布"],
    "algorithms": ["输入数据", "状态/结构", "算法步骤", "复杂度/验证"],
    "network": ["客户端", "协议交互", "传输/路由", "服务端/观测"],
    "database": ["查询/写入", "索引/事务", "存储引擎", "一致性与恢复"],
    "ai": ["输入/提示", "模型/检索", "工具/生成", "评测/安全"],
    "security": ["资产/入口", "威胁/漏洞", "控制/权限", "检测/响应"],
    "systems": ["硬件/内核", "资源/调度", "IO/存储", "故障/观测"],
    "distributed": ["客户端", "网关/服务", "数据副本", "故障/补偿"],
    "engineering": ["需求/设计", "实现/评审", "测试/发布", "复盘/改进"],
    "math": ["定义/集合", "变换/矩阵", "计算/误差", "验证/边界"],
    "cross": ["语法", "类型", "内存/并发", "错误/生态"],
    "visual": ["输入/场景", "核心机制", "状态变化", "验证/失败"],
}


def group_for(category_id: str) -> str:
    if category_id in {"python", "cpp", "java", "javascript", "csharp", "go", "rust", "typescript", "shell", "c", "kotlin", "swift", "flutter", "html_css"}:
        return "language"
    if category_id == "algorithms":
        return "algorithms"
    if category_id == "network":
        return "network"
    if category_id == "database":
        return "database"
    if category_id == "ai":
        return "ai"
    if category_id == "security":
        return "security"
    if category_id in {"fundamentals", "os", "toolchain"}:
        return "systems"
    if category_id == "distributed":
        return "distributed"
    if category_id in {"software_engineering", "project_practice"}:
        return "engineering"
    if category_id == "math":
        return "math"
    if category_id == "cross_language":
        return "cross"
    return "visual"


def make_diagram(
    name: str,
    title: str,
    category: str,
    summary: str,
    keywords: list[str],
    category_id: str,
) -> None:
    image, draw = base.new_canvas(1200, 720)
    header(draw, title, category)
    group = group_for(category_id)
    stages = GROUPS[group]
    if group == "math":
        # 数学使用矩阵 + 变换 + 结果三层图。
        base.box(draw, (80, 150, 340, 260), "输入/定义\n集合、向量", fill=base.PRIMARY_SOFT, outline=base.PRIMARY, size=19)
        base.box(draw, (460, 150, 740, 260), "变换/计算\n函数、矩阵", fill=base.ACCENT_SOFT, outline=base.ACCENT, size=19)
        base.box(draw, (860, 150, 1120, 260), "结果/误差\n输出、边界", fill=base.GREEN_SOFT, outline=base.GREEN, size=19)
        base.arrow(draw, (340, 205), (460, 205), color=base.LINE)
        base.arrow(draw, (740, 205), (860, 205), color=base.LINE)
    else:
        flow(draw, stages)
    notes = [
        wrap(summary, 52)[0],
        f"关键词：{', '.join(keywords[:3])}" if keywords else "先定义输入、输出和边界",
        "先建立最小基线，再做单变量实验",
        "失败时记录错误、恢复和回滚路径",
    ]
    bullets(draw, notes, 330)
    base.caption(draw, "课程图：概念 → 机制 → 验证 → 失败恢复", y=650, width=1200)
    out = base.OUT_DIR / f"{name}.webp"
    out.parent.mkdir(parents=True, exist_ok=True)
    image.save(out, "WEBP", quality=82, method=4)
    print(f"  生成 {out}")


def main() -> None:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    batch = {}
    count = 0
    for category in manifest["categories"]:
        for lesson in category["lessons"]:
            path = ROOT / lesson["file"]
            if not path.exists():
                continue
            text = path.read_text(encoding="utf-8")
            if re.search(r"!\[[^\]]*\]\(images/", text):
                continue
            name = f"remaining_{lesson['id']}"
            make_diagram(
                name,
                lesson["title"]["zh"],
                category["title"]["zh"],
                lesson["summary"]["zh"],
                lesson.get("keywords", []),
                category["id"],
            )
            batch[lesson["id"]] = {
                "image": f"images/{name}.webp",
                "alt": lesson["title"]["zh"],
            }
            count += 1
    BATCH.parent.mkdir(parents=True, exist_ok=True)
    BATCH.write_text(json.dumps(batch, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"生成剩余配图 {count} 张，批次：{BATCH}")


if __name__ == "__main__":
    main()
