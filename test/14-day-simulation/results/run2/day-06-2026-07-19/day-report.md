# Day 6: 2026-07-19

- Scenario: Sunday drift audit escalates accumulated delay to rebaseline
- Workflow: sunday_review / travel
- Guard: rebaseline_required (proposal: rebaseline_required)
- Revision: PR-20260718-1 -> PR-20260718-1
- Correction: proposal_only; confirmations required: 3; actual valid replies: 0
- Capacity: expected 180 min; safe 144 min; coverage 0.84; confidence low
- Goal debt: 210 min
- Terminal outcome: -
- Artifact result: not generated (Sunday review produces an audit, not daily artifacts)
- Critical path: planned 0 min; actual 0 min
- Unplanned work: 0 min
- Daily scoring: not scored: Sunday review and travel day has no daily evening workbench.

## Checks

- PASS: cumulative drift detected: derived from debt=210, revisions=3, feasibility=red
- PASS: goal debt not cleared: 210 min
- PASS: travel/Sunday excluded from normal capacity: travel/Sunday excluded
- PASS: no Sunday artifacts: generation count=0
- PASS: scoring skip is explicit: Sunday review and travel day has no daily evening workbench.