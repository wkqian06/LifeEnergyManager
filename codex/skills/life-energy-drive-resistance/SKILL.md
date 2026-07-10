---
name: life-energy-drive-resistance
description: Produce LifeEnergyManager's three daily scoring metrics (energy remaining, predicted next-day drive, actual drive) from evening reports, with blind and calibrated agent values plus a conservative planning adjustment. Use as the default bounded-analysis path before any justified EnergyQuantAgent escalation.
---

# Life Energy Drive Resistance

## Overview

Use this skill as the default bounded-analysis contract for the three daily metrics defined in the tracker's Daily Scoring Model (energy remaining, predicted next-day drive, actual drive). Escalate to the `EnergyQuantAgent` only when the report is ambiguous, emotionally strong, its signals diverge, or the result would change next-day intensity. It is not diagnosis.

All three metrics are 0-100, same direction (higher = better). Definitions live in the tracker; do not restate them here.

## Inputs

- Evening workbench report or sparse manual evening fields.
- Completed tasks, incomplete tasks, blockers, focus minutes, condition (energy/condition text), and tomorrow first action.
- The user self-scores (`remainingSelf`, `predDriveSelf`) and notes are NOT inputs to the blind pass. Do not read them before the blind estimate; they are the user's own independent evening evaluation, weighed only at the calibration step.

## Procedure

1. Separate evidence from inference.
2. **Blind pass** (user self-scores not read), from report evidence only:
   - `remainingBlind` - energy left after today.
   - `predDriveBlind` - drive expected tomorrow.
   - `actualDrive` - the drive/energy you actually had to act that day, roughly how much you were able to get done though not a strict output count (single value, anchored on focus minutes and completions; never calibrated).
3. Set `agent_energy_confidence` (low / medium / high) and write a short summary.
4. Read the user self-scores and notes, then produce `remainingCalibrated` and `predDriveCalibrated` by weighing them. The blind values are never edited.
5. Recommend `planning_adjustment` from today's energy remaining and actual drive (they feed tomorrow's sizing), without punishment or shame. Predicted drive is a forecast used for calibration, not a planning input.
6. Compare `actualDrive` (today) with the calibrated prediction made last night; a large gap means the predictor is miscalibrated - flag it. Also flag a blind-vs-self gap of 30+ points on the drive prediction.

## Output

Return:

- `remainingBlind`, `remainingCalibrated`,
- `predDriveBlind`, `predDriveCalibrated`,
- `actualDrive`,
- `agent_energy_confidence`,
- `agent_energy_summary`,
- `planning_adjustment`,
- actual-vs-predicted comparison note,
- evidence,
- inference.

(The user self-scores `remainingSelf` / `predDriveSelf` come from the workbench, not from this skill.)
