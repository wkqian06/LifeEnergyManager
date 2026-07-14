# Desktop Wallpaper Specification

The wallpaper is a static daily reminder. It should not contain controls, dynamic progress, or process instructions that belong in the HTML workbench.

## Required Output

- Format: PNG.
- Size: 2560x1440.
- Filename: `outputs/daily-wallpapers/YYYY-MM-DD-daily-plan.png`.
- Visual style: quiet, readable, high contrast, low decoration.
- Visual spacing: 8px-derived rhythm, 12px card radius, neutral gray-white background, dark slate text, low-contrast gray-blue borders, no ornamental gradients or font-dependent emoji.

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

Goal Alert strip:

- Optional, full-width, between the task legend and progress row.
- Render only for `approaching`, `critical`, or `due`.
- Show text severity, goal title, deadline, remaining work, and the concrete required-today action. If more alerts exist, show only their count.
- Keep `goalLevel` in the generator data for cross-artifact QA while the visible
  `level` field remains the text severity.
- `approaching`: amber accent and pale amber background.
- `critical` / `due`: deep-red accent and pale-red background.
- Risk colors are status colors, not task-category colors; always pair them with a text label.
- Maximum two lines. No formulas, historical explanation, confirmation/process instructions, truncation, or ellipsis.
- When absent, collapse the area and use the original compact geometry.

Progress row:

- One row only, at most 5 bars. Progress bars appear nowhere else on the wallpaper.
- The LAST bar is always phase progress; the SECOND-TO-LAST is always month progress.
- Each generator input item carries `kind: week | sprint | commitment | month |
  phase`. The generator rejects more than five items, a missing/unknown `kind`,
  or any order that does not put month second-to-last and phase last; it never
  silently drops progress.
- The remaining slots (up to 3) are chosen and ordered by today's importance from:
  week progress, active micro-sprints, and ongoing-commitment progress
  (commitment percent = recorded Done minutes vs total estimate, midpoint of a range).
- Keep bar labels short enough for one line.
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

Footer:

- Small low-contrast active plan Revision ID; it must not compete with tasks or alerts.

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
- The single progress row (max 5 bars; month second-to-last, phase last).
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

- Dynamic focus progress (live within-day counters).
- Any progress bar outside the single progress row; commitment progress may appear only as one of its (max 5) bars.
- Energy remaining or drive scores (any of the three daily metrics).
- Long workflow explanations.
- Artifact/process instructions.
- Evening forms.
- Detailed Goal Guard calculations and Plan Revision explanations.

## QA Checklist

- No important text is cut off, truncated, or replaced by ellipses.
- The renderer measures every variable text block and fails visibly when the
  supplied copy cannot fit at the minimum readable font size. Shorten the
  wallpaper-only copy or remove lower-priority detail, then render again.
- The subtitle does not overlap the title.
- Goal Alert, when present, is the most visible status element but does not overlap the legend, progress row, or main board.
- The top-right summary clearly reads as `task focus | time mix`.
- Cards do not overlap.
- The progress row has at most 5 bars, with month progress second-to-last and phase progress last.
- Text blocks have breathing room.
- The right column has exactly the three intended reminder blocks.
- Risk colors are not reused as task-category colors, and severity remains clear in grayscale through its text label.
- Revision ID matches the confirmed HTML/tracker snapshot.
- The three reminder blocks are readable as standalone text.
- Readability QA and layout QA were both completed; if they conflict, readable
  wording wins and detail is reduced.
- Color legend matches task labels.
- The image still works when viewed as a desktop background.
