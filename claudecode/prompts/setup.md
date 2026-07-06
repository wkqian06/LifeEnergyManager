# LifeEnergyManager Setup Prompt (Claude Code)

Use this prompt when a user has provided a phase plan, monthly plan, or a filled `user_plan.md`.

## Role

You are configuring a LifeEnergyManager workflow for the current user in Claude Code. Build a reusable tracker and routine prompt set from their supplied plan.

## Inputs

Read, in this order if available:

1. `claudecode/prompts/subagents.md`
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
8. Use the `life-energy-plan-normalizer` skill by default to extract, normalize, identify missing information, and draft priority rules. Escalate to the `plan-normalizer` subagent only when source plans conflict, are messy enough to risk invented priorities, or missing information affects schedule, deadline, or core priority.
9. Derive the custom project name from `user_plan.md`, then use automation names in the format `LifeEnergyManager - <project name> (<workflow type>)`.
10. Prepare routine instructions using these exact names for:
   - Monday-Saturday morning planning.
   - Monday-Saturday evening check-in.
   - Sunday light review.
11. When creating or updating Claude Code routines, follow `claudecode/prompts/automation.md` exactly:
   - Use Claude Code desktop local routines as the primary path, with the workspace root as the working directory and an interactive permission mode.
   - Use a system scheduler launching an interactive Claude Code session only as the fallback path.
   - Do not use cloud routines; they cannot ask questions mid-run or write the local `outputs/` directory.

## Required Behavior

- Ask clarifying questions only for missing information that changes the schedule, deadline, or core priority.
- Do not create daily artifacts during setup.
- Do not invent project-specific priorities not supported by the plan.
- If the user's plan is messy, normalize it without requiring them to rewrite it.
- All persistent files created or updated by setup must be written under `outputs/`.
- Put the custom project name before the parentheses and the workflow type inside the parentheses.
- If the project name is missing, derive a short project name from the North Star and ask the user to confirm it before creating routines.
- Routine names must be `LifeEnergyManager - <project name> (morning planning)`, `LifeEnergyManager - <project name> (evening check-in)`, and `LifeEnergyManager - <project name> (Sunday review)`.
- After creating or updating routines, verify per the Schedule Verification section of `claudecode/prompts/automation.md`: check the stored cron expression and the next run converted to local time, allowing several minutes of deterministic scheduler jitter; do not rely on the human-readable summary string.
- If the user's configured timezone differs from the computer's local scheduler timezone, ask which local wall-clock time should run before creating the routines.
- The `life-energy-plan-normalizer` skill is the default bounded-analysis path when creating or updating `outputs/life_energy_tracker.md`.
- Use the `plan-normalizer` subagent only when claudecode/prompts/subagents.md escalation signals apply.
- Use the `plan-normalizer` subagent only for extraction, normalization, missing-info detection, and priority-rule drafting.
- If neither the `life-energy-plan-normalizer` skill nor a justified `plan-normalizer` subagent path is available, record `PlanNormalizerAgent: main-thread fallback` and do the same structured pass in the main session.
- The main session must make final tracker, priority, and automation decisions.

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
- the routine names,
- the recommended automation schedule,
- the scheduling mechanism used for each routine (desktop local routine or system-scheduler fallback),
- whether the visible schedule and the displayed next run were verified after routine creation or update,
- any missing information,
- the required `Subagent calls` audit block.

```text
Subagent calls:
- PlanNormalizerAgent: skill used / subagent used / main-thread fallback / not needed
- Reason:
- Main-thread decision:
```
