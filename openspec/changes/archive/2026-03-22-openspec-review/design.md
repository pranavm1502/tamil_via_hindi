## Context

The `MistakesReviewScreen` already exists in the codebase and is wired to a `MistakeProvider` that persists mistakes to SharedPreferences. However, the current mistakes flow is a **persistent, long-lived list** — it accumulates wrong answers across all review sessions and asks users to drill them at any time from the profile/dashboard.

The proposal asks for a complementary **in-session mistakes drill**: at the end of a review session, if cards were answered incorrectly, prompt the user to drill just those cards immediately. This is a separate flow from the existing persistent mistakes system.

**Current state:**
- `ReviewProvider` tracks `_currentReviewQueue` and `_currentCardIndex` during a session.
- When a card is answered with `ReviewQuality.again`, `SRSService.updateCard` reschedules it but the card is not separately tracked as a session mistake.
- `review_screen.dart` shows a completion summary with card count and daily goal progress but no mistakes drill prompt.
- `MistakesReviewScreen` is driven by `MistakeProvider` (persistent), not `ReviewProvider`.

## Goals / Non-Goals

**Goals:**
- Track which `ReviewCard`s were answered incorrectly (`again`) during the current review session.
- At session end, if any mistakes exist, show a prompt offering an immediate drill.
- The drill reuses `MistakesReviewScreen` or a lightweight equivalent — no new screen required if the existing one can accept an in-memory card list.
- Offline-first: entirely in-memory, no network calls needed.

**Non-Goals:**
- Changing the persistent `MistakeProvider` / SharedPreferences mistakes system.
- Awarding extra XP for completing the mistakes drill (keep XP rules unchanged).
- Tracking streak credit for mistakes drills.
- Persisting session mistake history across app restarts.

## Decisions

**Decision 1: Track session mistakes in `ReviewProvider`, not a new provider.**

`ReviewProvider` already owns the review session lifecycle. Adding a `List<ReviewCard> _sessionMistakes` field there is the minimal change. A new provider would add indirection for no benefit.

Alternatives considered:
- New `SessionMistakesProvider`: unnecessary — no separate persistence or complex state.
- Pass mistakes as constructor arg to a new screen: workable but creates a new screen and duplicates the card-flip UI.

**Decision 2: Reuse `MistakesReviewScreen` by accepting an optional card override.**

`MistakesReviewScreen` already has the card-flip UI. Rather than building a new screen, add an optional `List<WordPair>?` (or `List<ReviewCard>?`) parameter. When provided, it bypasses `MistakeProvider.loadMistakes()` and drills directly from the in-memory list.

Alternatives considered:
- Separate `SessionMistakesScreen`: duplicates the entire card-flip widget tree.
- Navigate into regular `review_screen.dart` with a filtered queue: conflates the two flows and re-triggers SRS updates.

**Decision 3: Prompt at end of review session via a dialog, not a new screen nav.**

A simple `showDialog` at session end keeps the flow lightweight. The user can dismiss and skip the drill, or tap "Drill Mistakes" to push `MistakesReviewScreen` with the session list.

Offline-first: entirely local — `ReviewProvider._sessionMistakes` is in-memory only. Works with no network.

**Firestore:** No schema changes. Session mistakes are not persisted to Firestore.

## Risks / Trade-offs

- [Risk] `MistakesReviewScreen` currently couples tightly to `MistakeProvider` for loading. Adding an override path increases complexity slightly. → Mitigation: use a named constructor or a simple nullable parameter checked in `initState`.
- [Risk] Session mistakes list is lost on app restart or hot reload during a session. → Acceptable: the SRS scheduler will resurface the cards; the drill is a best-effort convenience.
- [Trade-off] Reusing `MistakesReviewScreen` means the persistent mistakes flow and the session drill share UI code. This is the intended outcome — less duplication.
