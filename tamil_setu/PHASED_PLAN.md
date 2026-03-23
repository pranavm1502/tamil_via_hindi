# Tamil Setu - Phased Improvement Plan

This is a working plan captured before committing to git. It will be updated as phases complete.

## Product Language Policy
- Instructions and UI guidance: English only.
- Learning content: Hindi <-> Tamil translation only.
- Avoid mixing scripts in instructional copy.

## Phase 1 - Stabilize Core Loop
Goals: reliable progression, consistent instruction language, data integrity, measurable retention basics.
- Enforce progression gates (disable testing mode in production).
- Remove duplicate provider wiring.
- Normalize instructional copy to English across core learning screens.
- Ensure tests that rely on unlocked content explicitly opt into testing mode.
- Add a basic analytics event map (spec only in this phase).
- Define XP and streak rules for lesson, review, and checkpoint completion.

Deliverables
- Unlocking works for lessons and checkpoints.
- Core screens use English instructions (dashboard, quizzes, review).
- Tests still pass.

## Phase 2 - Retention Systems
Goals: stickiness, daily habit formation, and review cadence.
- Daily session plan and streak protection (streak freeze).
- Leagues with weekly reset and tiered rewards.
- Mistakes review flow and short remediation sets.
- Review session pacing and difficulty-based ordering.
- Notification personalization (streak risk, due reviews).

## Phase 3 - Learning Depth
Goals: broader exercise types and deeper language skill transfer.
- Add listening comprehension and dictation exercises.
- Add sentence building and word order drills.
- Add speaking practice with pronunciation scoring or feedback proxy.
- Expand curriculum to include dialogue and situational tasks.

## Phase 4 - Personalization and Scale
Goals: adaptive learning at scale, content velocity, and experimentation.
- Placement test and dynamic difficulty curves.
- A/B testing framework and remote config.
- Telemetry dashboards for funnel and content quality.
- Content tooling: validation, review queues, and versioning.
