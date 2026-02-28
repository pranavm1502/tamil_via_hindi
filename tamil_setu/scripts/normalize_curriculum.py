import argparse
import json
import re
from pathlib import Path


def _clean_spoken(value: str) -> str:
    # Remove any romanization in parentheses and normalize spacing.
    cleaned = re.sub(r"\s*\([^)]*\)", "", value).strip()
    cleaned = re.sub(r"\s*/\s*", " / ", cleaned)
    cleaned = re.sub(r"\s+", " ", cleaned)
    return cleaned


def normalize_curriculum(input_path: Path, output_path: Path) -> int:
    with input_path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)

    updated = 0
    for level in data:
        for item in level.get("items", []):
            spoken = item.get("spoken", "")
            cleaned = _clean_spoken(spoken)
            if cleaned != spoken:
                item["spoken"] = cleaned
                updated += 1

    with output_path.open("w", encoding="utf-8") as handle:
        json.dump(data, handle, ensure_ascii=False, indent=2)
        handle.write("\n")

    return updated


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Normalize curriculum spoken fields by removing romanization."
    )
    parser.add_argument(
        "--input",
        default="assets/data/curriculum.json",
        help="Path to curriculum.json",
    )
    parser.add_argument(
        "--output",
        default="assets/data/curriculum.json",
        help="Path to write normalized curriculum.json",
    )
    args = parser.parse_args()

    input_path = Path(args.input)
    output_path = Path(args.output)

    updated = normalize_curriculum(input_path, output_path)
    print(f"Normalized {updated} spoken entries.")


if __name__ == "__main__":
    main()
