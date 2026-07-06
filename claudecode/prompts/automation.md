# LifeEnergyManager Routine Setup (Claude Code)

Use this file when creating Claude Code routines for a configured LifeEnergyManager workspace.

Automation names:

Use these routine name formats:

- `LifeEnergyManager - <project name> (morning planning)`
- `LifeEnergyManager - <project name> (evening check-in)`
- `LifeEnergyManager - <project name> (Sunday review)`

Use the project name from `user_plan.md`. If it is missing, derive a short project name from the North Star and confirm it with the user before creating routines. The text inside parentheses is the workflow type.

## Scheduling Mechanism For Claude Code

The three workflows need to read and write local files under `outputs/` and, in the morning, ask the user questions before finalizing the plan. Choose the mechanism accordingly:

### Primary path: Claude Code desktop local routines

Create the three automations as **local routines** in the Claude Code desktop app (Routines -> New routine -> Local), or by asking Claude Code in the workspace to create them.

Requirements for each routine:

- The working directory must be the user's LifeEnergyManager workspace root, so `outputs/`, `templates/`, and `claudecode/prompts/` resolve correctly.
- Use the `default` permission mode (or another interactive mode). Do not use a fully non-interactive mode for the morning routine: it must be able to ask about extra tasks and wait for plan confirmation.
- The desktop app must be running at the scheduled time. If the machine was asleep or the app was closed, the scheduler runs one catch-up session for the most recent missed time; treat a catch-up morning run as a normal morning run for today.

### Fallback path: system scheduler + Claude Code CLI

If the desktop app is unavailable, create OS-level scheduled tasks that open an interactive Claude Code session in the workspace with the task prompt. Example for Windows Task Scheduler:

```text
Program:  wt
Arguments: -d "<workspace path>" powershell -NoExit -Command "claude '<task prompt from this file>'"
```

