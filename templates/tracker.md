# LifeEnergyManager Tracker

Timezone:
Primary deadline:
Initial sprint:
Active plan revision: PR-[YYYYMMDD]-0
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
- Every finishable phase, month, week, micro-sprint, and ongoing commitment must
  have a stable Goal ID, a decidable exit criterion, a deadline or dated window,
  and exactly one terminal outcome before it leaves active planning.
- Goal Guard preflight runs before morning intake. A due goal without closure
  evidence becomes `closure_required`; normal planning and artifact generation
  stop until the user chooses a terminal outcome.
- Persistent plan changes pass through the Plan Revision Gate. Correction mode
  exists only before either daily artifact has started. Once either today's HTML
  or PNG exists, later changes are execution deviations for the evening report
  and the next morning's impact audit, never a same-day plan revision.
- Morning artifacts are generated only after plan confirmation.
- The interactive HTML workbench is the primary low-friction reporting tool.
- The desktop wallpaper is a static reminder only.
- Artifact text must stay readable. HTML may use longer explanatory wording;
  wallpaper wording may be shorter but must not use cryptic shorthand or
  unexplained planning jargon.
- Daily scoring uses three metrics, all 0-100 and all same-direction (higher = better/more). See the Daily Scoring Model section for definitions.
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

New evidence also travels upward before the daily plan is drafted:

`morning input -> plan-impact audit -> commitment/week/month/phase correction -> reread confirmed hierarchy -> today`

## Goal Lifecycle And Feasibility Model

This section is the single source for goal identity, closure, proximity,
feasibility, drift, confirmation, and artifact-lock rules. Workflow prompts and
skills reference it and must not restate competing definitions.

### Goal identity and lifecycle

- Stable ID prefixes: phase `PH-`, month `MO-YYYY-MM`, week
  `WK-YYYY-MM-DD`, micro-sprint `MS-`, ongoing commitment `CM-`.
- Non-terminal states: `planned`, `active`, `closure_required`.
- Terminal outcomes: `completed`, `partially_completed`, `missed`,
  `superseded`, `dropped`.
- `completed` requires exit-criterion evidence. `partially_completed` requires
  an outcome plus a disposition for every remaining item. `superseded` requires
  a successor Goal ID. `missed` and `dropped` require a reason and a remaining-
  work disposition.
- At or after a goal's deadline/window end, missing closure evidence sets
  `closure_required`. Ask the user to select the terminal outcome and stop the
  workflow until they answer. Continuing unfinished work creates a new
  successor goal; never roll the old deadline forward or keep the old goal
  active.
- Active plan tables may remove terminal rows only after the Goal Closure Log
  has received the complete closing record.

### Historical capacity and feasibility

- Use up to 28 valid working days; weight the most recent 7 days more heavily.
  Tag Recovery, manual catch-up, illness, travel, and externally constrained
  days and do not mix them silently with comparable normal days.
- With at least 7 comparable days, expected daily capacity is the recency-
  weighted median of actual critical-path minutes; safe daily capacity is 80%
  of expected capacity. With fewer than 7 comparable days, use the configured
  minimum focused-time target and mark confidence `low`.
- Estimate factor is the median `actual / planned` ratio for comparable
  completed tasks, clamped to 1.0-2.0. With fewer than 3 comparable tasks, use
  1.25 and mark confidence `low`.
- Corrected remaining work = recorded remaining estimate x estimate factor.
  Available safe capacity = safe daily capacity x eligible remaining workdays,
  minus fixed obligations, active commitment allocations, and known unavailable
  time.
- Coverage = available safe capacity / corrected remaining work:
  `green >= 1.25`, `yellow = 1.05-1.24`, `red < 1.05`. If required inputs are
  missing, feasibility is `unknown`; never report an unknown or red path as
  on-track.
- Proximity is independent of feasibility: `normal`, `approaching`, `critical`,
  `due`. `critical` applies when the latest safe start is today/past, coverage is
  red, or buffer is exhausted. `approaching` is derived from corrected work,
  safe capacity, and remaining workdays; a fixed date window is only a fallback.

