# Day 8: 2026-07-21

- Scenario: Unsupported hard-deadline move is blocked; user exits correction
- Workflow: morning_evening / illness
- Guard: warning (proposal: blocked)
- Revision: PR-20260720-1 -> PR-20260720-1
- Correction: entered_user_exit; confirmations required: 1; actual valid replies: 0
- Capacity: expected 180 min; safe 144 min; coverage 1.01; confidence low
- Goal debt: 210 min
- Terminal outcome: -
- Artifact result: generated and verified
- Critical path: planned 90 min; actual 60 min
- Unplanned work: 0 min
- Daily scoring: self 25/35; blind 30/40; actual 45; calibrated 28/38

## Checks

- PASS: hard deadline move rejected: authoritative hard deadline; proposed 2026-07-30 blocked; deadline and all surface hashes remained 2026-07-27
- PASS: renegotiation required: renegotiationRequired=true
- PASS: user exit writes zero changes: exact UTF-8 exit command; zero writes
- PASS: illness day excluded from normal capacity: illness excluded
- PASS: scoring blind pass precedes self-score calibration: persisted blind hash=1A7066585C67351B63A2B12F34C771071DB3B4ACDD931F7AFF4E9A6252D26EC6 stayed immutable
- PASS: simulated self and agent scores stored: self=25; actual=45
- PASS: score feedback changes or confirms next plan: mode=Reduced illness day; target=90; observation=2026-07-20; prediction target=2026-07-21