# LifeEnergyManager Artifact Specification

Use this specification whenever generating daily artifacts.

## HTML Workbench

Required file:

- `outputs/daily-workbenches/YYYY-MM-DD-workbench.html`

Required behavior:

- Work offline as a local HTML file.
- Persist entries in browser `localStorage`.
- Include baseline tasks, stretch tasks, and accepted urgent tasks.
- Layout the top control area as two first-row modules, `Temporary urgent tasks` and `Today suggestion`, followed by `Recent state` on the next row spanning the full HTML width.
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
- Show status summary and today advice.
- Show one combined recent 7-day chart:
  - focus minutes as bars on the left y-axis,
  - agent next-day drive-resistance score as dashed line on the right y-axis,
  - user next-day drive-resistance self-score as solid line on the right y-axis.
- Define score direction wherever the score appears: `0` means tomorrow's motivation and willingness are strong, including physically tired today but still eager to continue; `100` means tomorrow is likely to feel resistant, unwilling, or hard to start. Higher score means lower next-day drive, not merely more physical tiredness.
- Use only recorded prior evening reports for the chart.
- The current day's user next-day drive-resistance self-score is saved into tonight's report and appears only the next day.
- If no prior report exists, show `Waiting For Recording`.

## Wallpaper PNG

Required file:

- `outputs/daily-wallpapers/YYYY-MM-DD-daily-plan.png`

Required behavior:

- Size: 2560x1440.
- Use a static task-board format.
- Reserve a clear header band so the subtitle never overlaps the main title.
- Include:
  - main title,
  - subtitle,
  - focus mode badge,
  - stable task-category color legend,
  - phase/month/week/active micro-sprint progress,
  - baseline column,
  - stretch column,
  - right-side status/advice column.
- Right side contains exactly:
  - status summary,
  - today advice,
  - anti-distraction tip.

Do not include:

- dynamic focus progress,
- urgent task progress bars,
- next-day drive-resistance scores,
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
- Confirm no title/subtitle overlap.
- Confirm no visible text truncation.
- Confirm no old or invalid sections remain.
- Confirm HTML report can be generated from filled task fields.
- Confirm wallpaper and HTML describe the same accepted plan.
- When subagent tools are available, use `ArtifactQAAgent` for an independent check, then fix any issues before presenting artifacts.
- If subagent tools are unavailable, record `ArtifactQAAgent: unavailable fallback` and complete the QA checklist in the main thread.
