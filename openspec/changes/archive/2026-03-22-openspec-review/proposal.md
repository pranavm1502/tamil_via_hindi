## Why

The app's SRS review flow has no mechanism for users to revisit cards they got wrong during a session. After completing a review, mistakes disappear and users must wait for the SRS scheduler to reschedule them — sometimes days later — losing the immediate reinforcement benefit. A dedicated mistakes-review mode closes this loop and strengthens retention at the moment it matters most.

The SRS interval should not be manually decided by the user and should be completely automated.

This aligns with Phase 2 (Retention Systems) in PHASED_PLAN.md.

## What Changes

- A new **Mistakes Review** screen that surfaces all cards answered incorrectly in the most recent review session.
- A prompt at the end of a review session (when mistakes exist) offering users the chance to drill their mistakes immediately.
- Mistakes are passed in-memory from the review session — no new persistence layer needed.
- The existing `MistakesReviewScreen` stub is fleshed out with real card-flip / answer flow.

## Capabilities

### New Capabilities

- `mistakes-review`: A focused drill mode that presents only the cards a user got wrong in the preceding review session, allowing immediate re-practice before the SRS interval resets.

### Modified Capabilities

<!-- No existing spec-level requirements are changing. -->

## Impact

- `lib/screens/review_screen.dart` — add end-of-session prompt when mistakes exist.
- `lib/screens/mistakes_review_screen.dart` — implement full answer flow (currently a stub).
- `lib/providers/review_provider.dart` — expose the list of incorrectly-answered cards from the last session.
- No Firestore or SharedPreferences changes required (in-memory only).
- No XP or streak rule changes.
