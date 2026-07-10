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

| Micro-sprint | Window | Current day | Target | Status | Notes |
| --- | --- | ---: | --- | --- | --- |
| [name] | [dates] | 0 / N | [target] | Planned | [notes] |

## Ongoing Commitments

Accepted extra work that outlives the day it was accepted - urgent deadline-driven
tasks and multi-day non-urgent tasks share this table. These rules are the single
source for the commitment lifecycle; workflow prompts reference them and must not
restate them:

- ENTRY: any accepted extra task that outlives today must enter this table with a
  decidable exit criterion (artifact exists / event happened / count reached), a
  deadline date + type (hard/soft; no real deadline -> soft = Entered + 14 days),
  and a placement policy in Daily allocation naming which budget daily slices draw
  from (default: stretch/secondary capped lanes, never primary baseline blocks).
  A criterion that depends on an external party enters as `paused (until: <condition>)`.
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
- EXIT: exit criterion met -> done immediately (a deadline never blocks early exit).
  Closing requires criterion evidence - a done slice card proves the slice only,
  never the whole commitment. On close, ask once whether follow-up work remains
  (-> new commitment or backlog). Terminal rows (done/dropped) leave the table the
  same evening; the Daily Log records one closing line:
  `Commitment closed: <name> - entered <d1>, exited <d2>, total <n>m, outcome <line>`.
  Absorption into a micro-sprint = dropped + note "absorbed into <sprint>", valid
  only if the criterion text moves into that sprint's Target/Notes or the user
  confirms it is covered.
- CAP: at most 3 active rows. New entries and paused rows returning to active pass
  the same cap check; on overflow the user picks which 3 stay. The user may declare
  done/drop/pause in any session; the receiving session writes the table and the
  closing line immediately.

| Commitment | Entered | Exit criterion | Deadline (date + hard/soft) | Estimate | Done | Remaining | Daily allocation (incl. placement policy) | Skip count | Status |
| --- | --- | --- | --- | ---: | ---: | ---: | --- | ---: | --- |

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
