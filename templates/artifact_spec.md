# LifeEnergyManager Artifact Specification

Use this specification whenever generating daily artifacts.

## HTML Workbench

Required file:

- `outputs/daily-workbenches/YYYY-MM-DD-workbench.html`

Required behavior:

- Work offline as a local HTML file.
- Persist entries in browser `localStorage`. Validate and migrate legacy shapes,
  preserve recoverable task/field values, show load failures visibly, and back
  up an unreadable raw value before the next save.
- Carry `planRevisionId`; artifact generation requires a passed Goal Drift Guard, a closed correction mode, and the same active Revision ID used by the tracker and wallpaper.
- If the plan was generated as a manual catch-up run, present it as a remaining-time plan from actual run time to evening check-in. Do not show elapsed morning or afternoon work as planned work.
- Include a stable task-category color legend near the top of the workbench:
  - Orange: urgent/external/deadline.
  - Blue: deliverable/closure/visible output.
  - Green: deep research/analysis/implementation.
  - Gray: planning/log/admin/stop.
- Include baseline tasks, stretch tasks, and accepted urgent tasks.
- The plan-stack progress cards carry a `kind` class (phase | month | week | sprint | commitment) rendered as a small uppercase chip, so progress types are visually classified. The workbench sorts the cards by category order (phase, then month, then week, then sprint, then commitment; original order kept within a category), regardless of the order supplied in the stack. Ongoing commitments MAY each have a progress card here (percent = recorded Done minutes vs total estimate, midpoint of a range); the HTML has no five-bar cap - that cap applies to the wallpaper progress row only.
- The top-right header summary must show exactly:
  - today's overall task focus type, colored with its task-category color,
  - recommended time combination, for example `4 H Baseline + 1 H Stretch`.
- Directly below the header, keep a full-width Goal Guard Overview visible. With
  no alerts it shows a compact green text-labeled `pass` state; otherwise sort
  alerts `due`, `critical`, `approaching` and emphasize the highest severity
  without relying on color alone.
- Goal Guard Overview shows Goal ID/level, original/current deadline, proximity,
  feasibility, required-today action, and three visible summaries: corrected
  remaining work, safe capacity, and coverage/confidence. Put only the history
  window and day labels, comparable-day count, estimate factor, latest safe
  start, and risk explanation inside a disclosure block.
- Include a read-only Plan Revision Snapshot with Revision ID, affected levels, before/after, cumulative delay, goal debt, feasibility, and status. It is expanded only when `revisionSummary.changedToday` is true.
- Layout the top control area as two first-row modules, `Ongoing commitments (today's slices)` and `Today suggestion`, followed by `Recent state` on the next row spanning the full HTML width.
- For status summary, today advice, and anti-distraction guidance, prefer longer HTML-specific fields when present, such as `statusSummaryHtml`, `todayAdviceHtml`, and `antiDistractionTipHtml`. Fall back to the wallpaper fields only when no HTML-specific text is provided.
- Each task has:
  - done checkbox,
  - status,
  - actual minutes,
  - note/output,
  - blocker/next action.
- Include minimal global fields:
  - global blocker,
  - tomorrow first action,
  - energy/condition,
  - agent work launched/reviewed.
  - unplanned work,
  - unplanned minutes,
  - what it displaced.
- Generate a Markdown report from the task fields.
- The report includes Revision ID, Goal Alerts, planned/actual baseline minutes,
  critical-path minutes, planned/completed output counts, weekly output
  completion rate, and one structured completed-task estimate sample per task
  (Goal ID, task signature, planned/actual minutes, ratio, and critical-path
  flag), plus unplanned work/displacement so evening processing can update
  Planning Calibration.
- Include Copy report and Download `.md`.
- Avoid a separate long evening form.

Required Recent State behavior:

- Keep the module title `Recent state`.
- Show status summary, today advice, and anti-distraction guidance.
- Show one combined recent 7-day chart with two labeled y-axes (left = daily focus minutes with tick values, right = 0-100 score with tick values) and date labels on the x-axis. All three score metrics use the same direction (higher = better), so they share the right axis:
  - focus minutes as bars on the left y-axis,
  - energy remaining as a green solid line on the right y-axis,
  - predicted next-day drive as a blue dashed line on the right y-axis,
  - actual drive (night summary) as an orange solid line on the right y-axis.
- Provide one shared "perspective" dropdown (Self / Agent blind / Agent calibrated) that switches BOTH the remaining-energy and predicted-drive lines together; actual drive (night summary) is a single agent value, always shown.
- Show a color-swatch legend distinguishing all four series (bars + three score lines).
- Metrics and history keys per day (see the tracker Daily Scoring Model for definitions): `remainingSelf|remainingBlind|remainingCalibrated`, `predDriveSelf|predDriveBlind|predDriveCalibrated`, `actualDrive`. Prediction is stored under the day it targets so it aligns with that day's actual drive (night summary).
- Use only recorded prior evening reports for the chart (past days only; today appears the next day).
- If no prior report exists, show `Waiting For Recording`.
- Show a short planning-calibration summary outside the chart. Do not add goal risk as another chart line.

Required plan data additions:

