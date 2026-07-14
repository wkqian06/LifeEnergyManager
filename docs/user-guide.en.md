# LifeEnergyManager User Guide

[中文指南](user-guide.zh-cn.md) · [Back to README](../README.md)

LifeEnergyManager is a daily planning manager built around real capacity and long-range goals. It does more than place tasks on today: it detects goal drift, requires due goals to close, checks whether new work would damage weekly/monthly/phase plans, and turns the confirmed day into an HTML workbench and a desktop wallpaper.

This guide is organized for use rather than implementation. It explains what the manager does, how a day flows, how to read the workflow diagram, what every HTML and wallpaper module means, and why the displays change in different situations.

## 1. What it is designed to solve

LifeEnergyManager puts five commonly conflicting needs into one workflow:

1. Select today's meaningful action from phase, month, week, micro-sprint, and ongoing-commitment goals.
2. Size the day from recent actual focus capacity instead of ideal working hours.
3. Distinguish a small adjustment, a plan correction, and a goal rebaseline when new work affects future plans.
4. Give every due goal an explicit ending so a goal cannot remain active forever through repeated date changes.
5. Feed actual minutes, outputs, blockers, and unplanned work into future estimates through the evening report.

A normal day produces:

- a confirmed Baseline / Stretch daily plan;
- an offline HTML workbench with saved entries;
- a static 2560×1440 desktop wallpaper;
- a Markdown evening report that can be copied or downloaded.

## 2. Concepts to understand first

### 2.1 Planning levels and Goal IDs

| Level | Example Goal ID | Meaning |
| --- | --- | --- |
| Phase | `PH-DISSERTATION` | A phase deliverable or milestone |
| Month | `MO-2026-07` | An outcome window that should close this month |
| Week | `WK-2026-07-13` | A result to deliver or close within the week |
| Micro-sprint | `MS-ANALYSIS` | A smaller multi-day unit of work |
| Commitment | `CM-REVIEW` | Accepted extra work that must remain visible until it exits |

Every closable goal needs a date, a hard/soft deadline type, an exit criterion, and a status. The Goal ID links the same goal across the tracker, plan files, HTML, wallpaper, and evening report.

### 2.2 Baseline, Stretch, and critical path

- **Baseline** is the core work to protect first. Its normal target is about three hours, but it is adjusted for historical capacity and the remaining day window.
- **Stretch** is optional work attempted only after the Baseline and when energy remains. Its normal upper range is about two hours.
- **Critical path** marks an action that directly affects an approaching goal, a key deliverable, or an exit criterion. An active alert requires the daily plan to protect at least one critical-path action.
- **Ongoing commitment slice** is today's portion of a multi-day commitment. Completing the slice does not close the commitment; closure is decided in the evening against its exit criterion.

### 2.3 Risk and feasibility

| Field | What it means | How to read it |
| --- | --- | --- |
| Proximity | Position relative to safe start and deadline | `normal`, `approaching`, `critical`, or `due` |
| Feasibility | Whether available capacity covers corrected remaining work | `green`, `yellow`, `red`, or `unknown` |
| Corrected remaining | Remaining minutes adjusted by historical estimate error | More realistic than the raw estimate |
| Safe capacity | Capacity that can be committed safely | expected capacity × 0.8 |
| Coverage | Safe capacity before the deadline ÷ corrected remaining work | `≥1.25` green; `1.05–1.24` yellow; `<1.05` red |
| Latest safe start | Last start date that preserves the final buffer | Reaching it normally makes the goal critical |
| Goal debt | Work moved out of its original window but still owed | Changing the deadline does not erase it |

Capacity uses up to 28 comparable working days, with the most recent seven weighted more heavily. With fewer than seven comparable days, the configured minimum focused-time target is used and confidence is low. Recovery, catch-up, illness, and travel days retain their labels but are not mixed directly with ordinary days.

### 2.4 Revision ID

`PR-YYYYMMDD-N` identifies one authoritative plan revision. Every affected tracker/plan file and both daily artifacts must use the same Revision ID. The suffix is a monotonic revision ordinal for the day, not the number of confirmation replies.

## 3. The complete daily flow

### 3.1 Morning planning

