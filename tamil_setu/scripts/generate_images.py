#!/usr/bin/env python3
"""
Generate contextual word images for Tamil Setu.

Reads master_content.json, finds words without an image_path, generates
images, saves them to assets/images/words/<key>.png, and writes the
image_path back into master_content.json.

Backends (pick one):
    --gemini   (default) Gemini Nano Banana API — best quality, no GPU needed
    --local    Local Stable Diffusion via diffusers (MPS/CPU)
    --banana   Banana.dev inference API (legacy)

Usage:
    python scripts/generate_images.py [--lessons 1-10] [--dry-run]
    python scripts/generate_images.py --gemini --lessons 1 --overwrite
    python scripts/generate_images.py --local --lessons 1-10

Requirements:
    pip install requests python-dotenv pyyaml pillow
    For --gemini: pip install google-genai
    For --local:  pip install diffusers torch accelerate

Config:
    See scripts/image_generation_config.yaml for prompt settings.
    Set GEMINI_API_KEY in .env (get one at https://aistudio.google.com/apikey).
"""

import argparse
import base64
import io
import json
import os
import re
import sys
import time
from pathlib import Path

import requests
import yaml
from dotenv import load_dotenv
from PIL import Image

# ── Paths ─────────────────────────────────────────────────────────────────────
# __file__ is at tamil_setu/scripts/generate_images.py
# APP_ROOT  → tamil_setu/
# REPO_ROOT → tamil_via_hindi/
APP_ROOT = Path(__file__).resolve().parent.parent
REPO_ROOT = APP_ROOT.parent
CONTENT_JSON = APP_ROOT / "assets/data/master_content.json"
IMAGES_DIR = APP_ROOT / "assets/images/words"
CONFIG_PATH = Path(__file__).resolve().parent / "image_generation_config.yaml"
ENV_PATH = REPO_ROOT / ".env"

MAX_FILE_SIZE_KB = 80
TARGET_SIZE = 256  # Images display at 150 logical px; 256 is crisp at 2x density

# ── Helpers ───────────────────────────────────────────────────────────────────

def load_config() -> dict:
    with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def image_key_from_audio(word: dict) -> str:
    """Derive the image filename stem from the word's audio_path.

    e.g. 'assets/audio/l1_hello.mp3' → 'l1_hello'
    """
    audio = word.get("audio_path", "")
    if not audio:
        raise ValueError(f"Word missing audio_path: {word}")
    return Path(audio).stem


def english_concept(word: dict) -> str:
    """Extract an English concept for prompting from a word entry.

    Priority: explicit 'english' field > English in parentheses > Hindi (with warning).
    """
    # 1. Explicit english field
    if word.get("english"):
        return word["english"]
    # 2. Extract English from parentheses in the hindi field
    hindi = word.get("hindi", "")
    m = re.search(r"\(([A-Za-z][A-Za-z /\-']+)\)", hindi)
    if m:
        return m.group(1).strip()
    # 3. Fallback — warn that Hindi text won't produce good images
    print(f"  WARNING: No English concept for '{hindi}' — SD cannot understand Devanagari.")
    return hindi.split("/")[0].strip()


def build_prompt(concept_prefix: str, config: dict) -> str:
    base = config["prompt"]["base_suffix"]
    negative = config["prompt"].get("negative_prompt", "")
    return concept_prefix.rstrip(",") + ", " + base, negative


