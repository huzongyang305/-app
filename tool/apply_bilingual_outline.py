"""为 Top 50 课程生成逐节双语大纲。

用法：
    python tool/apply_bilingual_outline.py

优先调用 MyMemory 翻译接口；网络失败时使用内置技术词表。
结果缓存到 tool/translation_cache.json。
"""

from __future__ import annotations

import json
import re
import sys
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(".")
MANIFEST = ROOT / "assets" / "content" / "manifest.json"
CACHE = ROOT / "tool" / "translation_cache.json"
MARKER = "<!-- bilingual-outline:v1 -->"

TOP50 = {
    "python_basics", "python_concurrency", "python_project",
    "cpp_basics", "cpp_memory", "cpp_project",
    "java_basics", "java_concurrency", "java_project",
    "js_basics", "js_async", "js_project",
    "csharp_basics", "csharp_async", "csharp_project",
    "go_basics", "go_concurrency", "go_project",
    "rust_basics", "rust_ownership", "rust_cli_project",
    "typescript", "ts_narrowing_generics", "ts_project",
    "shell_bash", "shell_security", "shell_ci_templates",
    "c_basics", "c_pointers", "c_project",
    "kotlin_basics", "kotlin_coroutines", "kotlin_project",
    "swift_basics", "swift_async", "swift_project",
    "ai_basics", "ai_agent_basics", "ai_embeddings_rag", "ai_mcp",
    "security_threat_model", "security_owasp_top10", "security_supply_chain",
    "time_complexity", "dynamic_programming",
    "http_basics", "tcp_ip",
    "sql_basics", "index",
    "process_thread",
}

FALLBACK = {
    "学习目标": "Learning objectives",
    "前置知识": "Prerequisites",
    "核心知识": "Core concepts",
    "核心概念": "Core concepts",
    "一句话说清": "In one sentence",
    "常见错误": "Common mistakes",
    "动手练习": "Hands-on practice",
    "本课小结": "Summary",
    "代码示例": "Code example",
    "实战": "Hands-on project",
    "总结": "Summary",
    "性能": "Performance",
    "并发": "Concurrency",
    "内存": "Memory",
    "类型": "Types",
    "函数": "Functions",
    "接口": "Interfaces",
    "异步": "Async",
    "测试": "Testing",
    "调试": "Debugging",
    "部署": "Deployment",
    "安全": "Security",
    "网络": "Networking",
    "数据库": "Database",
    "索引": "Index",
    "事务": "Transactions",
    "所有权": "Ownership",
    "生命周期": "Lifetime",
    "集合": "Collections",
    "迭代器": "Iterators",
    "错误处理": "Error handling",
    "模块": "Modules",
    "包管理": "Package management",
    "构建": "Build",
    "发布": "Release",
    "版本": "Versions",
    "查询": "Query",
    "优化": "Optimization",
    "模型": "Model",
    "提示": "Prompt",
    "检索": "Retrieval",
    "向量": "Vector",
    "上下文": "Context",
    "工具": "Tools",
    "权限": "Permissions",
    "威胁": "Threats",
    "漏洞": "Vulnerabilities",
    "身份": "Identity",
    "密钥": "Secrets",
    "协议": "Protocol",
    "缓存": "Cache",
    "队列": "Queue",
    "复制": "Replication",
    "一致性": "Consistency",
    "可用性": "Availability",
    "容量": "Capacity",
    "故障": "Failure",
    "恢复": "Recovery",
    "日志": "Logs",
    "指标": "Metrics",
    "追踪": "Tracing",
}


def translate(text: str, cache: dict, offline: bool) -> str:
    if text in cache:
        return cache[text]
    translated = ""
    try:
        if offline:
            raise RuntimeError("offline mode")
        query = urllib.parse.urlencode(
            {"q": text, "langpair": "zh-CN|en"}
        )
        opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
        with opener.open(
            f"https://api.mymemory.translated.net/get?{query}", timeout=12
        ) as response:
            payload = json.loads(response.read().decode("utf-8"))
        translated = (
            payload.get("responseData", {}).get("translatedText", "").strip()
        )
    except Exception:
        translated = ""
    if not translated:
        for zh, en in sorted(FALLBACK.items(), key=lambda item: -len(item[0])):
            if zh in text:
                text = text.replace(zh, en)
        translated = text
    if not translated:
        translated = text
    cache[text] = translated
    return translated


def headings(text: str) -> list[str]:
    result = []
    for line in text.splitlines():
        match = re.match(r"^##\s+(.+)$", line.strip())
        if not match:
            continue
        value = match.group(1).strip()
        if value in {
            "English Overview",
            "内容元数据",
            "Full English Study Guide",
            "Bilingual Section Outline",
        }:
            continue
        result.append(value)
    return result[:10]


def main() -> None:
    offline = "--offline" in sys.argv
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    lessons = {}
    for category in manifest["categories"]:
        for lesson in category["lessons"]:
            lessons[lesson["id"]] = lesson
    cache = (
        json.loads(CACHE.read_text(encoding="utf-8"))
        if CACHE.exists()
        else {}
    )
    changed = 0
    skipped = 0
    for lesson_id in TOP50:
        lesson = lessons.get(lesson_id)
        if lesson is None:
            continue
        path = ROOT / lesson["file"]
        text = path.read_text(encoding="utf-8")
        if MARKER in text:
            skipped += 1
            continue
        items = headings(text)
        if not items:
            continue
        rows = []
        for item in items:
            rows.append((item, translate(item, cache, offline)))
        table = "\n".join(f"| {zh} | {en} |" for zh, en in rows)
        block = f"""{MARKER}

## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
{table}

> 该大纲把每个中文小节映射为英文标题，配合 Full English Study Guide 使用。
"""
        path.write_text(f"{text.rstrip()}\n\n{block}\n", encoding="utf-8")
        changed += 1
    CACHE.write_text(
        json.dumps(cache, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"生成双语大纲：{changed} 篇，已存在跳过：{skipped} 篇")


if __name__ == "__main__":
    main()
