# Day 2: 2026-07-15

- Scenario: Small next-week reorder inside capacity
- Workflow: morning_evening / normal
- Guard: warning (proposal: warning)
- Revision: PR-20260714-0 -> PR-20260715-1
- Correction: not_entered; confirmations required: 1; actual valid replies: 1
- Capacity: expected 180 min; safe 144 min; coverage 1.18; confidence low
- Goal debt: 0 min
- Terminal outcome: -
- Artifact result: generated and verified
- Critical path: planned 180 min; actual 190 min
- Unplanned work: 0 min
- Daily scoring: self 60/70; blind 58/68; actual 80; calibrated 59/69

## Checks

- PASS: inline classification: inline without correction mode
- PASS: one final-plan confirmation: actual confirmations=1
- PASS: no correction-mode banner: correction.entered=false
- PASS: scoring blind pass precedes self-score calibration: persisted blind hash=73E6357726DC9197363FA941CF583789ABDB042A49B17EE35CC3D8EF1B27B799 stayed immutable
- PASS: simulated self and agent scores stored: self=60; actual=80
- PASS: score feedback changes or confirms next plan: mode=Standard; target=180; observation=2026-07-14; prediction target=2026-07-15