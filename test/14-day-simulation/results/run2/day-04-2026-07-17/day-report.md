# Day 4: 2026-07-17

- Scenario: Commitment cap overflow; confirmed write fails and rolls back
- Workflow: morning / recovery
- Guard: warning (proposal: warning)
- Revision: PR-20260716-1 -> PR-20260716-1
- Correction: write_failed_rollback; confirmations required: 1; actual valid replies: 1
- Capacity: expected 180 min; safe 144 min; coverage 0.92; confidence low
- Goal debt: 80 min
- Terminal outcome: -
- Artifact result: not generated (transaction rollback prohibits artifact generation)
- Critical path: planned 90 min; actual 75 min
- Unplanned work: 0 min
- Daily scoring: not scored: Morning-only rollback scenario has no evening report.

## Checks

- PASS: correction mode entered: correction.entered=true
- PASS: single dedicated confirmation: actual confirmations=1
- PASS: rollback keeps prior revision: failure before tracker and at tracker both restored every surface hash
- PASS: artifacts blocked: generation count=0
- PASS: scoring skip is explicit: Morning-only rollback scenario has no evening report.