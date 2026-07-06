# LifeEnergyManager Tracker

Timezone:
Primary deadline:
Initial sprint:
Active automation: LifeEnergyManager - [project name] (morning planning); LifeEnergyManager - [project name] (evening check-in); LifeEnergyManager - [project name] (Sunday review)
Output root: outputs/

## Operating Rules

- Daily plans should start from the highest-level goal and narrow down to the day.
- All persistent runtime outputs live under `outputs/`.
- Morning planning must ask about extra tasks before finalizing the day.
- Morning planning must determine run context before drafting tasks. If the
  Codex automation missed the scheduled start and the user runs it manually, or
  if the actual run time is more than 60 minutes after the configured morning
  planning time, plan only from actual run time to evening check-in.
- Extra tasks must be triaged before being accepted.
- Accepted extra tasks must replace, shrink, or defer another task unless there is real unused capacity.
- Morning artifacts are generated only after plan confirmation.
- The interactive HTML workbench is the primary low-friction reporting tool.
- The desktop wallpaper is a static reminder only.
- Artifact text must stay readable. HTML may use longer explanatory wording;
  wallpaper wording may be shorter but must not use cryptic shorthand or
  unexplained planning jargon.
- Next-day drive-resistance scoring is beta and used only for planning adjustment. `0` means tomorrow's motivation and willingness are strong, including physically tired today but still eager to continue; `100` means tomorrow is likely to feel resistant, unwilling, or hard to start.
- Do not punish an incomplete day by automatically increasing the next day.
- Agent work must produce concrete artifacts or reviewable outputs.

## Goal Hierarchy

### North Star

- [Long-term goal]

### Primary Workstreams

1. [Workstream]
   - Current status:
   - Current priority:

### Secondary Or Capped Work

1. [Workstream]
   - Cap:
   - Reason:

## Planning Layers

1. Phase plan:
2. Monthly plan:
3. Weekly plan:
4. Daily plan:

The daily workflow should always plan from the top down:

`primary deadline -> active phase -> current month -> current week -> today`

## Phase Plan

### Phase 1: [name]

Dates:

Primary outcome:

Required outcomes:

- [Outcome]

Gate:

- [Date]: [criterion]

### Phase 2: [name]

Dates:

Primary outcome:

Required outcomes:

- [Outcome]

Gate:

- [Date]: [criterion]

## Monthly Plan

### [Month YYYY]

Primary outcome:

Monthly outcomes:

- [Outcome]

Priority rules:

- [Rule]

Active micro-sprints:

- [Micro-sprint]

## Weekly Plan

### Week of [YYYY-MM-DD]

Weekly outcomes:

- [Outcome]

Planned focus:

- [Focus]

Agent-delegable tasks:

- [Task]

## Priority Rules For Scheduled Planning

- If a high-priority exit task is not closed, every weekday plan should include one concrete action for it.
- Primary workstreams are preferred over secondary scaffolding.
- Secondary projects are capped unless they directly support the active phase.
- A day with only agent launches and no human review/specification/writing does not count as a strong day.
- If a task is deferred for two consecutive days, schedule a smaller first action or admit it is not the current priority.

## Rolling 30-Day State

Retention rule:

- Keep the most recent 7 days relatively specific.
- Compress days 8-30 into weekly trend summaries unless a blocker, urgent task, or micro-sprint is still active.
- Archive or remove patterns after they have not affected planning for 30 days.

### Recent Focus Trend

- Not enough data yet.

### Next-Day Drive-Resistance Pattern

- Not enough data yet.

### Recurring Blockers

- Not enough data yet.

### Repeatedly Deferred Tasks

- Not enough data yet.

### Agent Tasks Pending Review

- None recorded yet.

## Active Micro-Sprints

| Micro-sprint | Window | Current day | Target | Status | Notes |
| --- | --- | ---: | --- | --- | --- |
| [name] | [dates] | 0 / N | [target] | Planned | [notes] |

## Temporary Urgent Tasks

Every accepted urgent task must have a daily allocation and an explicit tradeoff.

| Task | Deadline | Estimate | Done | Remaining | Status | Daily allocation | Replaces / tradeoff |
| --- | --- | ---: | ---: | ---: | --- | --- | --- |

## Dynamic Focus Intensity Rules

| Mode | Baseline | Stretch | Use when | Planning rule |
| --- | ---: | ---: | --- | --- |
| Recovery | 2h | +1h | Low energy, repeated fatigue, or day after overextension | Preserve one primary task and one tiny maintenance task. |
| Standard | 3h | +2h | Normal condition and no immediate deadline crisis | Default mode. Keep plan realistic and artifact-driven. |
| Push | 3.5-4h | +1-2h | Energy acceptable and a gate or micro-sprint needs catch-up | Add time by extending primary work, not by adding new task types. |
| Deadline | 5h protected | optional only after delivery | Real deadline within 1-2 days or external handoff due | Drop low-value tasks; protect delivery and recovery after completion. |

## Daily Log

### [YYYY-MM-DD]

- Awaiting first daily planning/check-in cycle.
