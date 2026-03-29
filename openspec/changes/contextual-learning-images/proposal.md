## Why

Visual associations dramatically improve vocabulary retention — learners form dual-coded memories (word + image) that are faster to recall and harder to forget. Tamil Setu currently teaches words entirely through text (Hindi ↔ Tamil script ↔ pronunciation), leaving a proven learning channel untapped. Adding a relatable image per word/sentence aligns with Phase 3 (Learning Depth) goals of deeper language skill transfer.

## What Changes

- Add an optional `image_path` field to `WordPair` (in `master_content.json`) and `SentenceItem` (in `sentences.json`) pointing to a bundled asset.
- Introduce a curated image asset set (`assets/images/words/`) — one PNG per vocabulary concept, sourced or generated and reviewed for cultural relevance to Hindi/Tamil speakers.
- Add a Python script (`scripts/generate_image_manifest.py`) to audit which words have images and flag gaps.
- Update the `WordCard` widget to display the contextual image above the Hindi/Tamil text in the Learn tab.
- Update the `QuizView` (Flashcard tab) to show the image as a visual cue before the user reveals the answer.
- Update `MultipleChoiceQuiz` to show the image alongside the Hindi prompt.
- Sentences in `SentenceBuilderQuiz` may optionally show a scene image.

## Capabilities

### New Capabilities
- `word-image-assets`: Asset pipeline — image naming conventions, directory layout, `imagePath` field in data models (`WordPair`, `SentenceItem`), and the audit/manifest script.
- `image-enhanced-learning`: UI layer — displaying contextual images in `WordCard` (Learn tab), `QuizView` (Flashcard), and `MultipleChoiceQuiz` screens with graceful fallback when no image exists.

### Modified Capabilities
<!-- No existing specs are changing their requirements -->

## Non-goals

- Real-time image generation via an AI API at runtime (images are pre-bundled, offline-first).
- Images for every one of the 300+ sentences (only priority sentences get images in v1).
- Animated images or GIFs.
- User-uploaded or community-sourced images.

## Impact

- **Data**: `master_content.json` and `sentences.json` gain an optional `image_path` string field; `WordPair` and `SentenceItem` Dart models updated accordingly.
- **Assets**: New `assets/images/words/` directory; `pubspec.yaml` updated to include new asset folder.
- **UI Widgets**: `WordCard`, `QuizView`, `MultipleChoiceQuiz` (potentially `SentenceBuilderQuiz`) updated.
- **Scripts**: New `scripts/generate_image_manifest.py` audit tool.
- **Tests**: Existing widget tests may need golden updates; new tests for image display/fallback logic.
- **App size**: Increases proportionally with image count — images should be compressed PNGs (≤50 KB each).
