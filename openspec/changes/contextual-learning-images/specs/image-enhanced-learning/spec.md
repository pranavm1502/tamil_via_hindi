## ADDED Requirements

### Requirement: WordCard displays contextual image when available
The `WordCard` widget SHALL display the word's contextual image at the top of the card when `imagePath` is non-null. When `imagePath` is null, the card SHALL render exactly as it does today (no placeholder box or empty space).

#### Scenario: Word has an image
- **WHEN** `WordCard` is rendered with a non-null `imagePath`
- **THEN** an `Image.asset(imagePath)` SHALL appear at the top of the card, inside a container of fixed height 150 dp, using `BoxFit.contain`

#### Scenario: Word has no image
- **WHEN** `WordCard` is rendered with `imagePath == null`
- **THEN** no image area SHALL be rendered and the card layout SHALL be identical to the current text-only layout

#### Scenario: Image fails to load from asset bundle
- **WHEN** the image asset path exists in the model but the file is missing from the bundle
- **THEN** Flutter's default `Image.asset` error builder SHALL display gracefully (no uncaught exception)

---

### Requirement: Flashcard quiz shows image as visual cue before reveal
In the `QuizView` (Flashcard tab), when a `WordPair` has a non-null `imagePath`, the image SHALL be displayed in the unrevealed state alongside the Hindi cue so the learner can form a visual association before seeing the Tamil answer.

#### Scenario: Flashcard unrevealed — word has image
- **WHEN** a flashcard is shown before the user taps "Reveal"
- **THEN** the contextual image SHALL be visible above the Hindi word

#### Scenario: Flashcard unrevealed — word has no image
- **WHEN** a flashcard is shown before the user taps "Reveal" for a word with no image
- **THEN** only the Hindi word SHALL be shown, with no image area

#### Scenario: Flashcard revealed — image remains visible
- **WHEN** the user taps "Reveal" on a flashcard that has an image
- **THEN** the image SHALL remain visible alongside the revealed Tamil text and pronunciation

---

### Requirement: Multiple-choice quiz shows image with the Hindi prompt
In `MultipleChoiceQuiz`, when the current `WordPair` has a non-null `imagePath`, the image SHALL be displayed above the Hindi question prompt.

#### Scenario: MCQ question has image
- **WHEN** a multiple-choice question is rendered for a word with an image
- **THEN** the contextual image SHALL appear above the Hindi prompt text, at the same 150 dp fixed height with `BoxFit.contain`

#### Scenario: MCQ question has no image
- **WHEN** a multiple-choice question is rendered for a word without an image
- **THEN** only the Hindi question prompt SHALL appear, with no image area or blank space

---

### Requirement: Image accessibility — semantic label
Every contextual image rendered in `WordCard`, `QuizView`, and `MultipleChoiceQuiz` SHALL include a `semanticsLabel` set to the Hindi word, so screen readers can describe the image.

#### Scenario: Image has semantic label
- **WHEN** `Image.asset` is rendered with a non-null `imagePath`
- **THEN** a `semanticsLabel` equal to the `hindi` field of the associated `WordPair` SHALL be provided

---

### Requirement: No layout regression for words without images
Existing words that do not have images SHALL exhibit no visual change in any learning screen.

#### Scenario: Learn tab with all text-only words
- **WHEN** a lesson whose words all have `imagePath == null` is opened in the Learn tab
- **THEN** the UI SHALL be pixel-identical (within golden test tolerance) to the pre-feature layout
