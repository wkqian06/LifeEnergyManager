---
name: life-energy-artifact-qa
description: QA LifeEnergyManager daily HTML workbench and wallpaper artifacts against the confirmed plan, output paths, layout rules, and report behavior. Use when artifact-qa subagent escalation is unavailable.
---

# Life Energy Artifact QA

## Overview

Use this skill when the `artifact-qa` subagent is unavailable. Artifact QA is normally a subagent escalation task because it benefits from an independent check before the main session presents artifacts.

## Inputs

- Confirmed daily plan.
- `outputs/daily-workbenches/YYYY-MM-DD-workbench.html`.
- `outputs/daily-wallpapers/YYYY-MM-DD-daily-plan.png`.
- `templates/artifact_spec.md` and `templates/wallpaper_spec.md`.

## Checks

- Artifacts are under `outputs/`.
- HTML and PNG match the same confirmed plan.
- HTML report can be generated from task fields.
- HTML uses the longer readable wording when available for status summary, today advice, and anti-distraction guidance.
- No old or invalid sections remain.
- Wallpaper has no title/subtitle overlap.
- Top-right summary clearly shows task focus type and recommended time combination.
- Top-right focus type uses the correct task-category color.
- Wallpaper has no clipped or visibly truncated text.
- Wallpaper status/advice/tip remain readable after shortening; they must not become abstract shorthand or unexplained English planning jargon.
- Reject phrases that require guessing, including examples like `protected exit block`, `external handoffs are real`, or `visibly smaller`.
- If readability and wallpaper layout conflict, require reducing details or task count before accepting cryptic wording.
- Color legend is stable and category-based.
- Right wallpaper column contains only status summary, today advice, and anti-distraction tip.
- Wallpaper excludes dynamic focus progress, urgent progress bars, drive-resistance scores, process instructions, evening fields, and long workflow rules.
- Run readability QA and layout QA as separate passes, then integrate the fixes into the final artifacts.

## Output

Return:

- pass/fail,
- issues with file and location if available,
- required fixes,
- readability failures and layout failures as separate items when both exist,
- confirmation when ready to present.

## Boundaries

- Do not present artifacts before fixes are applied.
- Do not generate new final artifacts unless the main session asks for fixes.
- The main session remains responsible for visual inspection and presentation.
