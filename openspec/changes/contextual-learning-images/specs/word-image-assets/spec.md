## ADDED Requirements

### Requirement: Optional image path field on WordPair
The `WordPair` model SHALL include an optional `imagePath` field (`String?`) that holds the Flutter asset path to a contextual image for that vocabulary word. When `image_path` is absent in the JSON source, `imagePath` SHALL be `null`.

#### Scenario: WordPair with image_path in JSON
- **WHEN** `WordPair.fromJson` is called with a JSON object containing `"image_path": "assets/images/words/namaste.png"`
- **THEN** the resulting `WordPair.imagePath` SHALL equal `"assets/images/words/namaste.png"`

#### Scenario: WordPair without image_path in JSON
- **WHEN** `WordPair.fromJson` is called with a JSON object that has no `image_path` key
- **THEN** the resulting `WordPair.imagePath` SHALL be `null`

#### Scenario: WordPair with null image_path in JSON
- **WHEN** `WordPair.fromJson` is called with a JSON object containing `"image_path": null`
- **THEN** the resulting `WordPair.imagePath` SHALL be `null`

---

### Requirement: Optional image path field on SentenceItem
The `SentenceItem` model SHALL include an optional `imagePath` field (`String?`) following the same contract as `WordPair.imagePath`.

#### Scenario: SentenceItem with image_path in JSON
- **WHEN** `SentenceItem.fromJson` is called with a JSON object containing `"image_path": "assets/images/words/eat.png"`
- **THEN** the resulting `SentenceItem.imagePath` SHALL equal `"assets/images/words/eat.png"`

#### Scenario: SentenceItem without image_path in JSON
- **WHEN** `SentenceItem.fromJson` is called with a JSON object that has no `image_path` key
- **THEN** the resulting `SentenceItem.imagePath` SHALL be `null`

---

### Requirement: Word image asset directory structure
All word/sentence contextual images SHALL reside under `assets/images/words/` and be declared in `pubspec.yaml` so Flutter bundles them in the app binary.

#### Scenario: Asset directory is declared in pubspec
- **WHEN** the app is built
- **THEN** Flutter SHALL include all files under `assets/images/words/` in the asset bundle, accessible via `Image.asset()`

#### Scenario: Image file naming convention
- **WHEN** an image is added for a vocabulary concept
- **THEN** the file SHALL be named using the snake-case romanisation of the primary Hindi word (the part before `/` if variants exist), with a `.png` extension (e.g. `namaste.png`, `pani.png`, `khaana.png`)

---

### Requirement: Image asset size constraint
Each image file under `assets/images/words/` SHALL be no larger than 50 KB (compressed PNG) to keep the app binary size growth bounded.

#### Scenario: Oversized image is flagged by audit script
- **WHEN** `scripts/generate_image_manifest.py` is run
- **THEN** it SHALL print a warning for every image whose file size exceeds 50 KB

---

### Requirement: Image manifest and coverage audit script
A Python script at `scripts/generate_image_manifest.py` SHALL report image coverage for `master_content.json` and `sentences.json`.

#### Scenario: Script reports per-lesson coverage
- **WHEN** the script is run from the repository root
- **THEN** it SHALL print, for each lesson, the count of words that have an `image_path` and the count that do not

#### Scenario: Script reports missing image files
- **WHEN** a word's `image_path` references a file that does not exist on disk
- **THEN** the script SHALL flag that entry as a broken reference

#### Scenario: Script exits non-zero on broken references
- **WHEN** any broken image reference is found
- **THEN** the script SHALL exit with a non-zero exit code (suitable for use in CI)
