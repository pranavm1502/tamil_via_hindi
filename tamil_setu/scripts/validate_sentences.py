import json
import re
from pathlib import Path

SENTENCES_PATH = Path("assets/data/sentences.json")


def _is_non_empty_string(value) -> bool:
    return isinstance(value, str) and value.strip() != ""


def _has_latin_letters(value: str) -> bool:
    return re.search(r"[A-Za-z]", value or "") is not None


def _normalize_text(value: str) -> str:
    return re.sub(r"\s+", " ", value.strip())


def validate_sentences(path: Path) -> int:
    errors = []
    seen_keys = set()

    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"ERROR: Failed to parse JSON: {exc}")
        return 1

    if not isinstance(data, list):
        errors.append("Root must be a list of sentences.")
        data = []

    for index, item in enumerate(data, start=1):
        if not isinstance(item, dict):
            errors.append(f"Sentence {index} must be an object.")
            continue

        for key in ("hindi", "tamil", "pronunciation", "audio_path"):
            if not _is_non_empty_string(item.get(key)):
                errors.append(f"Sentence {index} missing '{key}'.")

        tags = item.get("tags")
        if not isinstance(tags, list):
            errors.append(f"Sentence {index} tags must be a list.")

        tamil = item.get("tamil", "")
        pronunciation = item.get("pronunciation", "")
        if _has_latin_letters(tamil):
            errors.append(f"Sentence {index} tamil contains Latin letters.")
        if _has_latin_letters(pronunciation):
            errors.append(
                f"Sentence {index} pronunciation contains Latin letters."
            )

        key = (
            _normalize_text(item.get("hindi", "")),
            _normalize_text(item.get("tamil", "")),
            _normalize_text(item.get("pronunciation", "")),
        )
        if key in seen_keys:
            errors.append(f"Sentence {index} is a duplicate.")
        else:
            seen_keys.add(key)

    if errors:
        print("Validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("Sentence validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(validate_sentences(SENTENCES_PATH))
