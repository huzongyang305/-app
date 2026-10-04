"""使用 Argos CTranslate2 模型离线生成 Top 50 完整英文正文。

用法：
    python tool/translate_top50_argos.py <argos_model_root>

模型根目录需要包含 model/model.bin 和 sentencepiece.model。
输出：assets/content_en/<lesson_id>.md
"""

from __future__ import annotations

import ctranslate2
import sentencepiece as spm
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import translate_top50_offline as base  # noqa: E402

ROOT = Path(".")
MANIFEST = ROOT / "assets" / "content" / "manifest.json"
OUT = ROOT / "assets" / "content_en"


class ArgosTranslator:
    def __init__(self, model_root: Path) -> None:
        self.translator = ctranslate2.Translator(
            str(model_root / "model"),
            device="cpu",
            compute_type="int8",
        )
        self.sp = spm.SentencePieceProcessor(
            model_file=str(model_root / "sentencepiece.model")
        )

    def translate_many(self, texts: list[str]) -> list[str]:
        if not texts:
            return []
        token_lists = [
            self.sp.encode(text, out_type=str) + ["</s>"] for text in texts
        ]
        results = self.translator.translate_batch(
            token_lists,
            beam_size=4,
            max_batch_size=32,
            replace_unknowns=True,
            no_repeat_ngram_size=3,
            repetition_penalty=1.2,
            max_decoding_length=256,
        )
        output = []
        for result in results:
            text = self.sp.decode(result.hypotheses[0])
            text = text.replace("▁", " ").replace(" ##", "").strip()
            output.append(text)
        return output


def main() -> None:
    if len(sys.argv) < 2:
        print("usage: translate_top50_argos.py <argos_model_root>")
        raise SystemExit(1)
    model_root = Path(sys.argv[1])
    manifest = base.json.loads(MANIFEST.read_text(encoding="utf-8"))
    lessons = {}
    for category in manifest["categories"]:
        for lesson in category["lessons"]:
            lessons[lesson["id"]] = lesson

    translator = ArgosTranslator(model_root)
    OUT.mkdir(parents=True, exist_ok=True)
    done = 0
    for lesson_id in base.TOP50:
        lesson = lessons.get(lesson_id)
        if lesson is None:
            continue
        source = ROOT / lesson["file"]
        target = OUT / f"{lesson_id}.md"
        target.write_text(
            base.translate_markdown(
                translator,
                source.read_text(encoding="utf-8"),
            )
            + "\n",
            encoding="utf-8",
        )
        lesson["file_en"] = f"assets/content_en/{lesson_id}.md"
        done += 1
        print(f"translated {lesson_id}", flush=True)
    MANIFEST.write_text(
        base.json.dumps(manifest, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"done: {done}")


if __name__ == "__main__":
    main()
