---
name: life-energy-drive-resistance
description: Infer LifeEnergyManager next-day drive-resistance from evening reports, including score, confidence, summary, and conservative planning adjustment. Use as the default bounded-analysis path before any justified EnergyQuantAgent escalation.
---

# Life Energy Drive Resistance

## Overview

Use this skill as the default bounded-analysis contract for next-day drive-resistance inference. Escalate to `EnergyQuantAgent` only when the report is ambiguous, emotionally strong, or completion, fatigue, motivation, and next-day willingness point in different directions. It is not diagnosis.

## Inputs

- Evening workbench report or sparse manual evening fields.
- Completed tasks, incomplete tasks, blockers, focus minutes, condition (energy/condition text), and tomorrow first action.
- The user self-score and its note are NOT scoring inputs. Do not read them before estimating; they are the user's own independent evening evaluation of the day, recorded alongside the agent score afterwards.

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
6. Only after the blind estimate is recorded, read the user self-score and note, then produce `agent_calibrated_score`: the final estimate after weighing the user's own evening evaluation. The blind `agent_energy_score` is never edited. Base `planning_adjustment` on the calibrated score. If blind and user scores diverge by 30+ points, flag the divergence explicitly as a planning signal.

## Output

Return:

- `agent_energy_score` (blind),
- `agent_energy_confidence`,
- `agent_energy_summary`,
- `agent_calibrated_score`,
- `planning_adjustment`,
- evidence,
- inference.
