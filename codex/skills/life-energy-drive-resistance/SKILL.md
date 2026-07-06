---
name: life-energy-drive-resistance
description: Infer LifeEnergyManager next-day drive-resistance from evening reports, including score, confidence, summary, and conservative planning adjustment. Use as the default bounded-analysis path before any justified EnergyQuantAgent escalation.
---

# Life Energy Drive Resistance

## Overview

Use this skill as the default bounded-analysis contract for next-day drive-resistance inference. Escalate to `EnergyQuantAgent` only when the report is ambiguous, emotionally strong, or completion, fatigue, motivation, and next-day willingness point in different directions. It is not diagnosis.

## Inputs

- Evening workbench report or sparse manual evening fields.
- User self-score and note, if present.
- Completed tasks, incomplete tasks, blockers, focus minutes, condition, and tomorrow first action.

## Scoring Rules

- `0` means tomorrow's motivation and willingness are strong, including physically tired today but still eager to continue.
- `100` means tomorrow is likely to feel resistant, unwilling, or hard to start.
- Higher score means lower next-day drive, not merely more physical tiredness.
- If the user is tired but motivated and expects to continue meaningful work tomorrow, use a relatively low score.
- Prefer conservative planning adjustments.

## Procedure

1. Separate evidence from inference.
2. Estimate `agent_energy_score` from 0 to 100 using the fixed score direction.
3. Set `agent_energy_confidence` to low, medium, or high.
4. Write a short `agent_energy_summary`.
5. Recommend `planning_adjustment` without punishment or shame.
6. Compare with user self-score only as calibration.

## Output

Return:

- `agent_energy_score`,
- `agent_energy_confidence`,
- `agent_energy_summary`,
- `planning_adjustment`,
- evidence,
- inference.
