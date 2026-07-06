# LifeEnergyManager Scheduled Task Setup

Use this file when creating Codex scheduled tasks for a configured LifeEnergyManager workspace.

Automation names:

Use these scheduled-task name formats:

- `LifeEnergyManager - <project name> (morning planning)`
- `LifeEnergyManager - <project name> (evening check-in)`
- `LifeEnergyManager - <project name> (Sunday review)`

Use the project name from `user_plan.md`. If it is missing, derive a short project name from the North Star and confirm it with the user before creating tasks. The text inside parentheses is the workflow type.

## Schedule Encoding For Local Codex Automations

For local Codex cron automations, encode recurring local wall-clock times with
`BYHOUR`, `BYMINUTE`, and `BYSECOND` inside the `RRULE`. Do not encode the local
time with `DTSTART;TZID=...`, a floating `DTSTART`, or a UTC `DTSTART...Z`.

Rationale:

- Some Codex local scheduler versions display `DTSTART;TZID=...` correctly but
  compute `next_run_at` as if the time were UTC.
- UTC `DTSTART...Z` can make execution correct but makes the schedule display as
  UTC.
- `RRULE` with `BYHOUR` and `BYMINUTE` keeps the displayed schedule and the
  computed next run aligned for local automations.

Use these patterns:

```text
Morning:
RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA;BYHOUR=<morning hour 0-23>;BYMINUTE=<morning minute>;BYSECOND=0

Evening:
RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA;BYHOUR=<evening hour 0-23>;BYMINUTE=<evening minute>;BYSECOND=0

Sunday review:
RRULE:FREQ=WEEKLY;BYDAY=SU;BYHOUR=<weekly review hour 0-23>;BYMINUTE=<weekly review minute>;BYSECOND=0
```

Example for 08:30, 22:30, and Sunday 19:00:

```text
RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA;BYHOUR=8;BYMINUTE=30;BYSECOND=0
RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA;BYHOUR=22;BYMINUTE=30;BYSECOND=0
RRULE:FREQ=WEEKLY;BYDAY=SU;BYHOUR=19;BYMINUTE=0;BYSECOND=0
```

Keep the user's configured timezone in `outputs/profile.md` and
`outputs/life_energy_tracker.md`, but do not put `TZID` or `Z` in the local
automation RRULE. If the configured timezone differs from the computer's local
scheduler timezone, ask the user which local wall-clock time should run before
creating automations.

After creating or updating an automation, verify both:

- the schedule summary shows the intended local days and time;
- `Next run` is the intended local day and time, allowing for a small scheduler
  delay of about 1-2 minutes.

## Task 1: Morning Planning

Name:

`LifeEnergyManager - <project name> (morning planning)`

Cadence:

- Monday-Saturday.
- User's configured morning planning time.
- User's configured timezone.
- RRULE must follow the local Codex pattern above:
  `RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA;BYHOUR=<hour>;BYMINUTE=<minute>;BYSECOND=0`.

Prompt:

```text
Run morning planning for the configured LifeEnergyManager project today.

Read codex/prompts/subagents.md, outputs/life_energy_tracker.md, and the current plan files under outputs/. Follow codex/prompts/morning.md exactly:
- read the tracker and rolling state first,
- ask whether I have extra urgent, external, or tempting tasks today,
- use $life-energy-urgency-triage if I provide extra urgent, external, or tempting tasks,
- escalate to UrgencyTriageAgent only when codex/prompts/subagents.md escalation signals apply and subagent tools are available,
- use $life-energy-daily-planner for provisional plan options,
- escalate to DailyPlannerAgent only when intensity selection or workstream tradeoffs are bias-prone and subagent tools are available,
- use $life-energy-advice for readable HTML and wallpaper variants of status summary, today advice, and anti-distraction tip,
- escalate to AdviceAgent only when state interpretation or distraction pattern is unclear and subagent tools are available,
- determine the actual run context before drafting the plan: if I triggered this manually because Codex missed the scheduled run, or if the current local time is more than 60 minutes after the configured morning planning time, treat it as `manual_catchup`,
- for `manual_catchup`, plan only from the current local time to the configured evening check-in time, label the result as a remaining-time plan, and do not include already-missed morning or afternoon blocks,
- record main-thread fallback and complete the same structured pass in the main thread only if neither the matching skill nor a justified subagent path is available,
- triage extra tasks before accepting them and keep final acceptance in the main thread,
- produce a provisional plan with the required Subagent calls audit block,
- wait for my confirmation before generating HTML or PNG artifacts,
- after confirmation, generate the daily HTML workbench and wallpaper under outputs/,
- use ArtifactQAAgent for artifact QA when subagent tools are available because artifact QA is an independent-review task,
- if ArtifactQAAgent is unavailable, use $life-energy-artifact-qa,
- record main-thread fallback and complete artifact QA in the main thread only if neither ArtifactQAAgent nor $life-energy-artifact-qa is available,
- QA readability and layout before presenting the artifacts.
```

