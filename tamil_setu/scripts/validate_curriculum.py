import json
import re
from pathlib import Path


CURRICULUM_PATH = Path("assets/data/curriculum.json")


def _is_non_empty_string(value) -> bool:
    return isinstance(value, str) and value.strip() != ""


def _has_latin_letters(value: str) -> bool:
    return re.search(r"[A-Za-z]", value) is not None


def validate_curriculum(path: Path) -> int:
    errors = []
    seen_ids = set()

    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"ERROR: Failed to parse JSON: {exc}")
        return 1

    if not isinstance(data, list):
        errors.append("Root must be a list of levels.")
        data = []

    for level_index, level in enumerate(data, start=1):
        if not isinstance(level, dict):
            errors.append(f"Level {level_index} must be an object.")
            continue

        level_num = level.get("level")
        if not isinstance(level_num, int):
            errors.append(f"Level {level_index} has invalid 'level'.")

        for key in ("topic", "description"):
            if not _is_non_empty_string(level.get(key)):
                errors.append(
                    f"Level {level_num} missing or empty '{key}'."
                )

        items = level.get("items")
        if not isinstance(items, list) or not items:
            errors.append(f"Level {level_num} has no items.")
            continue

        for item_index, item in enumerate(items, start=1):
            if not isinstance(item, dict):
                errors.append(
                    f"Level {level_num} item {item_index} must be an object."
                )
                continue

            for key in ("hindi", "formal", "spoken", "id"):
                if not _is_non_empty_string(item.get(key)):
                    errors.append(
                        f"Level {level_num} item {item_index} missing '{key}'."
                    )

            item_id = item.get("id")
            if _is_non_empty_string(item_id):
                if item_id in seen_ids:
                    errors.append(
                        f"Duplicate id '{item_id}' at level {level_num}."
                    )
                seen_ids.add(item_id)

            spoken = item.get("spoken", "")
            if "(" in spoken or ")" in spoken:
                errors.append(
                    f"Level {level_num} item {item_index} spoken contains parentheses."
                )
            if _has_latin_letters(spoken):
                errors.append(
                    f"Level {level_num} item {item_index} spoken contains Latin letters."
                )

    if errors:
        print("Validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("Curriculum validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(validate_curriculum(CURRICULUM_PATH))
