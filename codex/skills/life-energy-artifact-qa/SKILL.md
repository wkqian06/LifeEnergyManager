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
- `templates/artifact_spec.md` and `templates/wallpaper_spec.md`.
- Active plan Revision ID and Goal Drift Guard result.
- Tracker, affected phase/month plan files, and today's persisted artifact lock.
- Revision-confirmation state, due-target terminal decisions,
  correction-mode state, and final daily-plan confirmation state.

## Checks

- Artifacts are under `outputs/`.
- HTML and PNG match the same confirmed plan.
- Artifact lock, tracker, affected phase/month files, HTML, and PNG carry the
  same active Revision ID.
- Apply the complete conjunctive hard gate: revision confirmed; Goal Drift Guard
  passed; all due targets have terminal decisions; correction mode exited;
  final daily plan confirmed; all Revision IDs match; visual QA passed. Any
  false or unknown item is a failure.
- Goal ID, level, proximity, deadline, feasibility, and required-today action are semantically consistent across HTML and wallpaper.
- If the plan was generated in `manual_catchup` mode, both artifacts plan only from actual run time to evening check-in and do not include elapsed morning or afternoon blocks.
- HTML report can be generated from task fields.
- HTML uses the longer readable wording when available for status summary, today advice, and anti-distraction guidance.
- No old or invalid sections remain.
- Wallpaper has no title/subtitle overlap.
- Top-right summary clearly shows task focus type and recommended time combination.
- Top-right focus type uses the correct task-category color.
- Wallpaper has no clipped or visibly truncated text.
- Goal Alert strip, when present, is prominent without overlapping the legend, progress row, or main board; it shows no formula or workflow instruction.
- HTML Goal Guard modules are readable, correctly ordered, and keep detailed evidence inside disclosure blocks.
- Wallpaper status/advice/tip remain readable after shortening; they must not become abstract shorthand or unexplained English planning jargon.
- Reject phrases that require guessing, including examples like `protected exit block`, `external handoffs are real`, or `visibly smaller`.
- If readability and wallpaper layout conflict, require reducing details or task count before accepting cryptic wording.
- Color legend is stable and category-based.
- Right wallpaper column contains only status summary, today advice, and anti-distraction tip.
- Wallpaper has one progress row with at most 5 bars, month progress second-to-last and phase progress last, and no progress bars anywhere else.
- Wallpaper excludes live within-day focus counters, energy/drive scores, process instructions, evening fields, and long workflow rules.
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
- Do not generate new final artifacts unless the main thread asks for fixes.
- The main thread remains responsible for visual inspection and presentation.