## Task 2: Evening Check-In

Name:

`LifeEnergyManager - <project name> (evening check-in)`

Cadence:

- Monday-Saturday.
- User's configured evening check-in time.
- User's configured timezone.
- RRULE must follow the local Codex pattern above:
  `RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA;BYHOUR=<hour>;BYMINUTE=<minute>;BYSECOND=0`.

Prompt:

```text
Run evening check-in for the configured LifeEnergyManager project today.

Read codex/prompts/subagents.md first. Ask me for the Markdown report generated by today's HTML workbench under outputs/daily-workbenches/. Follow codex/prompts/evening.md exactly:
- use the workbench report as the primary source,
- update daily log, rolling 30-day state, active micro-sprints, and settle the Ongoing Commitments table,
- save any standalone daily report under outputs/daily-reports/,
- use $life-energy-drive-resistance when enough report content exists,
- escalate to EnergyQuantAgent only when the report is ambiguous, emotionally strong, or the score would change next-day intensity and subagent tools are available,
- if only sparse data exists, ask for the minimal evening fields before energy inference,
- record main-thread fallback and infer beta next-day drive-resistance state in the main thread only if neither $life-energy-drive-resistance nor a justified EnergyQuantAgent path is available,
- never treat next-day drive-resistance state as diagnosis,
- define score direction as 0 = tomorrow's motivation/willingness is strong and 100 = tomorrow is likely to feel resistant, unwilling, or hard to start,
- save user drive-resistance self-score if present,
- generate tomorrow's first-action seed and likely focus mode,
- include the required Subagent calls audit block.
```

## Task 3: Sunday Review

Name:

`LifeEnergyManager - <project name> (Sunday review)`

Cadence:

- Sunday.
- User's configured weekly review time.
- User's configured timezone.
- RRULE must follow the local Codex pattern above:
  `RRULE:FREQ=WEEKLY;BYDAY=SU;BYHOUR=<hour>;BYMINUTE=<minute>;BYSECOND=0`.

Prompt:

```text
Run Sunday review for the configured LifeEnergyManager project.

Read codex/prompts/subagents.md first. Follow codex/prompts/sunday_review.md exactly:
- read outputs/life_energy_tracker.md and the last 7 daily logs from outputs/,
- use $life-energy-weekly-review before updating next week's plan,
- escalate to WeeklyReviewAgent when repeated deferrals, unclear blockers, or major priority changes need a second pass and subagent tools are available,
- record main-thread fallback and complete the same structured weekly review in the main thread only if neither $life-energy-weekly-review nor a justified WeeklyReviewAgent path is available,
- summarize the week,
- compress rolling 30-day state where appropriate,
- update next week's plan,
- list agent-delegable tasks,
- choose Monday's first action,
- keep the review light and do not create a full daily plan unless I ask,
- include the required Subagent calls audit block.
```

## Notes

- Prefer one persistent Codex thread for the workflow so the user can review the same planning history.
- Do not create duplicate automations if one already exists.
- Use the exact scheduled-task name formats `LifeEnergyManager - <project name> (morning planning)`, `LifeEnergyManager - <project name> (evening check-in)`, and `LifeEnergyManager - <project name> (Sunday review)`.
- Preserve the user's configured times and timezone when updating an existing automation.
- For local Codex automations, preserve configured local times by using `RRULE` `BYHOUR` and `BYMINUTE`; do not use `DTSTART;TZID=...`, floating `DTSTART`, or UTC `DTSTART...Z`.
- Verify after creation or update that the schedule summary and `Next run` agree on the intended local time.
- Matching LifeEnergyManager skills are the default bounded-analysis path. Use subagents only when codex/prompts/subagents.md escalation signals apply and subagent tools are available. Use main-thread fallback only when neither the matching skill nor a justified subagent path is available.
- If a morning planning task is run manually after Codex failed to launch at the scheduled time, the generated plan must be based on the remaining window from actual run time to the evening check-in time, not on the full day.
