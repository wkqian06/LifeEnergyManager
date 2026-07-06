---
name: life-energy-weekly-review
description: Summarize LifeEnergyManager weekly logs and prepare next-week outcomes, blockers, deferrals, agent-delegable tasks, and Monday first action. Use as the default bounded-analysis path before any justified WeeklyReviewAgent escalation.
---

# Life Energy Weekly Review

## Overview

Use this skill as the default bounded-analysis contract for weekly review. Escalate to `WeeklyReviewAgent` only when repeated deferrals, unclear blockers, or major priority changes need a second pass. It summarizes weekly evidence and drafts next-week planning inputs; the main thread makes the final weekly plan.

## Inputs

- `outputs/life_energy_tracker.md`.
- Last 7 daily logs from tracker and `outputs/daily-reports/`.
- Rolling 30-day state.
- Active micro-sprints and temporary urgent tasks.
- Current phase and month gates.

## Procedure

1. Summarize the week from evidence.
2. Identify which workstream produced concrete outputs.
3. Identify repeated deferrals and real blockers.
4. Identify tasks that looked like productive procrastination.
5. Draft top 3 next outcomes.
6. List agent-delegable work for next week.
7. Choose a candidate Monday first action.
8. State evidence and inference separately.

## Output

Return:

- weekly summary,
- top 3 next outcomes,
- repeated deferrals,
- real blockers,
- agent-delegable tasks,
- Monday first action,
- evidence,
- inference.

## Boundaries

- Do not finalize next week's plan.
- Do not create a full daily plan.
- The main thread must update tracker state and priority rules.
