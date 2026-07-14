# Day 14: 2026-07-27

- Scenario: Dropped commitment plus post-artifact unplanned work
- Workflow: morning_evening / normal
- Guard: pass (proposal: blocked)
- Revision: PR-20260726-1 -> PR-20260726-1
- Correction: locked_after_artifact; confirmations required: 0; actual valid replies: 0
- Capacity: expected 195 min; safe 156 min; coverage 1.36; confidence high
- Goal debt: 300 min
- Terminal outcome: dropped
- Artifact result: generated and verified
- Critical path: planned 180 min; actual 185 min
- Unplanned work: 45 min
- Daily scoring: self 60/70; blind 58/68; actual 76; calibrated 59/69

## Checks

- PASS: dropped reason and disposition recorded: reason and remaining disposition stored
- PASS: artifact lock prevents revision: mid-generation and post-generation mutation attempts blocked; plan hashes unchanged
- PASS: late work recorded as unplanned: 45 unplanned min
- PASS: no artifact regeneration: one generation, zero regeneration, HTML/PNG hashes unchanged
- PASS: high-confidence capacity retained: high, 195 min
- PASS: scoring blind pass precedes self-score calibration: persisted blind hash=E1F7A3B89B2626AD9D628348B1A71096C36BE860E56E2C9B2B53AF6C33E4ACC3 stayed immutable
- PASS: simulated self and agent scores stored: self=60; actual=76
- PASS: score feedback changes or confirms next plan: mode=Standard; target=180; observation=2026-07-25; prediction target=