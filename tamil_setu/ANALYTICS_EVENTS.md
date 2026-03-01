# Analytics Event Map

This document defines the core learning events to capture for retention and quality analysis.

## Identity
- user_id (string, nullable when signed out)
- session_id (string, per app launch)
- device_platform (android/ios/web)
- app_version (semver)

## Core Events
1. app_open
   - cold_start (bool)

2. dashboard_view
   - lessons_visible (int)
   - streak_days (int)
   - xp_total (int)

3. lesson_start
   - lesson_index (int)
   - lesson_title (string)
   - source (dashboard/review/other)

4. lesson_complete
   - lesson_index (int)
   - score_percent (int)
   - duration_sec (int)
   - passed (bool)

5. quiz_start
   - lesson_index (int)
   - quiz_type (flashcard/mcq/checkpoint)

6. quiz_answer
   - lesson_index (int)
   - quiz_type (flashcard/mcq/checkpoint)
   - correct (bool)
   - response_time_ms (int)

7. quiz_complete
   - lesson_index (int)
   - quiz_type (flashcard/mcq/checkpoint)
   - score_percent (int)
   - passed (bool)
   - duration_sec (int)

8. review_start
   - due_cards (int)
   - daily_goal (int)

9. review_answer
   - lesson_index (int)
   - word_index (int)
   - quality (again/hard/good/easy)

10. review_complete
   - cards_reviewed (int)
   - duration_sec (int)
   - streak_days (int)

11. streak_updated
   - streak_days (int)
   - reason (lesson/review/checkpoint)

12. notification_scheduled
   - time_local (HH:mm)

13. notification_opened
   - notification_type (daily_review)

## Error Events
- audio_playback_error (source, lesson_index)
- tts_error (source, lesson_index)
- sync_error (action)

## Privacy
- No raw text answers stored.
- No precise location or contacts.
- User ID hashed or Firebase UID only.
