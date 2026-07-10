---
name: life-energy-daily-planner
description: Draft LifeEnergyManager provisional daily plan options from tracker state, rolling history, active sprints, and accepted urgent tasks. Use as the default bounded-analysis path before any justified DailyPlannerAgent escalation.
---

# Life Energy Daily Planner

## Overview

Use this skill as the default bounded-analysis contract for daily plan drafting. Escalate to `DailyPlannerAgent` only when repeated deferrals, real deadline pressure, low energy, or competing workstreams make intensity selection bias-prone. The main thread chooses the final plan.

## Inputs

- Active phase, current month, current week.
- Rolling 30-day state.
- Active micro-sprints.
- Active ongoing commitments with their today-allocation decisions from the Commitments digest, plus accepted morning extras.
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
3. Adjust intensity from yesterday's energy remaining and actual drive, recent blockers, sprint pressure, and real deadlines.
4. Fit the intensity to the actual planning window:
   - For `scheduled`, use the normal daily baseline/stretch target unless evidence says to reduce it.
   - For `manual_catchup`, plan only from `actual_run_time` to the evening check-in time.
   - Do not include elapsed time blocks or tasks that should already have happened.
   - If fewer than two usable hours remain, draft a stop-loss plan with one primary action, one closeout/admin action, and no stretch work.
5. Preserve primary work before secondary work.
6. Draft baseline tasks, stretch tasks, agent-delegable tasks, and explicit non-goals.
7. Choose today's overall task focus type and map it to the stable task-category color legend.
8. Draft the recommended time combination, for example `4 H Baseline + 1 H Stretch`; for manual catch-up, shrink the time combination to the remaining window.
9. State evidence and inference separately.

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

## Boundaries

- Do not finalize the plan.
- Do not generate HTML or PNG artifacts.
- Do not accept urgent tasks; use only tasks already accepted by the main thread.
- The main thread must choose the final plan and wait for user confirmation.
- Do not compensate for a late run by overloading the remaining hours.