Use the same triggers as the cadence sections below (Monday-Saturday or Sunday, at the user's configured local times). Headless mode (`claude -p "..."`) is only acceptable for non-interactive variants; the standard morning workflow requires an interactive session.

### Why not cloud routines

Do not use Claude Code cloud routines (claude.ai scheduled cloud agents) for this workflow:

- Cloud routines run autonomously and cannot ask the user questions mid-run, which breaks the morning intake and confirmation steps.
- Cloud routines cannot read or write the user's local `outputs/` directory, which is the persistent state root of this workflow (and is gitignored, so it is not in any remote copy).

## Schedule Verification

After creating or updating a routine, verify both:

- the stored schedule (cron expression, if exposed) matches the intended local days and time;
- the displayed next run, converted to local time, lands on the intended local day and base time, allowing for the scheduler's deterministic load-balancing jitter of several minutes (exposed as `jitterSeconds` on the routine).

Known platform caveats (verified 2026-07):

- The human-readable schedule summary can render day ranges incorrectly (for example, Monday-Saturday shown as "only on Monday"). Treat the stored cron expression plus the computed next run as the source of truth, never the summary string.
- The scheduled-tasks tool surface has no programmatic delete. Disabling a routine stops runs but keeps it listed; to fully remove one, delete it from the desktop app sidebar (Routines/Scheduled).

Keep the user's configured timezone in `outputs/profile.md` and `outputs/life_energy_tracker.md`. Local routines run on the computer's local clock; if the configured timezone differs from the computer's timezone, ask the user which local wall-clock time should run before creating the routines.

## Routine 1: Morning Planning

Name:

`LifeEnergyManager - <project name> (morning planning)`

Cadence:

- Monday-Saturday.
- User's configured morning planning time.
- User's configured timezone (see Schedule Verification above).

Prompt:

```text
Run morning planning for the configured LifeEnergyManager project today.

Read claudecode/prompts/subagents.md, outputs/life_energy_tracker.md, and the current plan files under outputs/. Follow claudecode/prompts/morning.md exactly:
- read the tracker and rolling state first,
- if this run is a catch-up for a missed morning slot (current time clearly past the configured morning time, e.g. past midday), follow the Catch-Up Runs rule in claudecode/prompts/morning.md: plan a compressed remainder-of-day instead of a full day and label it a catch-up plan,
- ask whether I have extra urgent, external, or tempting tasks today,
- use the life-energy-urgency-triage skill if I provide extra urgent, external, or tempting tasks,
- escalate to the urgency-triage subagent only when claudecode/prompts/subagents.md escalation signals apply,
- use the life-energy-daily-planner skill for provisional plan options,
- escalate to the daily-planner subagent only when intensity selection or workstream tradeoffs are bias-prone,
- use the life-energy-advice skill for readable HTML and wallpaper variants of status summary, today advice, and anti-distraction tip,
- escalate to the advice subagent only when state interpretation or the distraction pattern is unclear,
- record main-thread fallback and complete the same structured pass in the main session only if neither the matching skill nor a justified subagent path is available,
- triage extra tasks before accepting them and keep final acceptance in the main session,
- produce a provisional plan with the required Subagent calls audit block,
- wait for my confirmation before generating HTML or PNG artifacts,
- after confirmation, generate the daily HTML workbench and wallpaper under outputs/,
- use the artifact-qa subagent for artifact QA because artifact QA is an independent-review task,
- if the artifact-qa subagent is unavailable, use the life-energy-artifact-qa skill,
- record main-thread fallback and complete artifact QA in the main session only if neither the artifact-qa subagent nor the life-energy-artifact-qa skill is available,
- QA readability and layout before presenting the artifacts.
```

## Routine 2: Evening Check-In

Name:

`LifeEnergyManager - <project name> (evening check-in)`

Cadence:

- Monday-Saturday.
- User's configured evening check-in time.
- User's configured timezone (see Schedule Verification above).

Prompt:

```text
Run evening check-in for the configured LifeEnergyManager project today.

Read claudecode/prompts/subagents.md first. Ask me for the Markdown report generated by today's HTML workbench under outputs/daily-workbenches/. Follow claudecode/prompts/evening.md exactly:
- use the workbench report as the primary source,
- update daily log, rolling 30-day state, active micro-sprints, and temporary urgent tasks,
- save any standalone daily report under outputs/daily-reports/,
- use the life-energy-drive-resistance skill when enough report content exists,
- escalate to the energy-quant subagent only when the report is ambiguous, emotionally strong, or the score would change next-day intensity,
- if only sparse data exists, ask for the minimal evening fields before energy inference,
- record main-thread fallback and infer beta next-day drive-resistance state in the main session only if neither the life-energy-drive-resistance skill nor a justified energy-quant subagent path is available,
- never treat next-day drive-resistance state as diagnosis,
- define score direction as 0 = tomorrow's motivation/willingness is strong and 100 = tomorrow is likely to feel resistant, unwilling, or hard to start,
- save user drive-resistance self-score if present,
- generate tomorrow's first-action seed and likely focus mode,
- include the required Subagent calls audit block.
```

## Routine 3: Sunday Review

Name:

`LifeEnergyManager - <project name> (Sunday review)`

Cadence:

- Sunday.
- User's configured weekly review time.
- User's configured timezone (see Schedule Verification above).

Prompt:

```text
Run Sunday review for the configured LifeEnergyManager project.

Read claudecode/prompts/subagents.md first. Follow claudecode/prompts/sunday_review.md exactly:
- read outputs/life_energy_tracker.md and the last 7 daily logs from outputs/,
- use the life-energy-weekly-review skill before updating next week's plan,
- escalate to the weekly-review subagent when repeated deferrals, unclear blockers, or major priority changes need a second pass,
- record main-thread fallback and complete the same structured weekly review in the main session only if neither the life-energy-weekly-review skill nor a justified weekly-review subagent path is available,
- summarize the week,
- compress rolling 30-day state where appropriate,
- update next week's plan,
- list agent-delegable tasks,
- choose Monday's first action,
- keep the review light and do not create a full daily plan unless I ask,
- include the required Subagent calls audit block.
```

## Notes

- Prefer resuming the same workspace so the user can review the same planning history; each scheduled run starts a fresh session, and the persistent state lives in `outputs/life_energy_tracker.md`, not in the conversation.
- Do not create duplicate routines if one already exists.
- Use the exact routine name formats `LifeEnergyManager - <project name> (morning planning)`, `LifeEnergyManager - <project name> (evening check-in)`, and `LifeEnergyManager - <project name> (Sunday review)`.
- Preserve the user's configured times and timezone when updating an existing routine.
- Verify after creation or update per Schedule Verification above: stored cron expression + next run in local time, allowing several minutes of deterministic jitter; do not rely on the summary string.
- Matching LifeEnergyManager skills (`.claude/skills/life-energy-*`) are the default bounded-analysis path. Use subagents (`.claude/agents/`) only when claudecode/prompts/subagents.md escalation signals apply. Use main-thread fallback only when neither the matching skill nor a justified subagent path is available.
- Daily artifact QA must include both readability QA and layout QA. If wallpaper space is tight, reduce detail instead of using cryptic wording.
