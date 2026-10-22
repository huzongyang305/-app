"""为 P1 课程和图解专题批量生成统一风格的示意图。

用法：
    python tool/generate_lesson_diagrams.py

输出：
    assets/content/images/lesson_<id>.png
    tool/image_batches/p2.json
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import generate_diagrams as base  # noqa: E402
from PIL import ImageDraw  # noqa: E402


ROOT = Path(".")
SPEC_DIR = ROOT / "tool" / "p1_specs"
MANIFEST = ROOT / "assets" / "content" / "manifest.json"
BATCH = ROOT / "tool" / "image_batches" / "p2.json"


def wrap(text: str, width: int) -> list[str]:
    text = text.strip()
    return [text[i : i + width] for i in range(0, len(text), width)] or [""]


def draw_header(draw: ImageDraw.ImageDraw, title: str, category: str) -> None:
    size = 30 if len(title) > 22 else 34
    draw.text((40, 24), title, font=base.font(size, bold=True), fill=base.INK)
    draw.text((40, 68), category, font=base.font(18), fill=base.MUTED)
    draw.line([(40, 94), (1160, 94)], fill=(229, 231, 235), width=2)


def lesson_diagram(name: str, title: str, category: str, points: list[str], summary: str) -> None:
    image, draw = base.new_canvas(1200, 720)
    draw_header(draw, title, category)
    colors = [
        (base.PRIMARY_SOFT, base.PRIMARY),
        (base.ACCENT_SOFT, base.ACCENT),
        (base.GREEN_SOFT, base.GREEN),
    ]
    for index, point in enumerate(points[:3]):
        y = 116 + index * 118
        fill, outline = colors[index]
        draw.rounded_rectangle((40, y, 1160, y + 96), radius=12, fill=fill, outline=outline, width=2)
        draw.ellipse((58, y + 28, 98, y + 68), fill=outline)
        draw.text((70, y + 35), str(index + 1), font=base.font(20, bold=True), fill=(255, 255, 255))
        lines = wrap(point, 44)[:2]
        for line_index, line in enumerate(lines):
            draw.text((118, y + 22 + line_index * 30), line, font=base.font(20), fill=base.INK)

    stages = ["输入/场景", "核心机制", "验证/指标", "失败与恢复"]
    for index, stage in enumerate(stages):
        x = 40 + index * 285
        base.box(
            draw,
            (x, 486, x + 250, 566),
            stage,
            fill=base.SURFACE,
            outline=base.LINE,
            size=20,
            bold=True,
        )
        if index < len(stages) - 1:
            base.arrow(draw, (x + 250, 526), (x + 285, 526), color=base.LINE)
    base.caption(draw, wrap(summary, 58)[0], y=620, width=1200)
    base.caption(draw, "流程：先建立最小基线，再做单变量实验，最后验证失败与恢复", y=662, width=1200)
    base.save(image, name)


def flow_diagram(
    name: str,
    title: str,
    stages: list[str],
    notes: list[str],
    caption: str,
) -> None:
    image, draw = base.new_canvas(1200, 720)
    draw_header(draw, title, "图解专题")
    count = len(stages)
    gap = 24
    width = int((1120 - gap * (count - 1)) / count)
    for index, stage in enumerate(stages):
        x = 40 + index * (width + gap)
        base.box(
            draw,
            (x, 150, x + width, 250),
            stage,
            fill=base.PRIMARY_SOFT if index % 2 == 0 else base.ACCENT_SOFT,
            outline=base.PRIMARY if index % 2 == 0 else base.ACCENT,
            size=18,
        )
        if index < count - 1:
            base.arrow(draw, (x + width, 200), (x + width + gap, 200), color=base.LINE)

    for index, note in enumerate(notes[:5]):
        y = 300 + index * 58
        draw.ellipse((54, y + 8, 70, y + 24), fill=base.GREEN)
        draw.text((86, y), note, font=base.font(21), fill=base.INK)
    base.caption(draw, caption, y=640, width=1200)
    base.save(image, name)


VISUAL_DIAGRAMS = {
    "visual_git_states": (
        "Git 三区与提交流转",
        ["工作区\n修改文件", "暂存区\ngit add", "本地仓库\ngit commit", "远程仓库\ngit push"],
        ["修改先进入暂存区，提交范围才可控", "提交是不可变快照，分支只是指针", "已推送历史优先用 revert，不用 reset 重写"],
        "排查顺序：git status → git diff → git diff --staged → git log",
    ),
    "visual_tcp_handshake": (
        "TCP 三次握手与四次挥手",
        ["SYN\n客户端", "SYN+ACK\n服务端", "ACK\n连接建立", "DATA\n可靠传输", "FIN/ACK\n关闭连接"],
        ["三次握手交换初始序列号并确认收发能力", "全双工关闭需要两个方向分别 FIN", "TIME_WAIT 等待 2MSL 防止旧报文干扰"],
        "抓包看序列号、确认号、窗口和重传，而不是只看是否连上",
    ),
    "visual_k8s_scheduling": (
        "Kubernetes 调度与探针",
        ["创建 Pod\nPending", "调度筛选\n资源/污点", "节点打分\n亲和/均衡", "kubelet\n启动容器", "探针\n就绪/存活"],
        ["requests/limits 决定可调度资源", "liveness 失败重启，readiness 失败摘流量", "启动探针保护慢启动应用不被误杀"],
        "排查顺序：describe pod → events → 节点资源 → 探针日志",
    ),
    "visual_db_isolation": (
        "数据库事务隔离级别",
        ["读未提交\n可能脏读", "读已提交\n只读提交版本", "可重复读\n事务快照", "串行化\n冲突重试"],
        ["脏读、不可重复读、幻读对应不同可见性", "MVCC 让读写少阻塞，但写冲突仍需锁或版本检查", "隔离越强，并发冲突和重试越多"],
        "业务要明确一致性级别，并对死锁和串行化失败做重试",
    ),
    "visual_mq_delivery": (
        "消息队列投递语义",
        ["生产者\n发送消息", "Broker\n持久化/分区", "消费者\n处理业务", "ACK\n确认完成", "重试/DLQ\n失败隔离"],
        ["at-most-once 可能丢，at-least-once 可能重，exactly-once 需要端到端设计", "消费必须幂等，避免重试导致重复副作用", "死信队列隔离反复失败的消息"],
        "投递语义是业务契约，不是 MQ 自动提供的保证",
    ),
    "visual_oauth_flow": (
        "OAuth 2.0 授权码流程与 PKCE",
        ["客户端\n生成 PKCE", "授权服务器\n用户登录", "回调\n返回授权码", "令牌交换\ncode+verifier", "访问资源\naccess token"],
        ["授权码只用于换取令牌，不应直接访问资源", "PKCE 防止授权码被截获后滥用", "state 防 CSRF，redirect_uri 必须严格校验"],
        "排查顺序：redirect_uri → state → code_verifier → scope → token 过期",
    ),
    "visual_cdn_cache": (
        "CDN 缓存与回源",
        ["DNS\n就近解析", "边缘节点\n查缓存", "命中\n直接返回", "未命中\n回源", "缓存\n设置 TTL"],
        ["Cache-Control、ETag 和 Vary 决定缓存行为", "TTL 抖动避免大量内容同时失效", "回源限流和预热防止源站被打穿"],
        "排查顺序：命中率 → TTL → 缓存键 → 回源量 → 源站延迟",
    ),
    "visual_vector_index": (
        "向量检索与 HNSW",
        ["查询向量\nEmbedding", "上层导航\n稀疏跳转", "底层搜索\n邻接扩展", "Top-K\n候选结果", "Rerank\n精排"],
        ["HNSW 用分层图把搜索步数降到近似对数", "efSearch 影响召回率和延迟", "删除通常软删除，需要过滤或定期重建"],
        "评测顺序：Recall@K → 延迟 P95 → 内存 → 更新成本",
    ),
}


def load_p1_lessons() -> list[dict]:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    by_id = {}
    for category in manifest["categories"]:
        for lesson in category["lessons"]:
            by_id[lesson["id"]] = {
                "title": lesson["title"]["zh"],
                "summary": lesson["summary"]["zh"],
                "category": category["title"]["zh"],
                "keywords": lesson.get("keywords", []),
            }
    specs = {}
    for path in SPEC_DIR.glob("*.json"):
        specs.update(json.loads(path.read_text(encoding="utf-8")))
    lessons = []
    for lesson_id, spec in specs.items():
        meta = by_id.get(lesson_id, {})
        lessons.append(
            {
                "id": lesson_id,
                "title": meta.get("title", spec["title"]["zh"]),
                "summary": meta.get("summary", spec["summary"]["zh"]),
                "category": meta.get("category", spec["category"]),
                "points": spec["points"],
            }
        )
    return lessons


def main() -> None:
    batch = {}
    lessons = load_p1_lessons()
    for lesson in lessons:
        name = f"lesson_{lesson['id']}"
        lesson_diagram(
            name,
            lesson["title"],
            lesson["category"],
            lesson["points"],
            lesson["summary"],
        )
        batch[lesson["id"]] = {
            "image": f"images/{name}.png",
            "alt": lesson["title"],
        }

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    titles = {
        lesson["id"]: lesson["title"]["zh"]
        for category in manifest["categories"]
        for lesson in category["lessons"]
    }
    for lesson_id, (title, stages, notes, caption) in VISUAL_DIAGRAMS.items():
        name = lesson_id
        flow_diagram(name, title, stages, notes, caption)
        batch[lesson_id] = {
            "image": f"images/{name}.png",
            "alt": titles.get(lesson_id, title),
        }

    BATCH.parent.mkdir(parents=True, exist_ok=True)
    BATCH.write_text(json.dumps(batch, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"共生成 {len(batch)} 张图，批次文件：{BATCH}")


if __name__ == "__main__":
    main()
