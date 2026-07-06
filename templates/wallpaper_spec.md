# Desktop Wallpaper Specification

The wallpaper is a static daily reminder. It should not contain controls, dynamic progress, or process instructions that belong in the HTML workbench.

## Required Output

- Format: PNG.
- Size: 2560x1440.
- Filename: `outputs/daily-wallpapers/YYYY-MM-DD-daily-plan.png`.
- Visual style: quiet, readable, high contrast, low decoration.

## Layout

Top header:

- Main title: `Daily Plan - YYYY-MM-DD`.
- Subtitle: active phase, active sprint day, and current focus note. For a
  manual catch-up run, the subtitle should indicate the remaining-time window
  from actual run time to evening check-in.
- Reserve a clear header band so the subtitle never overlaps the main title.
- Top-right summary with exactly two parts:
  - today's overall task focus type, colored by the task-category color it belongs to,
  - recommended time combination, such as `4 H Baseline + 1 H Stretch`.
- Stable color legend below the subtitle.

Progress row:

- Phase progress.
- Month progress.
- Week progress.
- Active micro-sprint progress.
- Progress bars use neutral gray-blue, not task-category colors.

Main board:

- Left column: baseline tasks. Default label is `Baseline 3h`; for a manual
  catch-up plan, the label may show the adjusted remaining-time target.
- Middle column: stretch tasks. Default label is `Later 2h stretch`; for a
  manual catch-up plan, the label may show reduced stretch work or `No stretch`.
- Right column: `Status and advice`.

Right column content:

- Status summary.
- Today advice.
- Anti-distraction tip.

## Color Rules

Task category colors must be stable across users and projects:

- Orange: urgent, external, deadline-driven work.
- Blue: deliverable, closure, visible-output work.
- Green: deep research, analysis, implementation, strategic thinking.
- Gray: planning, logging, admin, stopping, review.

Do not assign colors to specific projects. If one project ends and another starts, the same category colors should continue to mean the same thing.

## Content Rules

Include:

- Tasks.
- Static phase/month/week/micro-sprint progress.
- Top-right task focus and time combination summary.
- Status summary.
- Today advice.
- One anti-distraction tip.

For manual catch-up plans:

- Include only tasks that can still happen between actual run time and evening
  check-in.
- Do not show already-missed morning or afternoon blocks as planned work.

Readability rules:

- Wallpaper wording may be shorter than the HTML workbench, but it must still
  be understandable without decoding private shorthand.
- Prefer the user's working language. If the plan is in Chinese, write natural
  Chinese except for stable project names such as `WDM`.
- Each advice block should state the concrete action, time window, output, or
  decision when relevant.
- Avoid unexplained abstractions and compressed English planning phrases such as
  `protected exit block`, `external handoffs are real`, or `visibly smaller`.
- If text does not fit, remove lower-priority detail or reduce task count before
  using vague wording.

Exclude:

- Dynamic focus progress.
- Dynamic urgent-task progress.
- Next-day drive-resistance scores.
- Long workflow explanations.
- Artifact/process instructions.
- Evening forms.

## QA Checklist

- No important text is cut off, truncated, or replaced by ellipses.
- The subtitle does not overlap the title.
- The top-right summary clearly reads as `task focus | time mix`.
- Cards do not overlap.
- Text blocks have breathing room.
- The right column has exactly the three intended reminder blocks.
- The three reminder blocks are readable as standalone text.
- Readability QA and layout QA were both completed; if they conflict, readable
  wording wins and detail is reduced.
- Color legend matches task labels.
- The image still works when viewed as a desktop background.
