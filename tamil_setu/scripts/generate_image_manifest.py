#!/usr/bin/env python3
"""
Tamil Setu — Image Coverage Audit Script

Reads master_content.json and sentences.json, reports per-lesson image
coverage, and flags any image_path entries whose files are missing on disk.

Usage:
    python scripts/generate_image_manifest.py

Exit codes:
    0 — all referenced image files exist (or no images referenced yet)
    1 — one or more broken references found
"""

import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
CONTENT_JSON = REPO_ROOT / "tamil_setu/assets/data/master_content.json"
SENTENCES_JSON = REPO_ROOT / "tamil_setu/assets/data/sentences.json"
IMAGES_DIR = REPO_ROOT / "tamil_setu/assets/images/words"

# Asset paths in JSON are Flutter asset paths (relative to pubspec.yaml's
# package root, i.e. the tamil_setu/ folder).
ASSET_ROOT = REPO_ROOT / "tamil_setu"


def resolve_asset(asset_path: str) -> Path:
    return ASSET_ROOT / asset_path


def check_words(lessons: list) -> tuple[int, int, list[str]]:
    """Returns (with_image, without_image, broken_references)."""
    broken = []
    total_with = 0
    total_without = 0

    print("=" * 60)
    print("LESSONS (master_content.json)")
    print("=" * 60)

    for lesson in lessons:
        level = lesson.get("level", "?")
        title = lesson.get("title", "")
        words = lesson.get("words", [])
        with_img = 0
        without_img = 0
        lesson_broken = []

        for word in words:
            image_path = word.get("image_path")
            if image_path:
                resolved = resolve_asset(image_path)
                if not resolved.exists():
                    lesson_broken.append(image_path)
                    broken.append(f"L{level} '{word.get('hindi', '')}' → {image_path}")
                with_img += 1
            else:
                without_img += 1

        total_with += with_img
        total_without += without_img
        coverage = f"{with_img}/{with_img + without_img}"
        flag = " ⚠ BROKEN REFS" if lesson_broken else ""
        print(f"  L{level:>2} {title:<30} {coverage} words with image{flag}")
        for b in lesson_broken:
            print(f"       MISSING FILE: {b}")

    print()
    print(f"  Total words with image:    {total_with}")
    print(f"  Total words without image: {total_without}")
    print(f"  Coverage: {total_with}/{total_with + total_without} "
          f"({100*total_with//(total_with+total_without) if total_with+total_without else 0}%)")
    return total_with, total_without, broken


def check_sentences(sentences: list) -> list[str]:
    """Returns broken_references list."""
    broken = []
    with_img = 0
    without_img = 0

    print()
    print("=" * 60)
    print("SENTENCES (sentences.json)")
    print("=" * 60)

    for sentence in sentences:
        image_path = sentence.get("image_path")
        if image_path:
            resolved = resolve_asset(image_path)
            if not resolved.exists():
                broken.append(f"'{sentence.get('hindi', '')}' → {image_path}")
            with_img += 1
        else:
            without_img += 1

    print(f"  Sentences with image:    {with_img}")
    print(f"  Sentences without image: {without_img}")
    if broken:
        print(f"  MISSING FILES ({len(broken)}):")
        for b in broken:
            print(f"    MISSING: {b}")
    return broken


def check_orphaned_images(all_referenced: set[str]) -> list[str]:
    """Find image files in words/ that aren't referenced by any content."""
    orphans = []
    if IMAGES_DIR.exists():
        for f in IMAGES_DIR.iterdir():
            if f.suffix.lower() == ".png":
                asset_path = f"assets/images/words/{f.name}"
                if asset_path not in all_referenced:
                    orphans.append(asset_path)
    return orphans


def main():
    with open(CONTENT_JSON, "r", encoding="utf-8") as f:
        lessons = json.load(f)
    with open(SENTENCES_JSON, "r", encoding="utf-8") as f:
        sentences = json.load(f)

    _, _, word_broken = check_words(lessons)
    sentence_broken = check_sentences(sentences)

    # Collect all referenced paths for orphan check
    all_referenced = set()
    for lesson in lessons:
        for word in lesson.get("words", []):
            p = word.get("image_path")
            if p:
                all_referenced.add(p)
    for sentence in sentences:
        p = sentence.get("image_path")
        if p:
            all_referenced.add(p)

    orphans = check_orphaned_images(all_referenced)
    if orphans:
        print()
        print("=" * 60)
        print("ORPHANED IMAGES (in assets/images/words/ but unreferenced)")
        print("=" * 60)
        for o in orphans:
            print(f"  {o}")

    all_broken = word_broken + sentence_broken
    print()
    if all_broken:
        print(f"RESULT: {len(all_broken)} broken reference(s) found. Fix before building.")
        for b in all_broken:
            print(f"  ✗ {b}")
        sys.exit(1)
    else:
        print("RESULT: All referenced image files exist. ✓")
        sys.exit(0)


if __name__ == "__main__":
    main()