1. Read the tracker, phase/month plans, active goals, commitments, historical capacity, and current Revision ID.
2. Run Goal Drift Guard for closure, proximity, feasibility, cumulative delay, and Goal debt.
3. If a due goal has no ending, enter `closure_required`; daily planning and new artifacts stop until the user chooses a terminal outcome.
4. Ask for extra tasks and classify their urgency, duration, and effect on the mainline.
5. Use Plan Revision Gate to classify the change as `none`, `inline`, `correction`, or `rebaseline`.
6. When needed, enter correction mode, collect the dedicated confirmation(s), apply one atomic revision, and exit the mode explicitly.
7. Re-read the authoritative plan and produce a provisional daily plan with Goal Alerts.
8. Ask the user to confirm the final daily plan separately.
9. Persist the artifact lock before either renderer starts.
10. Generate HTML and wallpaper from the same Revision ID and run semantic and visual QA.

### 3.2 How Plan Revision Gate classifies changes

| Kind | Typical case | Correction mode | Confirmation |
| --- | --- | --- | --- |
| `none` | The input does not affect the plan | No | None |
| `inline` | Small next-week reorder, same-capacity substitution, commitment change within budget | No | One provisional-plan confirmation |
| `correction` | Baseline displacement, commitment-cap overflow, material critical-path or weekly-capacity change | Yes | One dedicated reply |
| `rebaseline` | Month/phase impact, infeasible original goal, accumulated drift, or repeated revisions | Yes | Three separate user replies |

The three replies for month, phase, and every rebaseline confirm facts, the change set, and feasibility/consequences. Changed facts reset progress to reply 1; a substantive change-set edit resets it to reply 2. The user can enter `退出计划修正` to discard the pending proposal. Exit is terminal: later replies cannot continue the abandoned confirmation sequence.

### 3.3 After the artifact lock

Once either HTML or PNG starts generating, same-day long-range correction is closed:

- weekly/monthly/phase plans are no longer edited;
- the daily HTML and PNG are not regenerated;
- new work is recorded as `Unplanned work`, `Unplanned minutes`, and `What it displaced`;
- the evening report stores the deviation, and the next morning decides whether a revision is necessary.

### 3.4 Evening check-in

The user copies or downloads the Generated report from the HTML and submits it to the evening check-in. The workflow updates completion, blockers, actual minutes, commitments, Planning Calibration, the three state scores, and tomorrow's first action. Clear evidence may close a goal early.

### 3.5 Sunday review

Sunday review summarizes the last seven days and audits closure, risk, cumulative delay, and Goal debt for every week/month/phase/micro-sprint/commitment goal. It chooses the next week's priorities instead of mechanically carrying every unfinished task forward.

## 4. Reading the workflow diagram

![LifeEnergyManager guarded workflow](../assets/workflow.svg)

The diagram deliberately groups detailed checks into a few modules a user can recognize:

| Region | Module | What it contains |
| --- | --- | --- |
| Daily loop | Plan the day | Goal Guard, capacity sizing, extra-task triage, any necessary plan correction, and final daily-plan confirmation |
| Daily loop | Run the plan | The confirmed checklist, HTML/wallpaper, and the Revision lock that starts with artifact generation |
| Daily loop | Reflect | Evening outputs, blockers, actual minutes, unplanned displacement, energy/drive signals, and tomorrow's first action |
| Adaptive loop | Planning memory | Goal Registry, closures, historical capacity, drift, revisions, and Goal debt |
| Side entries | Setup · once / Sunday review | Create the first living plan; close due goals and refocus the next week |

The two curved arrows are the core idea: Reflect records reality in Planning memory, and Planning memory sizes the next plan from that evidence. The diagram no longer expands every `closure_required` or correction-mode step. Instead, the red `due → close` and amber `material impact → revise` cues identify the two Guard paths; sections 3 and 8 explain terminal outcomes and the one/three-reply rules.

`Artifact start locks revisions` inside Run is the hard boundary: correction is possible only before HTML/PNG generation begins. The three bottom principles state that every due goal gets an ending, material changes remain user-confirmed, and one hard day never increases tomorrow's load as punishment.

