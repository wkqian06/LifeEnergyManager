# LifeEnergyManager Artifact Specification

Use this specification whenever generating daily artifacts.

## HTML Workbench

Required file:

- `outputs/daily-workbenches/YYYY-MM-DD-workbench.html`

Required behavior:

- Work offline as a local HTML file.
- Persist entries in browser `localStorage`.
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
- Generate a Markdown report from the task fields.
- Include Copy report and Download `.md`.
- Avoid a separate long evening form.

Required Recent State behavior:

- Keep the module title `Recent state`.
- Show status summary, today advice, and anti-distraction guidance.
- Show one combined recent 7-day chart with two labeled y-axes (left = daily focus minutes with tick values, right = 0-100 score with tick values) and date labels on the x-axis. All three score metrics use the same direction (higher = better), so they share the right axis:
  - focus minutes as bars on the left y-axis,
  - energy reserve as a green solid line on the right y-axis,
  - predicted next-day drive as a blue dashed line on the right y-axis,
  - actual drive as an orange solid line on the right y-axis.
- Provide one shared "perspective" dropdown (Self / Agent blind / Agent calibrated) that switches BOTH the reserve and predicted-drive lines together; actual drive is a single agent value, always shown.
- Show a color-swatch legend distinguishing all four series (bars + three score lines).
- Metrics and history keys per day (see the tracker Daily Scoring Model for definitions): `reserveSelf|reserveBlind|reserveCalibrated`, `predDriveSelf|predDriveBlind|predDriveCalibrated`, `actualDrive`. Prediction is stored under the day it targets so it aligns with that day's actual drive.
- Use only recorded prior evening reports for the chart (past days only; today appears the next day).
- If no prior report exists, show `Waiting For Recording`.

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
  - one progress row with at most 5 bars: phase progress LAST, month progress SECOND-TO-LAST, and up to 3 earlier slots chosen and ordered by today's importance from week / micro-sprint / ongoing-commitment progress,
  - baseline column, with label adjusted when a manual catch-up plan has less than the normal 3h baseline,
  - stretch column, with label adjusted or omitted when a manual catch-up plan has no stretch work,
  - right-side status/advice column.
- Right side contains exactly:
  - status summary,
  - today advice,
  - anti-distraction tip.

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
- energy reserve or drive scores (any of the three daily metrics),
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
- When subagent tools are available, use `ArtifactQAAgent` for an independent check, then fix any issues before presenting artifacts.
- If `ArtifactQAAgent` is unavailable, use `$life-energy-artifact-qa`.
- If neither is available, record `ArtifactQAAgent: main-thread fallback` and complete the QA checklist in the main thread.
