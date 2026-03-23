## ADDED Requirements

### Requirement: Session mistakes are tracked during review
`ReviewProvider` SHALL record each `ReviewCard` answered with `ReviewQuality.again` into an in-memory session mistakes list during an active review session. The list SHALL be cleared when a new review session starts.

#### Scenario: Card answered again is tracked as a mistake
- **WHEN** a user answers a review card with quality `again`
- **THEN** that `ReviewCard` is added to the session mistakes list in `ReviewProvider`

#### Scenario: Session mistakes are cleared on new session start
- **WHEN** a new review session begins (session queue is built)
- **THEN** the session mistakes list is reset to empty

#### Scenario: No mistakes when all cards answered correctly
- **WHEN** a user completes a review session answering every card with `good` or better
- **THEN** the session mistakes list is empty

### Requirement: Mistakes drill prompt shown at session end
At the end of a review session, the app SHALL display a prompt offering an immediate drill if and only if the session mistakes list is non-empty. If the list is empty, no prompt is shown.

#### Scenario: Prompt shown when mistakes exist
- **WHEN** a review session completes and at least one card was answered with `again`
- **THEN** a dialog or bottom sheet is shown offering the user the option to drill their mistakes immediately

#### Scenario: No prompt when no mistakes exist
- **WHEN** a review session completes with zero cards answered `again`
- **THEN** no mistakes drill prompt is displayed

#### Scenario: User can dismiss the prompt
- **WHEN** the mistakes drill prompt is shown
- **THEN** the user can dismiss it and return to the normal post-session summary without entering the drill

### Requirement: Mistakes drill navigates to MistakesReviewScreen with session cards
When the user accepts the drill prompt, the app SHALL navigate to `MistakesReviewScreen` loaded with only the cards from the session mistakes list, bypassing the persistent `MistakeProvider` load.

#### Scenario: Drill starts with correct card set
- **WHEN** the user accepts the drill from the session-end prompt
- **THEN** `MistakesReviewScreen` is pushed with the session mistakes cards and only those cards are shown

#### Scenario: Persistent mistakes are unaffected
- **WHEN** the session drill is completed or dismissed
- **THEN** the persistent mistakes list in `MistakeProvider` (SharedPreferences) is unchanged