def generate_via_gemini(prompt: str, config: dict) -> bytes:
    """Generate an image using the Gemini Nano Banana API; returns raw PNG bytes."""
    try:
        from google import genai
        from google.genai import types
    except ImportError:
        print("ERROR: Install google-genai for Gemini generation:")
        print("  pip install google-genai")
        sys.exit(1)

    load_dotenv(ENV_PATH)
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise EnvironmentError(
            "GEMINI_API_KEY must be set in .env "
            "(get one at https://aistudio.google.com/apikey)"
        )

    model = config.get("gemini", {}).get("model", "gemini-3.1-flash-image-preview")
    client = genai.Client(api_key=api_key)

    max_retries = 3
    # Append size guidance to prompt for smaller file output
    prompt_with_size = prompt + ". Use minimal colors, flat shading, and simple shapes to keep file size small."
    for attempt in range(max_retries):
        try:
            response = client.models.generate_content(
                model=model,
                contents=[prompt_with_size],
                config=types.GenerateContentConfig(
                    response_modalities=["IMAGE"],
                    image_config=types.ImageConfig(
                        aspect_ratio="1:1",
                    ),
                ),
            )

            for part in response.parts:
                if part.inline_data is not None:
                    # inline_data.data is raw image bytes; re-encode as optimised PNG
                    raw = base64.b64decode(part.inline_data.data) if isinstance(part.inline_data.data, str) else part.inline_data.data
                    img = Image.open(io.BytesIO(raw))
                    buf = io.BytesIO()
                    img.save(buf, format="PNG", optimize=True)
                    return buf.getvalue()

            raise ValueError(f"Gemini returned no image. Response: {response.text}")
        except Exception as exc:
            if "429" in str(exc) and attempt < max_retries - 1:
                wait = 15 * (attempt + 1)
                print(f"    Rate limited, waiting {wait}s...")
                time.sleep(wait)
                continue
            raise


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


def generate_via_local(prompt: str, negative_prompt: str, config: dict, pipe=None) -> tuple[bytes, object]:
    """Generate using a local diffusers pipeline (CPU/MPS/GPU).
    Returns (png_bytes, pipe) so the pipe can be reused across calls."""
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

    if pipe is None:
        # Detect best available device (MPS for Apple Silicon, CUDA opt-in via --cuda)
        if hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
            device = "mps"
            dtype = torch.float16
        elif config.get("use_cuda") and torch.cuda.is_available():
            device = "cuda"
            dtype = torch.float16
        else:
            device = "cpu"
            dtype = torch.float32

        print(f"  Loading model {checkpoint} on {device}...")
        pipe = StableDiffusionPipeline.from_pretrained(
            checkpoint,
            torch_dtype=dtype,
        )
        pipe = pipe.to(device)
        # Disable safety checker for illustration-style outputs
        pipe.safety_checker = None
        pipe.requires_safety_checker = False

    device = pipe.device
    if device.type == "mps":
        generator = torch.Generator()
    else:
        generator = torch.Generator(device=device)
    generator.manual_seed(seed)

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
    return buf.getvalue(), pipe


def compress_if_needed(png_bytes: bytes, max_kb: int = MAX_FILE_SIZE_KB) -> bytes:
    """Resize to TARGET_SIZE and re-encode with Pillow optimisation."""
    img = Image.open(io.BytesIO(png_bytes))
    # Resize to target — images display at 150px, 256 is crisp at 2x
    if img.width > TARGET_SIZE or img.height > TARGET_SIZE:
        img = img.resize((TARGET_SIZE, TARGET_SIZE), Image.LANCZOS)
    rgb = img.convert("RGB")
    buf = io.BytesIO()
    rgb.save(buf, format="PNG", optimize=True)
    result = buf.getvalue()
    if len(result) <= max_kb * 1024:
        return result
    # If still too large, quantise to 256 colours
    quantised = rgb.quantize(colors=256, method=Image.Quantize.FASTOCTREE)
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


COMPARE_MODELS = [
    "Fictiverse/Stable_Diffusion_PaperCut_Model",
    "dreamlike-art/dreamlike-diffusion-1.0",
    "runwayml/stable-diffusion-v1-5",
]


