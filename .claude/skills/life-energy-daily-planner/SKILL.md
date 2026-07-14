---
name: life-energy-daily-planner
description: Draft LifeEnergyManager provisional daily plan options from tracker state, rolling history, active sprints, and accepted urgent tasks. Use as the default bounded-analysis path before any justified daily-planner subagent escalation.
---

# Life Energy Daily Planner

## Overview

Use this skill as the default bounded-analysis contract for daily plan drafting. Escalate to the `daily-planner` subagent only when repeated deferrals, real deadline pressure, low energy, or competing workstreams make intensity selection bias-prone. The main session chooses the final plan.

## Inputs

- Active phase, current month, current week.
- Rolling 30-day state.
- Active micro-sprints.
- Active ongoing commitments with their today-allocation decisions from the Commitments digest, plus accepted morning extras.
- Active plan Revision ID, Goal Drift Guard result, and any confirmed inline amendments or completed correction summary.
- Yesterday's daily log or report, if available.
- Morning run context:
  - `run_mode`: `scheduled` or `manual_catchup`.
  - `actual_run_time`.
  - configured morning planning time.
  - configured evening check-in time.
  - usable remaining planning window.

## Procedure

1. Build from `primary deadline -> active phase -> current month -> current week -> today`.
2. Choose one candidate focus mode: Recovery, Standard, Push, or Deadline.
3. Adjust intensity from yesterday's energy remaining and actual drive (night summary), recent blockers, sprint pressure, and real deadlines.
4. Fit the intensity to the actual planning window:
   - For `scheduled`, use the normal daily baseline/stretch target unless evidence says to reduce it.
   - For `manual_catchup`, plan only from `actual_run_time` to the evening check-in time.
   - Do not include elapsed time blocks or tasks that should already have happened.
   - If fewer than two usable hours remain, draft a stop-loss plan with one primary action, one closeout/admin action, and no stretch work.
5. Preserve primary work before secondary work.
6. If any goal is approaching/critical/due, protect one concrete critical-path
   action in baseline and carry the Guard's Goal Alert evidence unchanged:
   original/current deadline, corrected remaining, safe capacity, coverage,
   confidence, history window/day labels/comparable-day count, estimate factor,
   latest safe start, explanation, and required-today action.
7. Draft baseline tasks, stretch tasks, agent-delegable tasks, and explicit non-goals. Attach a Goal ID and `criticalPath` flag to each task.
8. Choose today's overall task focus type and map it to the stable task-category color legend.
9. Draft the recommended time combination, for example `4 H Baseline + 1 H Stretch`; for manual catch-up, shrink the time combination to the remaining window.
10. State evidence and inference separately.

## Output

Return a concise provisional plan draft:

- run mode and planning window,
- focus mode,
- today's overall task focus type,
- task focus color,
- recommended time combination,
- baseline tasks,
- stretch tasks,
- agent-delegable tasks,
- explicit non-goals,
- reason for intensity,
- remaining-time rationale if `run_mode` is `manual_catchup`,
- risks or confirmations.
- active plan Revision ID, Goal Alerts, and task Goal ID/critical-path metadata.

## Boundaries

- Do not finalize the plan.
- Do not revise an upstream plan; consume only confirmed revisions.
- Do not generate HTML or PNG artifacts.
- Do not accept urgent tasks; use only tasks already accepted by the main session.
- The main session must choose the final plan and wait for user confirmation.
- Do not compensate for a late run by overloading the remaining hours.
