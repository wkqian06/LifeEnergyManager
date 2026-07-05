---
name: life-energy-artifact-qa
description: QA LifeEnergyManager daily HTML workbench and wallpaper artifacts against the confirmed plan, output paths, layout rules, and report behavior. Use when ArtifactQAAgent escalation is unavailable.
---

# Life Energy Artifact QA

## Overview

Use this skill when `ArtifactQAAgent` is unavailable. Artifact QA is normally a subagent escalation task when subagent tools are available because it benefits from an independent check before the main thread presents artifacts.

## Inputs

- Confirmed daily plan.
- `outputs/daily-workbenches/YYYY-MM-DD-workbench.html`.
- `outputs/daily-wallpapers/YYYY-MM-DD-daily-plan.png`.
- `prompts/artifact_spec.md` and `templates/wallpaper_spec.md`.

## Checks

- Artifacts are under `outputs/`.
- HTML and PNG match the same confirmed plan.
- HTML report can be generated from task fields.
- No old or invalid sections remain.
- Wallpaper has no title/subtitle overlap.
- Top-right summary clearly shows task focus type and recommended time combination.
- Top-right focus type uses the correct task-category color.
- Wallpaper has no clipped or visibly truncated text.
- Color legend is stable and category-based.
- Right wallpaper column contains only status summary, today advice, and anti-distraction tip.
- Wallpaper excludes dynamic focus progress, urgent progress bars, drive-resistance scores, process instructions, evening fields, and long workflow rules.

## Output

Return:

- pass/fail,
- issues with file and location if available,
- required fixes,
- confirmation when ready to present.

## Boundaries

- Do not present artifacts before fixes are applied.
- Do not generate new final artifacts unless the main thread asks for fixes.
- The main thread remains responsible for visual inspection and presentation.