### Goal drift guard

- Preserve the original target and original deadline. Every revision compares
  against both the previous version and the original baseline.
- Goal debt is corrected remaining work moved outside the original plan window
  while the obligation remains active. Changing a date never clears goal debt.
- Any external hard-deadline change requires evidence that the external date
  changed; otherwise record `renegotiation required` and keep the hard date.
- Repeated revisions, cumulative delay, growing goal debt, an altered exit
  criterion, or an infeasible original path trigger a goal-protection review.
  If the original target is no longer the target, ordinary correction is
  blocked and the change becomes a rebaseline with a terminal old goal and a
  new Goal ID.

### Revision gate and confirmations

- `inline`: a small future-week reorder or commitment adjustment that remains
  inside existing placement capacity, preserves dependencies and critical-path
  order, and does not change a month/phase gate. It rides the final daily-plan
  confirmation.
- `correction`: baseline displacement, commitment-cap overflow, material weekly
  capacity/sequence change, or any month/phase impact. Announce entry, affected
  levels, current confirmation progress, artifact-not-started status, and the
  exit phrase `退出计划修正`.
- Commitment/week-only correction uses one dedicated confirmation. Any month or
  phase change and every rebaseline uses three separate user replies: facts;
  before/after change set; feasibility and consequences. A facts change resets
  to confirmation 1; a material change-set edit resets to confirmation 2.
- Stage all changes in conversation before confirmation. After confirmation,
  apply one Revision ID across all affected output files and update `Active plan
  revision` last as the commit marker. On failure, restore the pre-change
  content, keep the old active revision, and do not generate artifacts.
- After a successful correction, announce exit, list the changes and risk, give
  the first mainline action, reread the confirmed hierarchy, then draft and ask
  for a separate final daily-plan confirmation.
- In `PR-YYYYMMDD-N`, `N` is the next monotonic revision ordinal for that date;
  it is not the number of confirmation replies. A three-reply change consumes
  one revision ordinal.

### Artifact lock

- Correction mode may start only when neither
  `outputs/daily-workbenches/YYYY-MM-DD-workbench.html` nor
  `outputs/daily-wallpapers/YYYY-MM-DD-daily-plan.png` exists or has started.
  Before either renderer starts, write
  `outputs/artifact-locks/YYYY-MM-DD.json` with the date, active Revision ID,
  first artifact, and status `started`. Its existence is authoritative even
  after an interrupted render. Update it to `html_complete`, `png_complete`,
  or `complete` as generation progresses; never delete it to reopen correction
  mode for that day.
- Both artifacts carry the active Revision ID and the same highest-priority Goal
  Alert. If either artifact has started, finish the pair from that confirmed
  snapshot; do not revise or regenerate the plan that day.
- Post-artifact changes are recorded as unplanned work, minutes, and displaced
  work in the HTML report, settled in the evening, and audited next morning.

## Goal Baseline Registry

All finishable targets remain here, including terminal targets. Detailed plan
sections and active tables reference these Goal IDs.

| Goal ID | Level | Original target | Current target | Original deadline (date + hard/soft) | Current deadline (date + hard/soft) | Exit criterion | Remaining estimate | State / terminal outcome | Revisions | Successor Goal ID |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | ---: | --- |
| [ID] | [phase/month/week/micro-sprint/commitment] | [original] | [current] | [date + type] | [date + type] | [criterion] | [minutes] | planned | 0 | |

## Goal Closure Log

| Goal ID | Closed at | Terminal outcome | Exit evidence | Outcome | Reason | Remaining-work disposition | Successor Goal ID |
| --- | --- | --- | --- | --- | --- | --- | --- |

## Planning Calibration

