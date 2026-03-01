import json
import os
import time
from pathlib import Path
from gtts import gTTS

SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
ASSETS_DIR = PROJECT_ROOT / "assets"
DATA_FILE = ASSETS_DIR / "data" / "sentences.json"
AUDIO_DIR = ASSETS_DIR / "audio"


def _clean_tamil(value: str) -> str:
    return value.replace("/", " ").strip()


def _normalized_key(item: dict) -> str:
    return "|".join(
        [
            item.get("hindi", "").strip(),
            item.get("tamil", "").strip(),
            item.get("pronunciation", "").strip(),
        ]
    )


def _dedupe(items: list) -> list:
    merged = {}
    for item in items:
        key = _normalized_key(item)
        if key not in merged:
            merged[key] = item
            continue

        existing = merged[key]
        tags = set(existing.get("tags", [])) | set(item.get("tags", []))
        existing["tags"] = sorted(tags)
        if not existing.get("audio_path") and item.get("audio_path"):
            existing["audio_path"] = item.get("audio_path")

    return list(merged.values())


def generate_assets(overwrite_audio: bool) -> int:
    if not DATA_FILE.exists():
        print(f"Missing {DATA_FILE}")
        return 1

    AUDIO_DIR.mkdir(parents=True, exist_ok=True)

    data = json.loads(DATA_FILE.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        print("Sentences JSON must be a list.")
        return 1

    data = _dedupe(data)

    updated = []
    for index, item in enumerate(data, start=1):
        tamil = _clean_tamil(item.get("tamil", ""))
        if not tamil:
            continue

        audio_filename = item.get("audio_path", "").replace("assets/audio/", "")
        if not audio_filename:
            audio_filename = f"sent_{index:04d}.mp3"
            item["audio_path"] = f"assets/audio/{audio_filename}"

        audio_path = AUDIO_DIR / audio_filename
        if overwrite_audio or not audio_path.exists():
            try:
                tts = gTTS(text=tamil, lang="ta", slow=False)
                tts.save(str(audio_path))
                time.sleep(0.4)
            except Exception as exc:
                print(f"Audio failed for {audio_filename}: {exc}")

        updated.append(item)

    DATA_FILE.write_text(
        json.dumps(updated, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"Generated {len(updated)} sentence assets.")
    return 0


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Generate sentence assets.")
    parser.add_argument(
        "--overwrite-audio",
        action="store_true",
        help="Regenerate audio files even if they already exist.",
    )
    args = parser.parse_args()
    raise SystemExit(generate_assets(overwrite_audio=args.overwrite_audio))
