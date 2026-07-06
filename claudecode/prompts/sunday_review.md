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
- temporary urgent tasks
- current phase and month gates

Use the `life-energy-weekly-review` skill by default to summarize logs and propose next-week priorities before updating the weekly plan. Escalate to the `weekly-review` subagent when repeated deferrals, unclear blockers, or major priority changes need a second pass. If neither the `life-energy-weekly-review` skill nor a justified `weekly-review` subagent path is available, record `WeeklyReviewAgent: main-thread fallback` and complete the same structured weekly review in the main session. The main session must make the final weekly plan.

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
- temporary urgent task status,
- priority rules if a pattern changed.

## Output

Return:

- one-paragraph weekly summary,
- next week's top 3 outcomes,
- first action for Monday,
- agent-delegable task list,
- one anti-distraction rule for the week,
- the required `Subagent calls` audit block.

```text
Subagent calls:
- WeeklyReviewAgent: skill used / subagent used / main-thread fallback / not needed
- Reason:
- Main-thread decision:
```

Keep the review light. Do not create a full daily plan unless the user asks.
