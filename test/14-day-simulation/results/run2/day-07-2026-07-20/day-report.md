# Day 7: 2026-07-20

- Scenario: Phase rebaseline with facts-change confirmation reset
- Workflow: morning_evening / normal
- Guard: warning (proposal: rebaseline_required)
- Revision: PR-20260718-1 -> PR-20260720-1
- Correction: entered_exited; confirmations required: 3; actual valid replies: 3
- Capacity: expected 180 min; safe 144 min; coverage 1.02; confidence low
- Goal debt: 210 min
- Terminal outcome: superseded
- Artifact result: generated and verified
- Critical path: planned 180 min; actual 200 min
- Unplanned work: 0 min
- Daily scoring: self 50/65; blind 52/62; actual 84; calibrated 51/64

## Checks

- PASS: facts reset handled: facts reset cleared stale reply and three new replies completed
- PASS: old phase closed superseded: PH-DISSERTATION closure logged
- PASS: successor Goal ID created: successor=PH-DISSERTATION-V2, dated with exit criterion
- PASS: three replies separate: three unique structured reply IDs survived reset
- PASS: new revision ordinal is one: revision=PR-20260720-1
- PASS: scoring blind pass precedes self-score calibration: persisted blind hash=0825F337F4F54D2D716918D60B646E4D1E5EE3AAF3F4DC9D1CF244B38FE3F114 stayed immutable
- PASS: simulated self and agent scores stored: self=50; actual=84
- PASS: score feedback changes or confirms next plan: mode=Recovery; target=90; observation=2026-07-18; prediction target=