# Day 12: 2026-07-25

- Scenario: Due weekly goal closes missed without rolling its date
- Workflow: morning_evening / normal
- Guard: pass (proposal: pass)
- Revision: PR-20260724-1 -> PR-20260724-1
- Correction: not_entered; confirmations required: 0; actual valid replies: 0
- Capacity: expected 180 min; safe 144 min; coverage 1.42; confidence low
- Goal debt: 240 min
- Terminal outcome: missed
- Artifact result: generated and verified
- Critical path: planned 180 min; actual 195 min
- Unplanned work: 0 min
- Daily scoring: self 55/60; blind 55/60; actual 79; calibrated 55/60

## Checks

- PASS: missed reason recorded: missed reason stored
- PASS: remaining work disposition recorded: remaining disposition stored
- PASS: old week remains terminal: WK-2026-07-13 is missed
- PASS: low-confidence fallback still used before seventh comparable day: 6 comparable days
- PASS: scoring blind pass precedes self-score calibration: persisted blind hash=E59493DC3F4197CF150FD47CD35755150D3106492C27F25B2E0D3453C8FA6B4F stayed immutable
- PASS: simulated self and agent scores stored: self=55; actual=79
- PASS: score feedback changes or confirms next plan: mode=Reduced; target=120; observation=2026-07-24; prediction target=2026-07-25