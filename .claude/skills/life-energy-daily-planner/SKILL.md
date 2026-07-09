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
- Yesterday's daily log or report, if available.

## Procedure

1. Build from `primary deadline -> active phase -> current month -> current week -> today`.
2. Choose one candidate focus mode: Recovery, Standard, Push, or Deadline.
3. Adjust intensity from yesterday's energy remaining and actual start-of-day drive, recent blockers, sprint pressure, and real deadlines.
4. Preserve primary work before secondary work.
5. Draft baseline tasks, stretch tasks, agent-delegable tasks, and explicit non-goals.
6. Choose today's overall task focus type and map it to the stable task-category color legend.
7. Draft the recommended time combination, for example `4 H Baseline + 1 H Stretch`.
8. State evidence and inference separately.

## Output

Return a concise provisional plan draft:

- focus mode,
- today's overall task focus type,
- task focus color,
- recommended time combination,
- baseline tasks,
- stretch tasks,
- agent-delegable tasks,
- explicit non-goals,
- reason for intensity,
- risks or confirmations.

## Boundaries

- Do not finalize the plan.
- Do not generate HTML or PNG artifacts.
- Do not accept urgent tasks; use only tasks already accepted by the main session.
- The main session must choose the final plan and wait for user confirmation.