For the actual Goal Drift Guard and Plan Modification decision, blocking, confirmation, and commit routes, see the [technical workflow](../REFERENCE.md#detailed-technical-workflow).

## 5. Wallpaper modules

The wallpaper is a static reminder. It does not contain editing controls, confirmation steps, or detailed calculations. Its layout is:

```text
Title / subtitle                         Task focus | Time mix
Task-category legend
[Goal Alert Strip: only when risk exists]
Progress row
Baseline tasks | Stretch tasks | Status and advice
Revision ID footer
```

| Module | What it shows | Purpose |
| --- | --- | --- |
| Title / subtitle | Date, phase/day type, or manual catch-up window | Identify the active day |
| Task focus | Dominant task category | Uses task-category color, not risk color |
| Time mix | Recommended Baseline and Stretch combination | Show the total daily commitment quickly |
| Task legend | Stable orange/blue/green/gray meanings | Keeps colors consistent across projects |
| Goal Alert Strip | Highest-risk goal, deadline, remaining work, required-today action | Appears only for approaching/critical/due |
| Progress row | Up to five week/sprint/commitment/month/phase progress items | Month is second-to-last and Phase is last |
| Baseline | Work that must be protected first | Left column |
| Stretch | Optional work after Baseline | Middle column; may shrink or show No stretch |
| Status and advice | Status summary, Today advice, Anti-distraction tip | Exactly three blocks in the right column |
| Revision footer | Active Revision ID | Confirms that wallpaper, HTML, and tracker match |

### Wallpaper display differences

| Situation | Display behavior |
| --- | --- |
| No risk | Goal Alert Strip disappears completely and its height is reclaimed |
| Approaching | Pale amber strip with an explicit `APPROACHING` label |
| Critical or Due | Pale red strip, deep-red accent, and explicit severity text |
| Multiple alerts | Only the highest-risk goal plus `N more goal alerts`; details remain in HTML |
| Manual catch-up | Subtitle shows the actual remaining window; missed time blocks are not presented as planned work |
| No Stretch today | Middle column is reduced or says `No stretch`; filler tasks are not invented |
| Copy is too long | Lower-priority detail or task count is reduced; ellipses and cryptic abbreviations are not used |

## 6. HTML Workbench modules

The HTML is the interactive workspace for the day. It works offline and saves entries in browser `localStorage`, so a refresh can restore the current state.

| Module | What it represents | When it changes |
| --- | --- | --- |
| Header summary | Date, Task focus, and Time mix | Follows today's category and capacity |
| Goal Guard Overview | All approaching/critical/due goals; green pass when none exist | Sorted `due → critical → approaching` |
| Feasibility cards | Corrected remaining, Safe capacity, Coverage/confidence | Changes with history and remaining work |
| Why this warning | History window, comparable days, labels, estimate factor, latest safe start, and explanation | Collapsed until the user opens it |
| Plan Revision Snapshot | Revision ID, affected levels, before/after, cumulative delay, Goal debt, status | Opens automatically when a revision occurred today; otherwise collapsed or hidden without data |
| Plan Stack | Phase, Month, Week, Sprint, and Commitment progress cards | HTML is not limited to the wallpaper's five-item row |
| Task-category legend | Stable orange/blue/green/gray task meanings | Does not change by project |
| Ongoing commitments | Today's slice for every accepted commitment | Done completes the slice, not the commitment itself |
| Today suggestion | Daily guidance and the user's Energy remaining / Predicted next-day drive scores | Self-scores enter the evening report and appear in history the next day |
| Recent state | Seven-day focus bars, energy/drive lines, advice, and calibration summary | Shows `Waiting For Recording` without prior reports |
| Baseline / Stretch | Task cards and execution records | Each card has Done, Status, Actual min, Note/output, and Blocker/next action |
| Global fields | Global blocker, tomorrow action, condition, agent work, and unplanned displacement | Supports evening attribution; it is not a long-range plan editor |
| Generated report | Tasks, alerts, revision, critical path, estimate/actual samples, and unplanned work | Updates with entries and can be copied or downloaded as `.md` |

### Reading the Recent state chart

- Gray bars: daily focus minutes on the left axis.
- Green solid line: energy remaining on the right 0–100 axis.
- Blue dashed line: predicted next-day drive on the right axis.
- Orange solid line: actual drive (night summary) on the right axis.
- The Perspective selector switches Energy remaining and Predicted drive together between Self, Agent blind, and Agent calibrated. Actual drive remains one agent value.
- Today's entries appear only after the evening report is processed, so they become visible on the next day.

## 7. What appears in different situations

| Situation | Conversation/workflow | HTML | Wallpaper |
| --- | --- | --- | --- |
| Ordinary day, no risk | Normal daily-plan confirmation | Green `Goal Guard passed` | No Alert Strip |
| Approaching goal | Protect one critical-path action | Amber alert with feasibility detail | Amber Alert Strip |
| Critical/due goal | Emphasize the required-today action; closure may be required | Deep-red banner and all sorted alerts | Highest-risk deep-red alert only |
| Due with no terminal outcome | `closure_required`; wait for user decision | No new daily HTML is generated | No new daily PNG is generated |
| Small next-week reorder | Inline; one provisional-plan confirmation | Snapshot normally remains collapsed | Footer uses the current/new revision when applicable |
| Month/phase/rebaseline | Correction mode, three replies, explicit exit | Snapshot opens with before/after and debt | Shows only the result and Revision ID, not confirmation steps |
| User exits correction | Proposal discarded; restore last confirmed version | Uses the prior authoritative revision | Uses the prior authoritative revision |
| New task after artifacts | No revision or regeneration | Record Unplanned work/minutes/displaced | Wallpaper does not change |
| Fewer than seven comparable days | Use configured fallback | Confidence is low | Shows only the conclusion, not the formula |
| At least seven comparable days | Use weighted historical capacity | Confidence may be high; evidence can expand | Still shows only concise alert copy |
| Multiple goal alerts | Daily Planner chooses the highest-priority action | Shows every alert | Highest alert plus remaining count |
| Manual catch-up | Plan only the remaining day | Labels the catch-up window | Adjusted subtitle and Baseline/Stretch |

## 8. How every goal must end

Every due goal must receive one of these labels:

| Terminal status | When to use it | Additional requirement |
| --- | --- | --- |
| `completed` | Exit criterion is satisfied | Record evidence |
| `partially_completed` | Part of the result is complete but the window ends | Dispose of remaining work; create a successor if continuing |
| `missed` | Exit criterion was not met before the window ended | Record reason and remaining-work disposition |
| `superseded` | A new goal formally replaces the old one | Point to the successor Goal ID |
| `dropped` | The work is explicitly abandoned | Record the reason; it cannot disappear silently |

When unfinished work continues, the old goal still closes and the new goal receives a new Goal ID, date, and exit criterion. Overwriting the old deadline is not a substitute for closure.

## 9. Four common examples

### Example 1: Swap two tasks next week

If total capacity, critical path, and higher-level plans stay unchanged, this is normally inline. It does not enter correction mode and is confirmed with the provisional daily plan.

### Example 2: Delay a phase deadline by one week

The manager checks whether the deadline is hard or soft, historical capacity, and Goal debt. A phase change is a rebaseline and needs three separate replies. An external hard deadline cannot move without new evidence; it is marked for renegotiation instead.

### Example 3: A goal is due today and only half complete

Morning enters `closure_required`. The user may choose `partially_completed`, record the completed result and remaining work, and create a successor. The old goal does not remain active.

### Example 4: A 45-minute task arrives after HTML and wallpaper exist

Long-range plans are not changed and artifacts are not regenerated. The user records the task, minutes, and displaced work in the HTML. Evening attribution stores it, and the next Guard run decides whether a correction is needed.

## 10. Where files and data live

Persistent runtime files stay under the user's `outputs/` directory:

- `outputs/life_energy_tracker.md`: Goal Registry, closure log, history, and active plan;
- `outputs/phase_plan.md` and `outputs/month_plan.md`: normalized long-range plans;
- `outputs/daily-workbenches/`: daily HTML files;
- `outputs/daily-wallpapers/`: daily PNG files;
- `outputs/daily-reports/`: optional saved Markdown reports;
- `outputs/artifact-locks/`: same-day artifact locks.

The original `user_plan.md` remains read-only. The tracker is the runtime single source of truth; conflicting plan sources must be surfaced rather than silently resolved.

## 11. Boundaries and safety

- Energy and drive scores are planning heuristics, not medical or psychological diagnoses.
- An incomplete day does not automatically increase tomorrow's load. The workflow first distinguishes overplanning, energy, blockers, external obligations, and avoidance.
- The wallpaper is a static reminder and excludes live progress, long process explanations, evening forms, and detailed Guard formulas.
- The HTML is a same-day recording tool, not a way to edit long-range plans after the artifact lock.
- Final artifacts may be presented only when Guard passes, every due goal has a terminal decision, correction mode is closed, the daily plan is confirmed, Revision IDs match, and visual QA passes.

For installation and platform setup, read the [README](../README.md). For exact prompt, skill, and file contracts, read the [REFERENCE](../REFERENCE.md).
