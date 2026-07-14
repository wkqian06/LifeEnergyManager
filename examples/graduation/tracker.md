# Example LifeEnergyManager Tracker: Dissertation Workflow

Timezone: America/New_York
Primary deadline: dissertation first draft before spring graduation deadline
Initial sprint: Month 1 re-baseline
Active automation: Morning planning, evening check-in, Sunday review
Active plan revision: PR-YYYYMMDD-0

## Operating Rules

- Plan from the dissertation deadline down to today's tasks.
- Morning planning asks for extra tasks before finalizing.
- Extra tasks must be triaged and must replace, shrink, or defer something.
- Generate HTML and PNG only after the user confirms the plan.
- Run Goal Drift Guard before intake and block planning when a due goal lacks a
  terminal decision.
- Enter correction mode only before either artifact starts. Month, phase, and
  rebaseline changes require three separate user replies.
- Keep the HTML report as the main evening check-in artifact.
- The wallpaper is a static reminder, not a dashboard.
- Agent work must produce concrete artifacts.

## Goal Lifecycle And Feasibility Model

- Stable IDs use `PH-*`, `MO-YYYY-MM`, `WK-YYYY-MM-DD`, `MS-*`, and `CM-*`.
- Non-terminal states are `planned`, `active`, and `closure_required`.
- Terminal states are `completed`, `partially_completed`, `missed`,
  `superseded`, and `dropped`.
- `completed` needs evidence; `partially_completed` must route remaining work;
  `superseded` must identify a successor Goal ID.
- Goal feasibility uses the most recent 28 comparable workdays, gives the latest
  7 days more weight, and protects 20 percent of expected capacity as buffer.
- Goal debt is remaining work displaced outside its original plan window. Moving
  a date never erases it.

## Goal Baseline Registry

| Goal ID | Level | Original goal | Current goal | Original date/type | Current date/type | Exit criterion | Remaining estimate | Status | Revisions | Successor ID |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | ---: | --- |
| PH-DISSERTATION-DRAFT | phase | Re-baseline and core compression | Re-baseline and core compression | YYYY-MM-DD soft | YYYY-MM-DD soft | Readable chapter skeleton, result path, figure set v0, and revision checklist | 3600 min | active | 0 | — |
| MO-YYYY-MM | month | Close Manuscript A and make core analysis draftable | Close Manuscript A and make core analysis draftable | YYYY-MM-DD soft | YYYY-MM-DD soft | Manuscript closure state plus a validated analysis path | 1800 min | active | 0 | — |
| WK-YYYY-MM-DD | week | First closure and reviewable analysis path | First closure and reviewable analysis path | YYYY-MM-DD soft | YYYY-MM-DD soft | Three weekly outcomes have evidence or terminal labels | 900 min | planned | 0 | — |
| MS-MANUSCRIPT-A-EXIT | micro-sprint | Exit Manuscript A from daily workload | Exit Manuscript A from daily workload | YYYY-MM-DD soft | YYYY-MM-DD soft | Submitted, coauthor-ready, or externally blocked with evidence | 600 min | planned | 0 | — |

## Goal Closure Log

| Closed at | Goal ID | Terminal state | Evidence | Outcome/reason | Remaining work | Successor ID |
| --- | --- | --- | --- | --- | ---: | --- |

## Planning Calibration

| Date | Run context / day labels | Planned baseline | Actual baseline | Critical-path minutes | Planned outputs | Completed outputs | Completed-task samples (Goal ID; signature; planned; actual; ratio; critical-path) | Estimate factor | Unplanned minutes | What it displaced | Weekly output rate | Confidence |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | ---: | ---: | --- | ---: | --- |

## Plan Revision Log

| Revision ID | Trigger | Levels / Goal IDs | Before | After | Cumulative delay | Goal debt | Risk | Confirmations | Final state |
| --- | --- | --- | --- | --- | ---: | ---: | --- | ---: | --- |

## Goal Hierarchy

### North Star

- Complete a dissertation first draft before the spring graduation deadline.

### Primary Workstreams

1. Manuscript A closure
   - Current status: about 90 percent complete.
   - Current priority: exit quickly.

2. Core analysis framework
   - Current status: refactor underway.
   - Current priority: validate one analysis path.

3. Dataset workflow
   - Current status: optimization and tests underway.
   - Current priority: document workflow status.

### Secondary Or Capped Work

1. Optional modeling preparation
   - Cap: scope note only until core work is protected.

2. Framework-only side projects
   - Cap: minimal scaffolding only.

## Phase Plan

### Phase 1: Re-baseline and core compression

Goal ID: PH-DISSERTATION-DRAFT

Dates: Month 1, ending YYYY-MM-DD

Deadline type: soft

Primary outcome: remove old manuscript burden and make the core analysis chapter draftable.

Required outcomes:

- Manuscript A exits daily workload.
- Core analysis has one validated path.
- Chapter skeleton and figure slots exist.
- Dataset workflow status is documented.

Gate:

- End of Month 1: readable chapter skeleton, main result path, figure set v0, and remaining-revision checklist.

Exit criterion: the gate artifacts exist and have been reviewed.

## Monthly Plan

### Month 1

Goal ID: MO-YYYY-MM

Deadline: YYYY-MM-DD soft

Primary outcome: close Manuscript A and make core analysis draftable.

Monthly outcomes:

- Manuscript A moved to submitted/coauthor-ready/externally blocked.
- Core analysis path validated.
- Dataset workflow status documented.
- Secondary projects capped.

Priority rules:

- Include Manuscript A closure every weekday until it exits.
- Prefer core analysis over optional modeling.
- Treat side project scaffolding as capped maintenance.

Exit criterion: Manuscript A has a terminal label and one validated analysis path is saved as reviewable evidence.

## Weekly Plan

### Week of YYYY-MM-DD

Goal ID: WK-YYYY-MM-DD

Deadline: YYYY-MM-DD soft

Weekly outcomes:

- First closure move for Manuscript A.
- First reviewable path for core analysis.
- Dataset workflow notes started.

Exit criterion: the three outcomes have evidence or an explicit terminal disposition.

Agent-delegable tasks:

- Review code path and produce blocker list.
- Draft checklist for manuscript closure.

## Rolling 30-Day State

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

| Goal ID | Micro-sprint | Window / deadline | Current day | Target / exit criterion | Remaining | Status | Notes |
| --- | --- | --- | ---: | --- | ---: | --- | --- |
| MS-MANUSCRIPT-A-EXIT | Manuscript A exit | 5 days / YYYY-MM-DD soft | 0 / 5 | Exit daily workload with closure evidence | 600 min | planned | 3 main days plus 2 buffer days. |
| MS-CORE-CHAPTER-GATE | Core chapter gate | Month 1 / YYYY-MM-DD soft | 0 / N | Reviewable path and figure slots | 1200 min | planned | Needs main path and figure slots. |

## Ongoing Commitments

Accepted extra work that outlives the day it was accepted. Lifecycle rules live in
the table-header comment of `templates/tracker.md` (single source).

| Goal ID | Commitment | Entered | Exit criterion | Deadline (date + hard/soft) | Estimate | Done | Remaining | Daily allocation (incl. placement policy) | Skip count | Status |
| --- | --- | --- | --- | --- | ---: | ---: | ---: | --- | ---: | --- |

## Daily Log

### YYYY-MM-DD

- Awaiting first daily cycle.
