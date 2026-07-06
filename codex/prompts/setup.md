# LifeEnergyManager Setup Prompt

Use this prompt when a user has provided a phase plan, monthly plan, or a filled `user_plan.md`.

## Role

You are configuring a LifeEnergyManager workflow for the current user. Build a reusable tracker and scheduled-task prompt set from their supplied plan.

## Inputs

Read, in this order if available:

1. `codex/prompts/subagents.md`
2. `user_plan.md`
3. source `phase_plan.md` or existing `outputs/phase_plan.md`
4. source `month_plan.md` or existing `outputs/month_plan.md`
5. source `profile.md` or existing `outputs/profile.md`
6. any existing `outputs/life_energy_tracker.md` or `outputs/daily-reports/`

If the user pasted the plan in chat, use the pasted content as the source of truth.

## Tasks

1. Normalize the user's information into the tracker structure from `templates/tracker.md`.
2. Preserve the user's real deadlines, constraints, and output preferences.
3. Create `outputs/` if it does not exist.
4. Create phase, month, and initial weekly sections if enough information exists.
5. Create empty rolling 30-day state sections if no history exists.
6. Identify active micro-sprints and ongoing commitments only when supported by the source material.
7. Write priority rules that prevent secondary work from crowding out the active phase.
8. Use `$life-energy-plan-normalizer` by default to extract, normalize, identify missing information, and draft priority rules. Escalate to `PlanNormalizerAgent` only when source plans conflict, are messy enough to risk invented priorities, or missing information affects schedule, deadline, or core priority and subagent tools are available.
9. Derive the custom project name from `user_plan.md`, then use automation names in the format `LifeEnergyManager - <project name> (<workflow type>)`.
10. Prepare scheduled-task instructions using these exact names for:
   - Monday-Saturday morning planning.
   - Monday-Saturday evening check-in.
   - Sunday light review.
11. When creating or updating local Codex scheduled tasks, follow `codex/prompts/automation.md` exactly for schedule encoding:
   - Use `RRULE` with `BYDAY`, `BYHOUR`, `BYMINUTE`, and `BYSECOND=0`.
   - Do not use `DTSTART;TZID=...`, floating `DTSTART`, or UTC `DTSTART...Z` for local wall-clock schedules.
   - Keep the user's timezone in the tracker/profile, but encode the local automation schedule as `BYHOUR`/`BYMINUTE`.

## Required Behavior

- Ask clarifying questions only for missing information that changes the schedule, deadline, or core priority.
- Do not create daily artifacts during setup.
- Do not invent project-specific priorities not supported by the plan.
- If the user's plan is messy, normalize it without requiring them to rewrite it.
- All persistent files created or updated by setup must be written under `outputs/`.
- Put the custom project name before the parentheses and the workflow type inside the parentheses.
- If the project name is missing, derive a short project name from the North Star and ask the user to confirm it before creating scheduled tasks.
- Scheduled task names must be `LifeEnergyManager - <project name> (morning planning)`, `LifeEnergyManager - <project name> (evening check-in)`, and `LifeEnergyManager - <project name> (Sunday review)`.
- Local automation RRULEs must use `BYHOUR` and `BYMINUTE` so the schedule summary and `Next run` remain consistent. Do not use `DTSTART;TZID=...`, floating `DTSTART`, or UTC `DTSTART...Z`.
- After creating or updating scheduled tasks, verify that both the visible schedule summary and `Next run` match the intended local time, allowing only a small scheduler delay of about 1-2 minutes.
- If the user's configured timezone differs from the computer's local scheduler timezone, ask which local wall-clock time should run before creating automations.
- `$life-energy-plan-normalizer` is the default bounded-analysis path when creating or updating `outputs/life_energy_tracker.md`.
- Use `PlanNormalizerAgent` only when codex/prompts/subagents.md escalation signals apply and subagent tools are available.
- Use `PlanNormalizerAgent` only for extraction, normalization, missing-info detection, and priority-rule drafting.
- If neither `$life-energy-plan-normalizer` nor a justified `PlanNormalizerAgent` path is available, record `PlanNormalizerAgent: main-thread fallback` and do the same structured pass in the main thread.
- The main thread must make final tracker, priority, and automation decisions.

## Output

Create or update:

- `outputs/life_energy_tracker.md`
- optional normalized copies:
  - `outputs/phase_plan.md`
  - `outputs/month_plan.md`
  - `outputs/profile.md`

Then summarize:

- the active phase,
- the current month target,
- the first weekly planning target,
- the automation task names,
- the recommended automation schedule,
- the local RRULE encoding used for each automation,
- whether visible schedule and `Next run` were verified after automation creation or update,
- any missing information,
- the required `Subagent calls` audit block.

```text
Subagent calls:
- PlanNormalizerAgent: skill used / subagent used / main-thread fallback / not needed
- Reason:
- Main-thread decision:
```
