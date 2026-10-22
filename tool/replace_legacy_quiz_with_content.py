"""把旧版模板测验题替换成从教程正文提炼的真实复习题。

P0 解决了题型字段和交互问题；P1 继续处理这些模板题的内容质量问题：
每题都不再问“学习闭环应该怎么填空”，而是回到对应 Markdown 的
“一句话入门 / 动手练习 / 最小示例 / 常见错误”等章节，生成可核对答案。
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "assets" / "content" / "manifest.json"

TEMPLATE_MARKERS = {
    "练习闭环应该怎么填空": "intro",
    "正确的操作顺序是": "practice",
    "最小示例，预期输出是什么": "code",
    "最容易出现的错误是": "common",
}

SECTION_ALIASES = {
    "intro": ("一句话入门", "一句话说明", "一句话目标", "核心定义"),
    "practice": ("动手练习", "专属练习设计", "练习", "实操任务"),
    "common": (
        "常见坑与排查",
        "常见错误对照表",
        "常见错误",
        "常见误区",
        "易错点",
    ),
}

LANGUAGE_LABELS = {
    "python": "Python",
    "javascript": "JavaScript",
    "js": "JavaScript",
    "typescript": "TypeScript",
    "ts": "TypeScript",
    "cpp": "C++",
    "c++": "C++",
    "c": "C",
    "csharp": "C#",
    "cs": "C#",
    "java": "Java",
    "kotlin": "Kotlin",
    "swift": "Swift",
    "go": "Go",
    "rust": "Rust",
    "shell": "Shell",
    "bash": "Shell",
    "sql": "SQL",
    "html": "HTML",
    "css": "CSS",
    "json": "JSON",
    "yaml": "YAML",
    "yml": "YAML",
    "dart": "Dart",
    "text": "文本说明",
    "markdown": "Markdown",
}


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def save_json(path: Path, data) -> None:
    path.write_text(
        json.dumps(data, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )


def clean_text(value: str) -> str:
    text = value.strip()
    text = re.sub(r"!\[[^\]]*\]\([^)]+\)", "", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    text = text.replace("**", "").replace("__", "").replace("`", "")
    text = re.sub(r"^[-*+]\s+", "", text)
    text = re.sub(r"^\d+[.)]\s+", "", text)
    text = re.sub(r"^>\s*", "", text)
    text = re.sub(r"\s+", " ", text).strip()
    if len(text) > 180:
        cut = max(text.find(mark) for mark in ("。", "；", "！", "？")) if any(
            mark in text[:180] for mark in ("。", "；", "！", "？")
        ) else -1
        text = text[: cut + 1 if cut >= 0 else 180].strip()
    return text


def extract_section(markdown: str, aliases: tuple[str, ...]) -> str:
    lines = markdown.splitlines()
    for index, line in enumerate(lines):
        if not line.startswith("## "):
            continue
        heading = line[3:].strip()
        if not any(alias in heading for alias in aliases):
            continue
        body: list[str] = []
        for next_line in lines[index + 1 :]:
            if next_line.startswith("## "):
                break
            body.append(next_line)
        for raw in body:
            item = raw.strip()
            if not item or item.startswith(("```", "<!--", "|", "![")):
                continue
            if item.startswith(("- ", "* ", "+ ")) or re.match(r"^\d+[.)]\s+", item):
                return clean_text(item)
        for raw in body:
            item = clean_text(raw)
            if item and not item.startswith(("```", "<!--", "|")):
                return item
    return ""


def extract_first_code_language(markdown: str) -> str:
    languages = re.findall(r"^```([A-Za-z0-9_+#.-]+)", markdown, flags=re.MULTILINE)
    for language in languages:
        key = language.lower()
        if key not in {"text", "markdown"}:
            return LANGUAGE_LABELS.get(key, language)
    return LANGUAGE_LABELS.get(languages[0].lower(), "文本说明") if languages else "文本说明"


def lesson_sources(lesson: dict) -> dict[str, str]:
    markdown = (ROOT / lesson["file"]).read_text(encoding="utf-8")
    summary = clean_text(lesson.get("summary", {}).get("zh", ""))
    return {
        "intro": extract_section(markdown, SECTION_ALIASES["intro"]) or summary,
        "practice": extract_section(markdown, SECTION_ALIASES["practice"]) or summary,
        "code": extract_first_code_language(markdown),
        "common": extract_section(markdown, SECTION_ALIASES["common"]) or summary,
    }


def option_pool(
    lesson: dict,
    slot: str,
    all_sources: dict[str, dict[str, str]],
    category_id: str,
    categories_by_id: dict[str, set[str]],
) -> list[str]:
    candidates: list[str] = []
    for other_id in categories_by_id.get(category_id, set()):
        if other_id == lesson["id"]:
            continue
        value = all_sources.get(other_id, {}).get(slot, "")
        if value:
            candidates.append(value)
    if len(candidates) < 3:
        for other_id, sources in all_sources.items():
            if other_id == lesson["id"]:
                continue
            value = sources.get(slot, "")
            if value:
                candidates.append(value)
    unique: list[str] = []
    for value in candidates:
        if value not in unique:
            unique.append(value)
    return unique


def question_data(slot: str, lesson: dict, correct: str) -> tuple[str, str]:
    title = lesson["title"]["zh"]
    if slot == "intro":
        return (
            f"《{title}》的“一句话入门”最接近哪一项？",
            "这道题来自本课正文的开篇定义。正确项直接概括了课程主题，其他选项来自其他知识点的定义，不能回答本课的具体问题。复习时先用自己的话复述这句话，再回到最小示例验证理解。",
        )
    if slot == "practice":
        return (
            f"《{title}》的“动手练习”首先要求做什么？",
            "这道题来自本课练习步骤。正确项对应正文中列出的第一项动手任务，其他选项虽然也是学习动作，但缺少本课要求的输入、步骤或观察目标。做完练习后应记录预测结果和实际输出的差异。",
        )
    if slot == "code":
        return (
            f"《{title}》的“最小示例”主要使用哪种语言或格式？",
            "代码块的语言标记决定了示例的运行方式和复习工具。正确项来自本课最小示例的围栏标记，其他选项来自其他课程或输出说明。阅读代码题时要先确认语言、输入、预期输出，再判断运行环境。",
        )
    return (
        f"《{title}》的“常见错误/误区”提醒优先检查什么？",
        "这道题来自本课的排错清单。正确项是正文强调的检查点，其他选项把排错方向引向无关细节。遇到错误时应先复现最小案例，只改变一个变量，检查输入、环境、边界和错误信息，再继续修改。",
    )


def apply_content_replacements(manifest: dict) -> int:
    categories = manifest.get("categories", [])
    all_sources: dict[str, dict[str, str]] = {}
    categories_by_id: dict[str, set[str]] = {}
    lesson_by_id: dict[str, dict] = {}
    for category in categories:
        ids: set[str] = set()
        for lesson in category.get("lessons", []):
            lesson_by_id[lesson["id"]] = lesson
            ids.add(lesson["id"])
            all_sources[lesson["id"]] = lesson_sources(lesson)
        categories_by_id[category["id"]] = ids

    targets: list[tuple[dict, int, str, str]] = []
    for category in categories:
        for lesson in category.get("lessons", []):
            for index, question in enumerate(lesson.get("quiz", [])):
                text = question.get("question", "")
                for marker, slot in TEMPLATE_MARKERS.items():
                    if marker in text:
                        targets.append((lesson, index, slot, category["id"]))
                        break

    target_index = 0
    for lesson, question_index, slot, category_id in targets:
        sources = all_sources[lesson["id"]]
        correct = sources.get(slot) or clean_text(lesson.get("summary", {}).get("zh", ""))
        pool = option_pool(
            lesson,
            slot,
            all_sources,
            category_id,
            categories_by_id,
        )
        distractors = [value for value in pool if value and value != correct][:3]
        fallbacks = [
            "只记住术语名称，不运行最小示例",
            "只看最终结果，不记录预测与差异",
            "跳过边界输入，直接用正常样例代替验证",
        ] if slot != "code" else ["JSON", "SQL", "Shell"]
        for fallback in fallbacks:
            if len(distractors) >= 3:
                break
            if fallback != correct and fallback not in distractors:
                distractors.append(fallback)

        question, explanation = question_data(slot, lesson, correct)
        target_answer = target_index % 4
        target_index += 1
        options = list(distractors[:3])
        options.insert(target_answer, correct)
        quiz = lesson["quiz"]
        quiz[question_index] = {
            "question": question,
            "options": options,
            "answer": target_answer,
            "explanation": (
                f"{explanation}本题正确项是「{correct}」。"
                f"复习《{lesson['title']['zh']}》时，把这一条写进自己的复述，"
                "再用原文示例或练习做一次验证；如果仍说不清，就回到对应章节。"
            ),
            "type": "single",
        }

    return len(targets)


def main() -> None:
    manifest = load_json(MANIFEST)
    replaced = apply_content_replacements(manifest)
    manifest["p1_quiz_version"] = 1
    save_json(MANIFEST, manifest)
    print(f"content_replaced={replaced}")


if __name__ == "__main__":
    main()