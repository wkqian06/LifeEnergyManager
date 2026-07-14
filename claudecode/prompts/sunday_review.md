# LifeEnergyManager Sunday Review Prompt (Claude Code)

Use this prompt for the weekly light review routine.

## Role

You are keeping the system aligned without creating a heavy planning session.

## Read

Read:

- `claudecode/prompts/subagents.md`
- `outputs/life_energy_tracker.md`
- last 7 daily logs from `outputs/life_energy_tracker.md` and `outputs/daily-reports/`
- rolling 30-day state
- active micro-sprints
- ongoing commitments (table + this week's Daily Log closing lines)
- current phase and month gates
- Goal Baseline Registry, Goal Closure Log, Planning Calibration, Plan Revision Log, and active Revision ID

Use the `life-energy-weekly-review` skill by default to summarize logs and propose next-week priorities before updating the weekly plan. Escalate to the `weekly-review` subagent when repeated deferrals, unclear blockers, or major priority changes need a second pass. If neither the `life-energy-weekly-review` skill nor a justified `weekly-review` subagent path is available, record `WeeklyReviewAgent: main-thread fallback` and complete the same structured weekly review in the main session. The main session must make the final weekly plan.

Run `life-energy-goal-drift-guard` before updating next week. Audit every due
phase/month/week/micro-sprint/commitment goal. A due goal without a terminal
outcome becomes `closure_required`; ask the user and stop the update until they
choose. Record closures before creating any successor. Summarize proximity,
coverage confidence, revision frequency, cumulative delay, and goal debt.

## Review Questions

Answer briefly:

- Did the long-term goal become more achievable this week?
- Which workstream produced concrete outputs?
- Which task was repeatedly deferred?
- Which blockers are real?
- Which tasks looked like productive procrastination?
- Which agent-delegable work should be launched or reviewed next week?
- What needs human judgment before more automation is useful?

## Update

Update:

- weekly plan for the next week,
- rolling 30-day state compression,
- active micro-sprint day counts and status,
- ongoing commitments audit (three checks, one line each: expired deadlines incl. soft defaults, high Skip counts, unresolved Migration pending marker),
- Goal Baseline Registry and Goal Closure Log,
- Planning Calibration and Plan Revision Log drift summary,
- Planning Calibration weekly planned/completed output totals and completion rate,
- priority rules if a pattern changed.

## Output

Return:

- one-paragraph weekly summary,
- next week's top 3 outcomes,
- first action for Monday,
- agent-delegable task list,
- one anti-distraction rule for the week,
- stale or exit-ready commitments (from the ongoing commitments audit),
- goal terminal outcomes, approaching/critical warnings, and any rebaseline-required decision,
- the required `Subagent calls` audit block.

```text
Subagent calls:
- GoalDriftGuardAgent: skill used / subagent used / main-thread fallback / not needed
- WeeklyReviewAgent: skill used / subagent used / main-thread fallback / not needed
- Reason:
- Main-thread decision:
```

Keep the review light. Do not create a full daily plan unless the user asks.
