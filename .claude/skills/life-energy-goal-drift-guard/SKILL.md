---
name: life-energy-goal-drift-guard
description: Guard LifeEnergyManager goals against silent deadline drift, compute history-calibrated proximity and feasibility, require terminal outcomes, and block unsafe revisions or artifact generation.
---

# Life Energy Goal Drift Guard

## Overview

Run this skill before morning intake, before a proposed persistent revision, and
after its final change set. Also use it during evening closure and Sunday goal
audits. The tracker's Goal Lifecycle And Feasibility Model is the single source;
do not invent alternate thresholds or terminal states.

Escalate to the `goal-drift-guard` subagent only when exit evidence conflicts,
the original baseline conflicts across sources, or drift attribution is
disputed.

## Inputs

- Goal Baseline Registry and Goal Closure Log.
- Planning Calibration and the last 28 valid working days.
- Current phase/month/week, micro-sprints, and ongoing commitments.
- Proposed plan change, when running around a revision.
- Artifact existence/start state, persisted artifact lock, and active Revision ID.

## Procedure

1. Validate Goal IDs, exit criteria, deadlines/windows, and active/terminal state.
2. If a goal is due without closure evidence, return `closure_required` and the
   exact terminal decision required; normal planning must stop.
3. Compute safe capacity, estimate factor, corrected remaining work, coverage,
   confidence, proximity, cumulative delay, revision count, and goal debt per
   the tracker model.
4. Preserve hard external deadlines unless formal change evidence exists.
5. Return `blocked` for false on-track claims, artifact-lock violations, silent
   original-target overwrite, or an invalid terminal transition.
6. Return `rebaseline_required` when the original target is no longer the goal
   or ordinary correction cannot preserve a feasible path.
7. Draft one readable alert that names the target, risk, deadline, and required
   action. Use neutral, non-shaming language.

## Output

```yaml
guard_status: pass | warning | blocked | rebaseline_required | closure_required
goal_id:
proximity: normal | approaching | critical | due
feasibility: green | yellow | red | unknown
cumulative_delay_days:
revision_count:
goal_debt_minutes:
hard_deadline_violation: true | false
required_user_decision:
display_alert:
calculation:
  confidence:
  history_window:
  comparable_days:
  history_labels:
  expected_capacity_minutes:
  safe_capacity_minutes:
  estimate_factor:
  corrected_remaining_minutes:
  coverage:
  latest_safe_start:
evidence:
inference:
```

## Boundaries

- Do not choose a terminal outcome for the user.
- Do not accept a revision, write plan files, or generate artifacts.
- Do not diagnose, shame, or equate low energy with weak commitment.
- Do not clear goal debt merely because a date changed.