| Date | Run context / day labels | Planned baseline min | Actual baseline min | Critical-path min | Planned outputs | Completed outputs | Completed-task estimate samples (Goal ID; task signature; planned; actual; ratio; critical-path) | Estimate factor | Unplanned min | What it displaced | Weekly output completion rate | Confidence note |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | ---: | ---: | --- | ---: | --- |

## Plan Revision Log

| Revision ID | Date | Trigger | Goal IDs / levels | Before -> after | Cumulative delay | Goal debt | Feasibility | Confirmations | Status |
| --- | --- | --- | --- | --- | ---: | ---: | --- | --- | --- |

## Phase Plan

### Phase 1: [name]

Goal ID: PH-[name]

Dates:

Deadline type: hard / soft

Primary outcome:

Required outcomes:

- [Outcome]

Gate:

- [Date]: [criterion]

### Phase 2: [name]

Goal ID: PH-[name]

Dates:

Deadline type: hard / soft

Primary outcome:

Required outcomes:

- [Outcome]

Gate:

- [Date]: [criterion]

## Monthly Plan

### [Month YYYY]

Goal ID: MO-YYYY-MM

Deadline: [YYYY-MM-DD + hard/soft]

Primary outcome:

Monthly outcomes:

- [Outcome]

Priority rules:

- [Rule]

Active micro-sprints:

- [Micro-sprint]

## Weekly Plan

### Week of [YYYY-MM-DD]

Goal ID: WK-YYYY-MM-DD

Deadline: [YYYY-MM-DD + hard/soft]

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
- If a task is deferred for two consecutive days, schedule a smaller first action or admit it is not the current priority. This rule does not apply to Ongoing Commitments; their absence is tracked by Skip count instead.

## Daily Scoring Model

Single source for the three daily metrics. All are 0-100 and same-direction (higher = better/more); they share one chart axis. Definitions and field keys must not be restated elsewhere - other files reference this section.

- **Energy remaining** (`remainingSelf` / `remainingBlind` / `remainingCalibrated`): energy left after today. `0` = depleted, `100` = full. A next-day planning input: yesterday's remaining energy helps size today.
- **Predicted next-day drive** (`predDriveSelf` / `predDriveBlind` / `predDriveCalibrated`): drive expected tomorrow. `0` = hard to start, `100` = strong drive. A forecast, compared to the next day's actual drive (night summary) for calibration; the comparison is not a planning input.
- **Actual drive (night summary)** (`actualDrive`, single agent value from the evening report): the drive and energy you actually had to act that day - roughly how much you were able to get done, though not a strict output count - assessed from the evening report. This is the realized counterpart of the prior night's predicted next-day drive. Same scale as predicted drive. A next-day planning input; also compared against the prior night's `predDriveCalibrated` for calibration only.

Scoring rules:

- The agent produces `*Blind` values from report evidence only, before reading any user self-score. It then reads the user self-scores and produces `*Calibrated`; blind values are never edited afterward. `actualDrive` is a single blind value (no calibration, anchored on focus minutes and completions).
- A blind-vs-self gap of 30+ points on the drive prediction is a planning signal - surface it.
- Prediction is stored under the day it targets: tonight's `predDrive*` is written into tomorrow's row so it aligns with tomorrow's `actualDrive`.
- Next-day planning is informed by the previous day's energy remaining and actual drive (night summary), using the agent-calibrated variant as the primary signal (`remainingCalibrated`; actual drive (night summary) is a single agent value). The predicted-vs-actual comparison is recorded for calibration only and does not drive planning.

## Rolling 30-Day State

Retention rule:

- Keep the most recent 7 days relatively specific.
- Compress days 8-30 into weekly trend summaries unless a blocker, ongoing commitment, or micro-sprint is still active.
- Archive or remove patterns after they have not affected planning for 30 days.

### Recent Focus Trend

- Not enough data yet.

### Drive And Energy Pattern

- Not enough data yet.

### Recurring Blockers

- Not enough data yet.

### Repeatedly Deferred Tasks

- Not enough data yet.

### Agent Tasks Pending Review

- None recorded yet.

