## Context

Tamil Setu is an offline-first Flutter app. All lesson content is bundled as JSON assets (`master_content.json`, `sentences.json`) and audio `.mp3` files. The `WordPair` model and `SentenceItem` model carry text and an `audioPath`; neither has any image field today. The `WordCard` widget renders text-only cards in the Learn tab. Flashcard and MCQ quiz views pass `WordPair` data directly — they also have no image awareness.

Images must be bundled (offline-first constraint). No runtime AI image generation. The feature is purely additive — words without images continue to work unchanged.

## Goals / Non-Goals

**Goals:**
- Add an optional `imagePath` string field to `WordPair` and `SentenceItem` (null when absent).
- Update `WordCard` to display the image (if present) as a visual aid above the Hindi text.
- Update `QuizView` (Flashcard) to show the image alongside the Hindi cue before reveal.
- Update `MultipleChoiceQuiz` to show the image with the Hindi prompt.
- Provide a Python audit script that reports coverage (how many words/sentences have images).
- Define a clear naming convention so the asset library can be grown incrementally.

**Non-Goals:**
- Fetching images from the network at runtime.
- AI image generation at app startup or install.
- Automated bulk image assignment (v1 uses manual curation).
- Images in `SentenceBuilderQuiz` (deferred to v2 — sentences are more abstract).
- Changing the SRS/XP/streak logic.

## Decisions

### Decision 1: Bundle images as Flutter assets, generated offline via Stable Diffusion

**Chosen**: Generate all images **offline at build/content-authoring time** using Stable Diffusion (hosted on Banana.dev or run locally), then pre-bundle them in `assets/images/words/` and declare them in `pubspec.yaml`. A consistent prompt style (see Decision 6) ensures visual cohesion across all generated images.

**Alternatives considered**:
- _Remote CDN URLs stored in Firestore_: Would allow serving new images without an app update, but breaks the offline-first guarantee and adds network dependency to core learning flow.
- _Runtime AI generation on-device_: Infeasible — Stable Diffusion models are too large for mobile; adds latency and battery cost.
- _Manual illustration / free-license icon sets (Noun Project, Flaticon)_: Consistent art style is hard to guarantee across different contributors; licensing terms vary per asset.

**Rationale**: Offline-first is a non-negotiable constraint. Generating images at content-authoring time (not at runtime) keeps the app fully offline while still getting high-quality, thematically consistent artwork. Banana.dev provides a simple REST API to Stable Diffusion so generation can be scripted and reproduced.

### Decision 2: Optional `imagePath` field with graceful null fallback

**Chosen**: `imagePath` is `String?` on both `WordPair` and `SentenceItem`. When null, widgets render exactly as today (no empty placeholder box).

**Alternatives considered**:
- _Mandatory field with a generic placeholder image_: Forces polluting every existing JSON entry and shows a visually noisy placeholder where no specific image exists.
- _Separate image lookup table (map of word key → path)_: Adds indirection; the field-on-model approach is simpler and consistent with how `audioPath` works today.

**Rationale**: Keeps the data model self-contained and the migration surface minimal. Words/sentences without images degrade gracefully, enabling incremental rollout.

### Decision 3: Image naming convention — concept key derived from Hindi word

**Chosen**: Snake-case of the primary Hindi word (before `/`), e.g. `नमस्ते` → `namaste.png`. Stored at `assets/images/words/<key>.png`. The `image_path` JSON value is the full asset path string (e.g. `"assets/images/words/namaste.png"`).

**Alternatives considered**:
- _Lesson-scoped names (`l1_namaste.png`)_: Mirrors audio naming but risks duplication when the same concept appears in multiple lessons.
- _Auto-numeric IDs_: Opaque; hard to audit or manually assign.

**Rationale**: Concept-scoped names mirror how the audio files are already named and allow a single image to serve multiple lessons that teach the same word.

### Decision 4: Display position — image above Hindi text in `WordCard`

**Chosen**: Render the image in a fixed-height container (150 dp) with `BoxFit.contain` at the top of the card, above the existing Hindi section.

**Alternatives considered**:
- _Image as card background_: Reduces text legibility.
- _Image below Tamil text_: Less intuitive; learners should see the visual cue first, then decode the target language.

**Rationale**: Image → Hindi cue → Tamil answer creates the correct recall chain. `BoxFit.contain` prevents distortion for images of varying aspect ratios.

### Decision 5: No Firestore schema changes

Images are bundled assets — no Firestore document changes are needed. `imagePath` lives only in the local JSON and in-memory Dart models.

### Decision 6: Stable Diffusion prompt style — flat illustration, warm South Asian palette

**Chosen**: All images are generated with a shared base prompt suffix enforcing a consistent visual theme:
> _"flat vector illustration, warm earthy tones, South Asian cultural context, simple clean background, no text, friendly and approachable, 512×512"_

Each word gets a per-concept prefix (e.g. `"a glass of water,"` for पानी) prepended to this base prompt. A fixed seed range and the same SD checkpoint (e.g. `Realistic Vision` or a flat-illustration fine-tune like `flat2DAnimerge`) is used for all generations so the style is reproducible.

**Script**: `scripts/generate_images.py` will call the Banana.dev inference API (or a local `diffusers` pipeline as fallback), iterate over words in `master_content.json` that lack an `image_path`, generate the image, save it to `assets/images/words/<key>.png`, and write the asset path back into the JSON.

**Rationale**: A shared prompt suffix + fixed checkpoint is the minimal mechanism to keep hundreds of AI-generated images visually coherent without manual design work.

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| App binary size grows significantly if many images are added | Compress all images to ≤50 KB PNG; audit size in CI before release |
| Culturally inappropriate images for some Hindi/Tamil concepts | Manual review of every image before adding to the bundle; maintain a review checklist |
| JSON entries for existing words will not have `image_path` → null handling must be correct | `WordPair.fromJson` already defaults missing fields; null-safety enforced by `String?` type |
| Widget tests may fail if golden files don't account for images | Update/regenerate goldens as part of this change |
| Image sourcing for 300+ words is a long-tail effort | Phase the rollout: start with Lessons 1–10 (most common survival vocabulary) |

## Migration Plan

1. Add `image_path` as optional field in `master_content.json` and `sentences.json` JSON schema (no existing entries are modified, only new entries may have it).
2. Update `WordPair.fromJson` and `SentenceItem.fromJson` to parse `image_path → imagePath` (nullable).
3. Update `WordCard`, `QuizView`, `MultipleChoiceQuiz` to render image if `imagePath != null`.
4. Add `assets/images/words/` to `pubspec.yaml`.
5. Add images for Lessons 1–10 vocabulary (~80 words) as first batch.
6. Run `scripts/generate_image_manifest.py` to confirm coverage.
7. Update/regenerate widget test goldens.

**Rollback**: Because `imagePath` is optional and all existing words have `null`, removing images is as simple as deleting asset files and bumping the app version. No data migration required.

## Open Questions

- **Sentence images**: Sentences are more abstract than words — should scene images for sentences wait for v2, or should a subset (greetings, common actions) be included in v1? → Deferred to v2 per Non-goals.

~~**Image sources**~~: ✅ Resolved — images will be generated offline using **Stable Diffusion via Banana.dev** (or local `diffusers` as fallback), following a consistent flat-illustration prompt style. See Decision 6.
