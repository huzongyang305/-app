"""使用 MyMemory 接口并发生成 Top 50 英文正文。

用法：
    python tool/translate_top50_mymemory.py [--limit=1] [--workers=6]

特性：
    · 每个请求最多 500 字符，自动按句切分；
    · 本地缓存 tool/translation_memory.json，重复内容不重复请求；
    · 保留代码围栏、行内代码和 URL；
    · 输出 assets/content_en/<lesson_id>.md，并写入 manifest 的 file_en。
"""

from __future__ import annotations

import concurrent.futures
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(".")
MANIFEST = ROOT / "assets" / "content" / "manifest.json"
OUT = ROOT / "assets" / "content_en"
CACHE_PATH = ROOT / "tool" / "translation_memory.json"
API = "https://api.mymemory.translated.net/get"
MAX_CHARS = 450

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

HAS_CJK = re.compile(r"[\u4e00-\u9fff]")


def has_cjk(text: str) -> bool:
    return bool(HAS_CJK.search(text))


def load_cache() -> dict[str, str]:
    if CACHE_PATH.exists():
        return json.loads(CACHE_PATH.read_text(encoding="utf-8"))
    return {}


def save_cache(cache: dict[str, str]) -> None:
    CACHE_PATH.write_text(
        json.dumps(cache, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def split_chunks(text: str) -> list[str]:
    if len(text) <= MAX_CHARS:
        return [text]
    parts = re.split(r"(?<=[。！？!?；;])", text)
    chunks: list[str] = []
    current = ""
    for part in parts:
        if current and len(current) + len(part) > MAX_CHARS:
            chunks.append(current)
            current = part
        else:
            current += part
    if current:
        chunks.append(current)
    return chunks


def translate_chunk(text: str, cache: dict[str, str]) -> str:
    if text in cache:
        return cache[text]
    query = urllib.parse.urlencode(
        {"q": text, "langpair": "zh-CN|en"}
    )
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    for attempt in range(3):
        try:
            with opener.open(f"{API}?{query}", timeout=30) as response:
                payload = json.loads(response.read().decode("utf-8"))
            translated = (
                payload.get("responseData", {}).get("translatedText", "").strip()
            )
            if (
                translated
                and "QUERY LENGTH LIMIT" not in translated
                and "MYMEMORY WARNING" not in translated
            ):
                cache[text] = translated
                return translated
        except Exception:
            pass
        time.sleep(0.5 * (attempt + 1))
    return text


def protect_inline(text: str) -> tuple[str, list[str]]:
    protected: list[str] = []

    def replace(match: re.Match) -> str:
        protected.append(match.group(0))
        return f"XQZ{len(protected) - 1}QZX"

    pattern = re.compile(r"`[^`]+`|https?://\S+|\[[^\]]+\]\([^)]+\)")
    return pattern.sub(replace, text), protected


def restore_inline(text: str, protected: list[str]) -> str:
    for index, value in enumerate(protected):
        text = re.sub(
            rf"XQZ\s*{index}\s*QZX",
            value.replace("\\", "\\\\"),
            text,
            flags=re.IGNORECASE,
        )
    return text


def collect_chunks(lines: list[str]) -> tuple[list[str], list[tuple]]:
    chunks: list[str] = []
    owners: list[tuple] = []
    in_fence = False
    for line_index, line in enumerate(lines):
        if line.strip().startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence or not has_cjk(line):
            continue
        if line.strip().startswith("|"):
            if set(line.replace("|", "").strip()) <= {"-", ":"}:
                continue
            cells = line.split("|")
            for cell_index, cell in enumerate(cells):
                if not has_cjk(cell):
                    continue
                protected, values = protect_inline(cell)
                for chunk in split_chunks(protected):
                    chunks.append(chunk)
                    owners.append(("table", line_index, cell_index, values))
            continue
        match = re.match(r"^(\s*(?:#{1,6}|[-*+]|\d+\.)\s+)(.*)$", line)
        content = match.group(2) if match else line
        protected, values = protect_inline(content)
        for chunk in split_chunks(protected):
            chunks.append(chunk)
            owners.append(("line", line_index, match.group(1) if match else "", values))
    return chunks, owners


def translate_markdown(
    text: str,
    cache: dict[str, str],
    workers: int,
) -> str:
    lines = text.splitlines()
    chunks, owners = collect_chunks(lines)
    unique = list(dict.fromkeys(chunks))
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as pool:
        futures = {
            pool.submit(translate_chunk, chunk, cache): chunk for chunk in unique
        }
        for future in concurrent.futures.as_completed(futures):
            future.result()

    assembled: dict[object, list[str]] = {}
    for chunk, owner in zip(chunks, owners):
        key = (
            ("table", owner[1], owner[2])
            if owner[0] == "table"
            else owner[1]
        )
        assembled.setdefault(key, []).append(cache.get(chunk, chunk))

    table_values: dict[tuple[int, int], list[str]] = {}
    for chunk, owner in zip(chunks, owners):
        if owner[0] == "table":
            table_values.setdefault((owner[1], owner[2]), owner[3])

    for key, values in table_values.items():
        line_index, cell_index = key
        cells = lines[line_index].split("|")
        translated = "".join(assembled.get(("table", line_index, cell_index), []))
        cells[cell_index] = restore_inline(translated, values)
        lines[line_index] = "|".join(cells)

    for line_index, prefix, values in (
        (owner[1], owner[2], owner[3])
        for owner in owners
        if owner[0] == "line"
    ):
        translated = "".join(assembled.get(line_index, []))
        lines[line_index] = prefix + restore_inline(translated, values)
    return "\n".join(lines)


def main() -> None:
    limit = None
    workers = 6
    for arg in sys.argv[1:]:
        if arg.startswith("--limit="):
            limit = int(arg.split("=", 1)[1])
        if arg.startswith("--workers="):
            workers = int(arg.split("=", 1)[1])

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    lessons = {}
    for category in manifest["categories"]:
        for lesson in category["lessons"]:
            lessons[lesson["id"]] = lesson
    cache = load_cache()
    OUT.mkdir(parents=True, exist_ok=True)
    translated = 0
    for lesson_id in TOP50:
        lesson = lessons.get(lesson_id)
        if lesson is None:
            continue
        target = OUT / f"{lesson_id}.md"
        source = ROOT / lesson["file"]
        text = source.read_text(encoding="utf-8")
        if not target.exists():
            target.write_text(
                translate_markdown(text, cache, workers) + "\n",
                encoding="utf-8",
            )
            save_cache(cache)
            translated += 1
            print(f"translated {lesson_id}", flush=True)
        lesson["file_en"] = f"assets/content_en/{lesson_id}.md"
        if limit and translated >= limit:
            break
    MANIFEST.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    save_cache(cache)
    print(f"done: {translated}")


if __name__ == "__main__":
    main()
