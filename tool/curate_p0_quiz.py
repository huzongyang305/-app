"""把模板化特殊题型降级，并写入一组可真实作答的 P0 题目。

执行方式（项目根目录）：
    python tool/curate_p0_quiz.py

脚本只修改 assets/content/manifest.json，不联网、不删除课程，通常可重复执行。
"""

from __future__ import annotations

import json
from pathlib import Path

from replace_legacy_quiz_with_content import apply_content_replacements

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "assets" / "content" / "manifest.json"
QUESTIONS = ROOT / "tool" / "p0_quiz_questions.json"

TEMPLATE_MARKERS = (
    "练习闭环应该怎么填空",
    "正确的操作顺序是",
    "最小示例，预期输出是什么",
    "最容易出现的错误是",
)


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def save_json(path: Path, data) -> None:
    path.write_text(
        json.dumps(data, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )


def lesson_map(manifest: dict) -> dict[str, dict]:
    result: dict[str, dict] = {}
    for category in manifest.get("categories", []):
        for lesson in category.get("lessons", []):
            result[lesson["id"]] = lesson
    return result


def demote_template_questions(manifest: dict) -> int:
    changed = 0
    for category in manifest.get("categories", []):
        for lesson in category.get("lessons", []):
            for question in lesson.get("quiz", []):
                text = question.get("question", "")
                question_type = question.get("type", "single")
                is_template = question_type in {"fill", "order", "code", "debug"} and any(
                    marker in text for marker in TEMPLATE_MARKERS
                )
                # 缺失新字段的旧题无法安全地按新交互判分，统一降级为单选。
                is_legacy_fill = question_type == "fill" and not question.get("accepted_answers")
                is_legacy_order = question_type == "order" and not question.get("correct_order")
                # 旧版 multi 实际上仍是单选，只有提供 answers 数组才算真正多选。
                is_fake_multi = question_type == "multi" and not question.get("answers")
                if is_template or is_legacy_fill or is_legacy_order or is_fake_multi:
                    question["type"] = "single"
                    for key in (
                        "accepted_answers",
                        "correct_order",
                        "language",
                        "expected_output",
                    ):
                        question.pop(key, None)
                    if is_template:
                        question.pop("code", None)
                    changed += 1
    return changed


def choose_question_index(lesson: dict, question_type: str) -> int:
    quiz = lesson.get("quiz", [])
    if not quiz:
        return -1
    for index, question in enumerate(quiz):
        if question.get("type", "single") == question_type:
            return index
    # 没有同题型时替换最后一题，保证课程原有题量不增加也不减少。
    return len(quiz) - 1


def apply_curated_questions(manifest: dict, curated: list[dict]) -> int:
    by_id = lesson_map(manifest)
    changed = 0
    for question in curated:
        lesson_id = question["lesson_id"]
        lesson = by_id.get(lesson_id)
        if lesson is None:
            raise SystemExit(f"lesson not found: {lesson_id}")
        index = choose_question_index(lesson, question["type"])
        if index < 0:
            raise SystemExit(f"lesson has no quiz: {lesson_id}")
        lesson["quiz"][index] = {
            key: value for key, value in question.items() if key != "lesson_id"
        }
        changed += 1
    return changed


def main() -> None:
    manifest = load_json(MANIFEST)
    curated = load_json(QUESTIONS)
    demoted = demote_template_questions(manifest)
    inserted = apply_curated_questions(manifest, curated)
    replaced = apply_content_replacements(manifest)
    manifest["p0_quiz_version"] = 1
    manifest["p1_quiz_version"] = 1
    save_json(MANIFEST, manifest)
    print(f"demoted={demoted} curated={inserted} content_replaced={replaced}")


if __name__ == "__main__":
    main()