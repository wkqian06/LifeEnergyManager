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
- Active micro-sprints and ongoing commitments (table + this week's Daily Log closing lines).
- Current phase and month gates.
- Goal Baseline Registry, Goal Closure Log, Planning Calibration, and Plan Revision Log.

## Procedure

1. Summarize the week from evidence.
2. Identify which workstream produced concrete outputs.
3. Identify repeated deferrals and real blockers.
4. Identify tasks that looked like productive procrastination.
5. Draft top 3 next outcomes.
6. List agent-delegable work for next week.
7. Choose a candidate Monday first action.
8. State evidence and inference separately.
9. Audit every due weekly/month/phase/micro-sprint/commitment goal. Return `closure_required` instead of rolling an unfinished goal forward.
10. Summarize revision frequency, cumulative delay, goal debt, and proximity warnings for the next week.

## Output

Return:

- weekly summary,
- stale or exit-ready commitments (expired deadlines incl. soft defaults, high Skip counts, unresolved Migration pending),
- top 3 next outcomes,
- repeated deferrals,
- real blockers,
- agent-delegable tasks,
- Monday first action,
- evidence,
- inference.
- due-goal closure decisions and goal-drift summary.

## Boundaries

- Do not finalize next week's plan.
- Do not create a full daily plan.
- The main thread must update tracker state and priority rules.
