## 1. ReviewProvider — Session Mistake Tracking

- [x] 1.1 Add `List<ReviewCard> _sessionMistakes` field to `ReviewProvider` (`lib/providers/review_provider.dart`)
- [x] 1.2 Expose `List<ReviewCard> get sessionMistakes` getter on `ReviewProvider`
- [x] 1.3 Clear `_sessionMistakes` when a new review session queue is built (in the method that populates `_currentReviewQueue`)
- [x] 1.4 Append to `_sessionMistakes` when a card is answered with `ReviewQuality.again` (in the answer-recording method)

## 2. ReviewProvider — Tests

- [x] 2.1 Add unit tests in `test/providers/review_provider_test.dart` covering:
  - Session mistakes list is empty at session start
  - Card answered `again` is added to session mistakes
  - Card answered `good` is NOT added to session mistakes
  - Session mistakes are cleared when a new session starts

## 3. MistakesReviewScreen — Accept In-Memory Card List

- [x] 3.1 Add an optional `List<ReviewCard>? sessionCards` parameter to `MistakesReviewScreen` (`lib/screens/mistakes_review_screen.dart`)
- [x] 3.2 In `initState`, skip `MistakeProvider.loadMistakes()` and use `sessionCards` directly when the parameter is provided
- [x] 3.3 Ensure the persistent `MistakeProvider` flow is unchanged when `sessionCards` is null

## 4. Review Screen — End-of-Session Prompt

- [x] 4.1 After session completion in `review_screen.dart`, check `ReviewProvider.sessionMistakes.isNotEmpty`
- [x] 4.2 If non-empty, show a dialog prompting "Drill your N mistake(s)?" with a "Drill" action and a "Skip" dismiss action
- [x] 4.3 On "Drill" tap, push `MistakesReviewScreen(sessionCards: reviewProvider.sessionMistakes)`
- [x] 4.4 If session mistakes are empty, show no prompt (existing summary flow unchanged)