## Active Micro-Sprints

| Goal ID | Micro-sprint | Window / deadline (date + type) | Current day | Target / exit criterion | Remaining estimate | Status | Notes |
| --- | --- | --- | ---: | --- | ---: | --- | --- |
| MS-[name] | [name] | [dates + hard/soft] | 0 / N | [decidable criterion] | [minutes] | planned | [notes] |

## Ongoing Commitments

Accepted extra work that outlives the day it was accepted - urgent deadline-driven
tasks and multi-day non-urgent tasks share this table. These rules are the single
source for the commitment lifecycle; workflow prompts reference them and must not
restate them:

- ENTRY: any accepted extra task that outlives today must enter this table with a
  stable `CM-*` Goal ID, a decidable exit criterion (artifact exists / event
  happened / count reached), a
  deadline date + type (hard/soft; no real deadline -> soft = Entered + 14 days),
  and a placement policy in Daily allocation naming which budget daily slices draw
  from (default: stretch/secondary capped lanes, never primary baseline blocks).
  A criterion that depends on an external party remains lifecycle state `active`
  and records operational disposition `paused (until: <condition>)` in Daily
  allocation or Notes; `paused` is not a lifecycle state.
- DAILY: every active row gets a disposition in the morning Commitments digest -
  a suggested today-slice sized as Remaining / remaining working days before the
  deadline (shrunk on Recovery days, prioritized near deadlines), or an explicit
  skip with a one-line reason. Coverage invariant: the digest opens with
  "Commitments: N active, N dispositions"; a plan missing any active row is
  non-conforming. If feasibility requires more than the placement budget, the
  digest raises an explicit conflict decision (approve mainline displacement today
  [user only] / reduce scope / extend / drop) - never silent, never deferred to expiry.
- COUNTING: Skip count is written only by evening settlement: a day ending with 0
  actual minutes on an active row -> +1; >0 minutes -> reset to 0; done/in-progress/
  blocked cards -> unchanged. Compressed-plan (catch-up) and Recovery days: no +1,
  no reset, transparent to continuity.
- INQUIRY: Skip count >= 3, or a hard deadline has passed -> the next morning digest
  carries a preset-recommendation inquiry: continue (reset + new allocation) /
  pause (with resume condition) / drop. Deferred past Recovery/compressed mornings.
- EXIT: exit criterion met -> `completed` immediately (a deadline never blocks
  early exit). Closing requires criterion evidence - a done daily task card proves the slice only,
  never the whole commitment. Write the Goal Closure Log before removing the
  active row. On close, ask once whether follow-up work remains
  (-> new commitment or backlog). Rows with one of the five terminal outcomes leave the table the
  same evening; the Daily Log records one closing line:
  `Commitment closed: <name> - entered <d1>, exited <d2>, total <n>m, outcome <line>`.
  The terminal labels are exactly `completed`, `partially_completed`, `missed`,
  `superseded`, and `dropped`. Absorption into a micro-sprint = `superseded`
  with successor Goal ID and note "absorbed into <sprint>", valid
  only if the criterion text moves into that sprint's Target/Notes or the user
  confirms it is covered.
- CAP: at most 3 active rows. New entries and paused rows returning to active pass
  the same cap check; on overflow the user picks which 3 stay. The user may declare
  done/drop/pause in any session; map these commands to lifecycle
  `completed`/`dropped`/operational pause respectively. The receiving session
  writes terminal outcomes to the closure log and removes the active row, or
  records the pause disposition without changing lifecycle state.

The active table's `Status` field uses only `planned`, `active`, or
`closure_required`. A terminal outcome is written to the Registry and Closure
Log before the row leaves this table.

| Goal ID | Commitment | Entered | Exit criterion | Deadline (date + hard/soft) | Estimate | Done | Remaining | Daily allocation (incl. placement policy) | Skip count | Status |
| --- | --- | --- | --- | --- | ---: | ---: | ---: | --- | ---: | --- |

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