- `planRevisionId`.
- `goalAlerts[]`: `goalId`, `title`, `level`, `deadline`, `deadlineType`, `originalDeadline`, `currentDeadline`, `proximity`, `feasibility`, `correctedRemainingMinutes`, `safeCapacityMinutes`, `coverage`, `confidence`, `historyWindow`, `comparableDays`, `historyLabels`, `latestSafeStart`, `estimateFactor`, `requiredToday`, `explanation`.
- `revisionSummary`: `changedToday`, `revisionId`, `affectedLevels`, `before`, `after`, `cumulativeDelayDays`, `goalDebtMinutes`, `feasibility`, `status`.
- Each baseline/stretch/commitment task includes `goalId` and `criticalPath`;
  `signature` may provide a stable similar-task calibration label and otherwise
  defaults to the task title.
- `planningCalibration.weeklyOutputCompletionRate` carries the current weekly
  completed/planned outcome rate when known.
- Wallpaper `progress[]` items include `kind`; the generator rejects more than
  five items and requires `month` second-to-last and `phase` last.
- Wallpaper `goalAlert.goalLevel` carries the goal hierarchy level for
  cross-artifact QA; `goalAlert.level` remains the visible severity
  (`approaching | critical | due`).

## Wallpaper PNG

Required file:

- `outputs/daily-wallpapers/YYYY-MM-DD-daily-plan.png`

Required behavior:

- Size: 2560x1440.
- Use a static task-board format.
- If the plan was generated as a manual catch-up run, show only the remaining-time plan from actual run time to evening check-in.
- Reserve a clear header band so the subtitle never overlaps the main title.
- Include:
  - main title,
  - subtitle,
  - top-right summary with today's overall task focus type and recommended time combination,
  - stable task-category color legend,
  - an optional full-width Goal Alert strip between the legend and progress row,
  - one progress row with at most 5 bars: phase progress LAST, month progress SECOND-TO-LAST, and up to 3 earlier slots chosen and ordered by today's importance from week / micro-sprint / ongoing-commitment progress,
  - baseline column, with label adjusted when a manual catch-up plan has less than the normal 3h baseline,
  - stretch column, with label adjusted or omitted when a manual catch-up plan has no stretch work,
  - right-side status/advice column.
- Right side contains exactly:
  - status summary,
  - today advice,
  - anti-distraction tip.

Goal Alert strip:

- Render only the highest-severity approaching/critical/due goal; show its text level, goal title, deadline, remaining work, and required-today action.
- If more alerts exist, show only `N more goal alerts`; detailed alerts stay in HTML.
- Use a separate status palette: amber for approaching, deep red for critical/due. Keep the task-category palette and legend unchanged.
- Maximum two readable lines; no formulas, history explanation, confirmation instructions, workflow instructions, truncation, or ellipsis.
- Collapse the strip and reclaim its height when there is no alert.
- Show the Revision ID as small low-contrast footer text.

## Copy Variants And Readability

Daily artifacts may use two wording variants from the same confirmed meaning:

- HTML copy: can be longer, clearer, and more explanatory.
- Wallpaper copy: should be shorter, but still readable as standalone text.

Readability requirements:

- Prefer the user's working language. If the plan is in Chinese, write natural
  Chinese except for stable project names such as `WDM`.
- Every recommendation should make the concrete action clear: what to do, when
  or for how long when relevant, and what output or decision counts as done.
- Avoid unexplained abstractions, metaphors, and compressed English planning
  phrases such as `protected exit block`, `external handoffs are real`, or
  `visibly smaller`.
- If wallpaper space is tight, reduce detail, reduce task count, or move
  explanation to the HTML workbench. Do not replace clear advice with cryptic
  shorthand.

Do not include:

- dynamic focus progress (live within-day counters),
- any progress bar outside the single progress row (commitment progress only as one of its max-5 bars),
- energy remaining or drive scores (any of the three daily metrics),
- artifact instructions,
- evening fields,
- long workflow rules.

## Color Legend

- Orange: urgent/external/deadline.
- Blue: deliverable/closure/visible output.
- Green: deep research/analysis/implementation.
- Gray: planning/log/admin/stop.

Colors are task-category colors, not project colors.

## QA

Before presenting artifacts:

- Open or visually inspect the wallpaper.
- Confirm manual catch-up artifacts, when applicable, cover only actual run time to evening check-in.
- Confirm no title/subtitle overlap.
- Confirm the top-right summary clearly reads as `task focus | time mix` and uses the correct task-category color for the focus type.
- Confirm no visible text truncation.
- Run a readability pass on HTML text and wallpaper text.
- Run a layout pass on the wallpaper.
- If readability and layout conflict, preserve readable wording and remove lower-priority detail before shortening text into vague phrases.
- Confirm no old or invalid sections remain.
- Confirm HTML report can be generated from filled task fields.
- Confirm wallpaper and HTML describe the same accepted plan.
- Confirm the persisted artifact lock, tracker, affected phase/month plan files,
  HTML, and PNG use the same Revision ID.
- Confirm Goal ID, proximity, deadline, feasibility, and required-today action have the same meaning across HTML and PNG.
- Confirm HTML disclosure sections, alert ordering, revision expansion state, and unplanned-work report fields work without horizontal overflow.
- Confirm the wallpaper Goal Alert does not overlap header, legend, progress, or main-board content and does not duplicate a fourth right-column block.
- When subagent tools are available, use `ArtifactQAAgent` for an independent check, then fix any issues before presenting artifacts.
- If `ArtifactQAAgent` is unavailable, use `$life-energy-artifact-qa`.
- If neither is available, record `ArtifactQAAgent: main-thread fallback` and complete the QA checklist in the main thread.

The presentation hard gate is conjunctive: revision confirmed, Goal Drift Guard
passed, every due target has a terminal decision, correction mode exited, final
daily plan confirmed, all Revision IDs match, and visual QA passed. Any false or
unknown item blocks presentation.