def run_compare(lessons, lesson_filter, config):
    """Generate one image per word per model into side-by-side folders."""
    compare_root = APP_ROOT / "assets/images/words_compare"
    compare_root.mkdir(parents=True, exist_ok=True)

    # Collect words to generate
    word_list = []
    for lesson in lessons:
        level = lesson.get("level", 0)
        if lesson_filter and level not in lesson_filter:
            continue
        for word in lesson.get("words", []):
            key = image_key_from_audio(word)
            eng = english_concept(word)
            concept_prefix = f"a visual representation of '{eng}'"
            prompt, negative_prompt = build_prompt(concept_prefix, config)
            word_list.append((level, key, prompt, negative_prompt))

    print(f"\nComparing {len(COMPARE_MODELS)} models × {len(word_list)} words\n")

    for model_id in COMPARE_MODELS:
        short_name = model_id.split("/")[-1]
        model_dir = compare_root / short_name
        model_dir.mkdir(parents=True, exist_ok=True)
        print(f"─── Model: {model_id} ───")

        # Override config checkpoint for this model
        model_config = dict(config)
        model_config["generation"] = dict(config["generation"])
        model_config["generation"]["checkpoint"] = model_id

        pipe = None
        for level, key, prompt, negative_prompt in word_list:
            out_path = model_dir / f"{key}.png"
            print(f"  L{level} → {short_name}/{key}.png")
            try:
                png_bytes, pipe = generate_via_local(prompt, negative_prompt, model_config, pipe=pipe)
                png_bytes = compress_if_needed(png_bytes)
                out_path.write_bytes(png_bytes)
                size_kb = len(png_bytes) // 1024
                print(f"    Saved ({size_kb} KB)")
            except Exception as exc:
                print(f"    ERROR: {exc}")

        # Free memory before loading next model
        del pipe
        try:
            import torch
            if torch.cuda.is_available():
                torch.cuda.empty_cache()
            import gc
            gc.collect()
        except ImportError:
            pass

    print(f"\nDone! Compare images in:\n  {compare_root}/")
    for model_id in COMPARE_MODELS:
        short_name = model_id.split("/")[-1]
        print(f"    {short_name}/")


def main():
    parser = argparse.ArgumentParser(description="Generate word images for Tamil Setu")
    parser.add_argument(
        "--lessons", default=None,
        help="Comma-separated lesson levels or ranges to process (e.g. '1-10' or '1,3,5'). "
             "Default: all lessons."
    )
    parser.add_argument("--dry-run", action="store_true", help="Print prompts without generating")
    parser.add_argument("--overwrite", action="store_true", help="Re-generate even if image already exists")
    parser.add_argument("--compare-models", action="store_true",
                        help="Generate with multiple models for side-by-side comparison (implies --local)")

    backend = parser.add_mutually_exclusive_group()
    backend.add_argument("--gemini", action="store_true", default=True,
                         help="Use Gemini Nano Banana API (default)")
    backend.add_argument("--local", action="store_true",
                         help="Use local Stable Diffusion via diffusers")
    backend.add_argument("--banana", action="store_true",
                         help="Use Banana.dev inference API (legacy)")
    parser.add_argument("--cuda", action="store_true",
                        help="With --local: use CUDA GPU (default: MPS on Apple Silicon)")
    args = parser.parse_args()

    config = load_config()
    config["use_cuda"] = args.cuda

    lesson_filter = parse_lesson_range(args.lessons) if args.lessons else None

    with open(CONTENT_JSON, "r", encoding="utf-8") as f:
        lessons = json.load(f)

    if args.compare_models:
        run_compare(lessons, lesson_filter, config)
        return

    IMAGES_DIR.mkdir(parents=True, exist_ok=True)

    modified = False
    generated = 0
    skipped = 0
    pipe = None  # Reuse across words when --local

    for lesson in lessons:
        level = lesson.get("level", 0)
        if lesson_filter and level not in lesson_filter:
            continue

        words = lesson.get("words", [])
        for word in words:
            existing_path = word.get("image_path")

            if existing_path and not args.overwrite:
                skipped += 1
                continue

            key = image_key_from_audio(word)
            out_path = IMAGES_DIR / f"{key}.png"
            asset_path = f"assets/images/words/{key}.png"

            # Build prompt using English concept (SD can't understand Devanagari)
            eng = english_concept(word)
            concept_prefix = f"a visual representation of '{eng}'"
            (prompt, negative_prompt) = build_prompt(concept_prefix, config)

            print(f"  L{level} → {key}.png")
            if args.dry_run:
                print(f"    Prompt: {prompt}")
                print(f"    Negative: {negative_prompt}")
                continue

            try:
                if args.local:
                    png_bytes, pipe = generate_via_local(prompt, negative_prompt, config, pipe=pipe)
                elif args.banana:
                    png_bytes = generate_via_banana(prompt, negative_prompt, config)
                else:
                    png_bytes = generate_via_gemini(prompt, config)

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
