#!/usr/bin/env python3
"""
Generate contextual word images for Tamil Setu using Stable Diffusion.

Reads master_content.json, finds words without an image_path, generates
images via the Banana.dev inference API (or a local diffusers pipeline as
fallback), saves them to assets/images/words/<key>.png, and writes the
image_path back into master_content.json.

Usage:
    python scripts/generate_images.py [--lessons 1-10] [--dry-run] [--local]

Requirements:
    pip install requests python-dotenv pyyaml pillow
    For --local: pip install diffusers torch accelerate

Config:
    See scripts/image_generation_config.yaml for SD checkpoint, seed, and
    prompt settings.
    Copy .env.example to .env and set BANANA_API_KEY and BANANA_MODEL_KEY.
"""

import argparse
import base64
import io
import json
import os
import re
import sys
import unicodedata
from pathlib import Path

import requests
import yaml
from dotenv import load_dotenv
from PIL import Image

# ── Paths ─────────────────────────────────────────────────────────────────────
REPO_ROOT = Path(__file__).resolve().parent.parent
CONTENT_JSON = REPO_ROOT / "tamil_setu/assets/data/master_content.json"
IMAGES_DIR = REPO_ROOT / "tamil_setu/assets/images/words"
CONFIG_PATH = Path(__file__).resolve().parent / "image_generation_config.yaml"
ENV_PATH = REPO_ROOT / ".env"

MAX_FILE_SIZE_KB = 50

# ── Helpers ───────────────────────────────────────────────────────────────────

def load_config() -> dict:
    with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def hindi_to_image_key(hindi: str) -> str:
    """
    Derive a snake_case ASCII image key from a Hindi word.
    Uses the portion before '/' (to handle variant forms like 'नमस्ते / हेलो').
    Falls back to NFKD-based ASCII stripping; non-ASCII chars become their
    Unicode name words joined by underscores if all else fails.
    """
    primary = hindi.split("/")[0].strip()
    # Normalise and try to reduce to ASCII
    nfkd = unicodedata.normalize("NFKD", primary)
    ascii_attempt = nfkd.encode("ascii", "ignore").decode("ascii").strip()
    if ascii_attempt:
        key = re.sub(r"[^a-z0-9]+", "_", ascii_attempt.lower()).strip("_")
        return key or "word"
    # If entirely non-ASCII (Devanagari), use Unicode name tokens
    tokens = []
    for char in primary:
        name = unicodedata.name(char, "").lower()
        # e.g. "devanagari letter na" -> "na"
        parts = name.split()
        tokens.extend(p for p in parts if p not in ("devanagari", "letter", "digit", "sign"))
    key = "_".join(t for t in tokens if t)[:60] or "word"
    return re.sub(r"_+", "_", key).strip("_")


def build_prompt(concept_prefix: str, config: dict) -> str:
    base = config["prompt"]["base_suffix"]
    negative = config["prompt"].get("negative_prompt", "")
    return concept_prefix.rstrip(",") + ", " + base, negative


def generate_via_banana(prompt: str, negative_prompt: str, config: dict) -> bytes:
    """Call Banana.dev inference API; returns raw PNG bytes."""
    load_dotenv(ENV_PATH)
    api_key = os.environ.get("BANANA_API_KEY")
    model_key = os.environ.get("BANANA_MODEL_KEY")
    if not api_key or not model_key:
        raise EnvironmentError(
            "BANANA_API_KEY and BANANA_MODEL_KEY must be set in .env"
        )

    payload = {
        "apiKey": api_key,
        "modelKey": model_key,
        "modelInputs": {
            "prompt": prompt,
            "negative_prompt": negative_prompt,
            "num_inference_steps": config["generation"]["steps"],
            "guidance_scale": config["generation"]["guidance_scale"],
            "seed": config["generation"]["seed"],
            "width": config["generation"]["width"],
            "height": config["generation"]["height"],
        },
        "startOnly": False,
    }

    resp = requests.post(
        "https://api.banana.dev/start/v4/",
        json=payload,
        timeout=120,
    )
    resp.raise_for_status()
    data = resp.json()

    # Banana returns base64-encoded image in modelOutputs.image
    b64 = data.get("modelOutputs", [{}])[0].get("image") or data.get("image")
    if not b64:
        raise ValueError(f"Unexpected Banana response: {data}")
    return base64.b64decode(b64)


