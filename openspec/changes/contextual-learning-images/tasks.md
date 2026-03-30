## 1. Data Model — Add imagePath field

- [x] 1.1 Add optional `imagePath` (`String?`) field to `lib/models/word_pair.dart` and update `WordPair.fromJson` to parse `image_path` (nullable)
- [x] 1.2 Add optional `imagePath` (`String?`) field to `lib/models/sentence_item.dart` and update `SentenceItem.fromJson` to parse `image_path` (nullable)
- [x] 1.3 Update `assets/data/curriculum.schema.json` and `assets/data/sentences.schema.json` to declare `image_path` as an optional string property
- [x] 1.4 Write unit tests in `test/models/` that verify: (a) `imagePath` is populated when `image_path` is present in JSON, (b) `imagePath` is null when key is absent, (c) `imagePath` is null when JSON value is null

## 2. Asset Infrastructure

- [x] 2.1 Create the `assets/images/words/` directory (add a `.gitkeep` to commit it)
- [x] 2.2 Add `assets/images/words/` to the `flutter > assets` section of `pubspec.yaml`
- [x] 2.3 Create `scripts/generate_images.py`: reads words from `master_content.json` that lack `image_path`, constructs a per-word Stable Diffusion prompt using the shared base suffix (`"flat vector illustration, warm earthy tones, South Asian cultural context, simple clean background, no text, friendly and approachable, 512x512"`), calls Banana.dev inference API (with local `diffusers` pipeline as fallback), saves output to `assets/images/words/<key>.png`, and writes the `image_path` back into `master_content.json`
- [x] 2.4 Configure the script: store the Banana.dev API key in a `.env` file (gitignored); document the SD checkpoint and fixed seed in a `scripts/image_generation_config.yaml` so generations are reproducible
- [ ] 2.5 Run `scripts/generate_images.py` for Lessons 1–10 vocabulary (~80 words); review generated images for cultural appropriateness and compress any that exceed 50 KB (e.g. using `pngquant`)
- [ ] 2.6 Verify all referenced image files exist on disk and build `flutter build apk --debug` to confirm assets are bundled

## 3. Audit Script

- [x] 3.1 Create `scripts/generate_image_manifest.py` that reads `master_content.json` and `sentences.json`, then prints per-lesson image coverage (words with/without `image_path`) and flags broken references (path referenced but file missing)
- [x] 3.2 Confirm the script exits with code 1 when broken references exist and code 0 otherwise
- [ ] 3.3 Run the script after step 2.4 and resolve any flagged issues

## 4. WordCard Widget

- [x] 4.1 Add an optional `imagePath` (`String?`) parameter to the `WordCard` constructor in `lib/widgets/word_card.dart`
- [x] 4.2 Render `Image.asset(imagePath!, semanticsLabel: hindi, fit: BoxFit.contain)` inside a 150 dp tall container at the top of the card when `imagePath != null`; render nothing extra when null
- [x] 4.3 Pass `word.imagePath` from the Learn tab in `LessonScreen` through to each `WordCard`
- [x] 4.4 Update `test/widgets/` (or equivalent) with a widget test that: (a) asserts image appears when `imagePath` is non-null, (b) asserts no image widget is present when `imagePath` is null

## 5. Flashcard (QuizView) — Image Cue

- [x] 5.1 In `lib/screens/quiz_view.dart`, read `imagePath` from the current `WordPair` and display it above the Hindi cue (same 150 dp height, `BoxFit.contain`) in the unrevealed state
- [x] 5.2 Keep the image visible after the card is revealed (so the visual association persists)
- [x] 5.3 Write/update a widget test in `test/` that covers: image visible before reveal and after reveal for a word with `imagePath`; no image widget when `imagePath` is null

## 6. Multiple-Choice Quiz — Image Prompt

- [x] 6.1 In `lib/screens/multiple_choice_quiz.dart`, read `imagePath` from the current `WordPair` and display it above the Hindi question prompt (150 dp, `BoxFit.contain`) when non-null
- [x] 6.2 Write/update a widget test covering: image visible with Hindi prompt when `imagePath` is non-null; no image when `imagePath` is null

## 7. Regression and Golden Tests

- [x] 7.1 Run the full test suite (`flutter test`) and fix any failures caused by the new `imagePath` parameter (especially constructors in existing tests)
- [ ] 7.2 Regenerate any golden screenshot files that are affected by the layout changes (run `update_golden_screenshots.sh` or equivalent)
- [ ] 7.3 Verify that lessons with all-null `imagePath` words produce pixel-identical output to the pre-feature baseline
