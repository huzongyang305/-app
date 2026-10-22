"""使用 CTranslate2 + SentencePiece 离线生成 Top 50 英文正文。

用法：
    python tool/translate_top50_offline.py <model_dir>

模型目录需要包含 model.bin、config.json、source.spm、target.spm。
输出：assets/content_en/<lesson_id>.md
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

import ctranslate2
import sentencepiece as spm

ROOT = Path(".")
MANIFEST = ROOT / "assets" / "content" / "manifest.json"
OUT = ROOT / "assets" / "content_en"

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


class Translator:
    def __init__(self, model_dir: Path) -> None:
        self.translator = ctranslate2.Translator(
            str(model_dir), device="cpu", compute_type="int8"
        )
        self.source = spm.SentencePieceProcessor(str(model_dir / "source.spm"))
        self.target = spm.SentencePieceProcessor(str(model_dir / "target.spm"))

    def translate(self, text: str) -> str:
        if not text.strip() or not has_cjk(text):
            return text
        tokens = self.source.encode(text, out_type=str)
        results = self.translator.translate_batch(
            [tokens],
            beam_size=1,
            max_batch_size=16,
            replace_unknowns=True,
            no_repeat_ngram_size=3,
            repetition_penalty=1.15,
            max_decoding_length=256,
        )
        return self.target.decode(results[0].hypotheses[0]).strip()

    def translate_chunks(self, text: str) -> str:
        parts = re.split(r"(?<=[。！？!?；;])", text)
        translated = []
        for part in parts:
            if not part:
                continue
            translated.append(self.translate(part))
        return "".join(translated)

    def translate_many(self, texts: list[str]) -> list[str]:
        if not texts:
            return []
        token_lists = [self.source.encode(text, out_type=str) for text in texts]
        results = self.translator.translate_batch(
            token_lists,
            beam_size=1,
            max_batch_size=32,
            replace_unknowns=True,
            no_repeat_ngram_size=3,
            repetition_penalty=1.15,
            max_decoding_length=256,
        )
        return [
            self.target.decode(result.hypotheses[0]).strip()
            for result in results
        ]


def protect_inline(text: str) -> tuple[str, list[str]]:
    protected = []

    def replace(match: re.Match) -> str:
        protected.append(match.group(0))
        return f"⟦{len(protected) - 1}⟧"

    pattern = re.compile(r"`[^`]+`|https?://\S+|\[[^\]]+\]\([^)]+\)")
    return pattern.sub(replace, text), protected


def restore_inline(text: str, protected: list[str]) -> str:
    for index, value in enumerate(protected):
        text = text.replace(f"⟦{index}⟧", value)
    return text


def translate_markdown(translator: Translator, text: str) -> str:
    lines = text.splitlines()
    output = list(lines)
    line_items: dict[int, tuple[str, str, list[str]]] = {}
    table_items: dict[tuple[int, int], tuple[str, list[str]]] = {}
    chunk_texts: list[str] = []
    chunk_owner: list[tuple[str, object]] = []
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
                table_items[(line_index, cell_index)] = (protected, values)
                for part in split_chunks(protected):
                    chunk_owner.append(("table", (line_index, cell_index)))
                    chunk_texts.append(part)
            continue
        match = re.match(r"^(\s*(?:#{1,6}|[-*+]|\d+\.)\s+)(.*)$", line)
        if match:
            protected, values = protect_inline(match.group(2))
            line_items[line_index] = (match.group(1), protected, values)
        else:
            protected, values = protect_inline(line)
            line_items[line_index] = ("", protected, values)
        for part in split_chunks(protected):
            chunk_owner.append(("line", line_index))
            chunk_texts.append(part)

    translated_chunks = translator.translate_many(chunk_texts)
    assembled: dict[object, list[str]] = {}
    for owner, value in zip(chunk_owner, translated_chunks):
        key = ("table", owner[1]) if owner[0] == "table" else owner[1]
        assembled.setdefault(key, []).append(value)

    for line_index, (prefix, _protected, values) in line_items.items():
        translated = restore_inline("".join(assembled.get(line_index, [])), values)
        output[line_index] = prefix + translated
    for line_index in sorted({key[0] for key in table_items}):
        cells = output[line_index].split("|")
        for cell_index in range(len(cells)):
            item = table_items.get((line_index, cell_index))
            if item is None:
                continue
            _protected, values = item
            translated = restore_inline(
                "".join(assembled.get(("table", (line_index, cell_index)), [])),
                values,
            )
            cells[cell_index] = translated
        output[line_index] = "|".join(cells)
    return "\n".join(output)


def split_chunks(text: str, max_length: int = 80) -> list[str]:
    if len(text) <= max_length:
        return [text]
    parts = re.split(r"(?<=[。！？!?；;])", text)
    chunks: list[str] = []
    current = ""
    for part in parts:
        if current and len(current) + len(part) > max_length:
            chunks.append(current)
            current = part
        else:
            current += part
    if current:
        chunks.append(current)
    return chunks


def main() -> None:
    if len(sys.argv) < 2:
        print("usage: translate_top50_offline.py <model_dir>")
        raise SystemExit(1)
    model_dir = Path(sys.argv[1])
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    lessons = {}
    for category in manifest["categories"]:
        for lesson in category["lessons"]:
            lessons[lesson["id"]] = lesson
    translator = Translator(model_dir)
    OUT.mkdir(parents=True, exist_ok=True)
    translated = 0
    for lesson_id in TOP50:
        lesson = lessons.get(lesson_id)
        if lesson is None:
            continue
        target = OUT / f"{lesson_id}.md"
        if target.exists():
            continue
        source = ROOT / lesson["file"]
        text = source.read_text(encoding="utf-8")
        target.write_text(
            translate_markdown(translator, text) + "\n",
            encoding="utf-8",
        )
        lesson["file_en"] = f"assets/content_en/{lesson_id}.md"
        translated += 1
        print(f"translated {lesson_id}")
    MANIFEST.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"done: {translated}")


if __name__ == "__main__":
    main()