def generate_via_local(prompt: str, negative_prompt: str, config: dict) -> bytes:
    """Generate using a local diffusers pipeline (CPU/GPU fallback)."""
    try:
        import torch
        from diffusers import StableDiffusionPipeline
    except ImportError:
        print("ERROR: Install diffusers and torch for local generation.")
        sys.exit(1)

    checkpoint = config["generation"]["checkpoint"]
    seed = config["generation"]["seed"]
    w = config["generation"]["width"]
    h = config["generation"]["height"]

    pipe = StableDiffusionPipeline.from_pretrained(
        checkpoint,
        torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32,
    )
    pipe = pipe.to("cuda" if torch.cuda.is_available() else "cpu")
    generator = torch.Generator().manual_seed(seed)

    result = pipe(
        prompt,
        negative_prompt=negative_prompt,
        num_inference_steps=config["generation"]["steps"],
        guidance_scale=config["generation"]["guidance_scale"],
        width=w,
        height=h,
        generator=generator,
    )
    img: Image.Image = result.images[0]
    buf = io.BytesIO()
    img.save(buf, format="PNG", optimize=True)
    return buf.getvalue()


def compress_if_needed(png_bytes: bytes, max_kb: int = MAX_FILE_SIZE_KB) -> bytes:
    """Re-encode with Pillow quantisation if over the size limit."""
    if len(png_bytes) <= max_kb * 1024:
        return png_bytes
    img = Image.open(io.BytesIO(png_bytes)).convert("RGBA")
    # Quantise to 256 colours (palette mode keeps file small)
    quantised = img.quantize(colors=256, method=Image.Quantize.MEDIANCUT)
    buf = io.BytesIO()
    quantised.save(buf, format="PNG", optimize=True)
    result = buf.getvalue()
    if len(result) > max_kb * 1024:
        print(f"  WARNING: still {len(result)//1024} KB after compression (limit {max_kb} KB)")
    return result


# ── Main ──────────────────────────────────────────────────────────────────────

def parse_lesson_range(s: str) -> set[int]:
    levels = set()
    for part in s.split(","):
        part = part.strip()
        if "-" in part:
            lo, hi = part.split("-", 1)
            levels.update(range(int(lo), int(hi) + 1))
        else:
            levels.add(int(part))
    return levels


def main():
    parser = argparse.ArgumentParser(description="Generate word images for Tamil Setu")
    parser.add_argument(
        "--lessons", default=None,
        help="Comma-separated lesson levels or ranges to process (e.g. '1-10' or '1,3,5'). "
             "Default: all lessons."
    )
    parser.add_argument("--dry-run", action="store_true", help="Print prompts without generating")
    parser.add_argument("--local", action="store_true", help="Use local diffusers instead of Banana.dev")
    parser.add_argument("--overwrite", action="store_true", help="Re-generate even if image already exists")
    args = parser.parse_args()

    config = load_config()
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)

    lesson_filter = parse_lesson_range(args.lessons) if args.lessons else None

    with open(CONTENT_JSON, "r", encoding="utf-8") as f:
        lessons = json.load(f)

    modified = False
    generated = 0
    skipped = 0

    for lesson in lessons:
        level = lesson.get("level", 0)
        if lesson_filter and level not in lesson_filter:
            continue

        words = lesson.get("words", [])
        for word in words:
            hindi = word.get("hindi", "")
            existing_path = word.get("image_path")

            if existing_path and not args.overwrite:
                skipped += 1
                continue

            key = hindi_to_image_key(hindi)
            out_path = IMAGES_DIR / f"{key}.png"
            asset_path = f"assets/images/words/{key}.png"

            # Build prompt
            concept_prefix = f"a visual representation of '{hindi.split('/')[0].strip()}'"
            (prompt, negative_prompt) = build_prompt(concept_prefix, config)

            print(f"  L{level} [{hindi}] → {key}.png")
            if args.dry_run:
                print(f"    Prompt: {prompt}")
                print(f"    Negative: {negative_prompt}")
                continue

            try:
                if args.local:
                    png_bytes = generate_via_local(prompt, negative_prompt, config)
                else:
                    png_bytes = generate_via_banana(prompt, negative_prompt, config)

                png_bytes = compress_if_needed(png_bytes)
                out_path.write_bytes(png_bytes)
                size_kb = len(png_bytes) // 1024
                print(f"    Saved ({size_kb} KB)")

                word["image_path"] = asset_path
                modified = True
                generated += 1

            except Exception as exc:
                print(f"    ERROR: {exc}")

    if modified and not args.dry_run:
        with open(CONTENT_JSON, "w", encoding="utf-8") as f:
            json.dump(lessons, f, ensure_ascii=False, indent=2)
        print(f"\nUpdated {CONTENT_JSON.name} with {generated} new image_path entries.")

    print(f"\nDone. Generated: {generated}, Skipped (already had image): {skipped}")


if __name__ == "__main__":
    main()
