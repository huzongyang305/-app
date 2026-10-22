"""Generate a compact pinyin lookup table for lesson titles and keywords.

The app only needs pinyin for searchable metadata, not for the full Markdown
body, so generating a small checked-in map keeps the APK overhead low.

Usage (requires pypinyin):
    python tool/generate_pinyin_map.py
"""

from __future__ import annotations

import json
from pathlib import Path

from pypinyin import Style, lazy_pinyin


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "assets" / "content" / "manifest.json"
OUTPUT = ROOT / "lib" / "data" / "pinyin_map.dart"


def collect_text(manifest: dict) -> list[str]:
    values: list[str] = []
    for category in manifest.get("categories", []):
        values.extend((category.get("title") or {}).values())
        for lesson in category.get("lessons", []):
            values.extend((lesson.get("title") or {}).values())
            values.extend((lesson.get("summary") or {}).values())
            values.extend(lesson.get("keywords") or [])
    return [str(item) for item in values if item]


def is_cjk(char: str) -> bool:
    return "\u4e00" <= char <= "\u9fff"


def main() -> None:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    chars = sorted({char for text in collect_text(manifest) for char in text if is_cjk(char)})
    entries: list[tuple[str, str]] = []
    for char in chars:
        syllables = lazy_pinyin(char, style=Style.NORMAL, errors="default")
        if not syllables:
            continue
        value = "".join(syllables).strip().lower()
        if value and value.isascii() and value.isalpha():
            entries.append((char, value))

    lines = [
        "// GENERATED FILE. Run tool/generate_pinyin_map.py to refresh.",
        "// Source data: pypinyin (MIT), covering metadata characters only.",
        "",
        "const Map<String, String> pinyinByCharacter = <String, String>{",
    ]
    for char, value in entries:
        lines.append(f"  '{char}': '{value}',")
    lines.extend(["};", ""])
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote {len(entries)} pinyin entries to {OUTPUT}")


if __name__ == "__main__":
    main()
