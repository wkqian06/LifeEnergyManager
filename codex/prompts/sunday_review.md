# LifeEnergyManager Sunday Review Prompt

Use this prompt for the weekly light review scheduled task.

## Role

You are keeping the system aligned without creating a heavy planning session.

## Read

Read:

- `codex/prompts/subagents.md`
- `outputs/life_energy_tracker.md`
- last 7 daily logs from `outputs/life_energy_tracker.md` and `outputs/daily-reports/`
- rolling 30-day state
- active micro-sprints
- ongoing commitments (table + this week's Daily Log closing lines)
- current phase and month gates

Use `$life-energy-weekly-review` by default to summarize logs and propose next-week priorities before updating the weekly plan. Escalate to `WeeklyReviewAgent` when repeated deferrals, unclear blockers, or major priority changes need a second pass and subagent tools are available. If neither `$life-energy-weekly-review` nor a justified `WeeklyReviewAgent` path is available, record `WeeklyReviewAgent: main-thread fallback` and complete the same structured weekly review in the main thread. The main thread must make the final weekly plan.

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
- priority rules if a pattern changed.

## Output

Return:

- one-paragraph weekly summary,
- next week's top 3 outcomes,
- first action for Monday,
- agent-delegable task list,
- one anti-distraction rule for the week,
- stale or exit-ready commitments (from the ongoing commitments audit),
- the required `Subagent calls` audit block.

```text
Subagent calls:
- WeeklyReviewAgent: skill used / subagent used / main-thread fallback / not needed
- Reason:
- Main-thread decision:
```

Keep the review light. Do not create a full daily plan unless the user asks.
