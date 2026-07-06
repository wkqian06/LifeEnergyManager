---
name: life-energy-plan-normalizer
description: Normalize messy LifeEnergyManager user plans into tracker-ready phase, month, priority, sprint, missing-info, and output-root content. Use as the default bounded-analysis path when creating/updating outputs/life_energy_tracker.md.
---

# Life Energy Plan Normalizer

## Overview

Use this skill as the default bounded-analysis contract for setup normalization. Escalate to the `plan-normalizer` subagent only when source plans conflict, are messy enough to risk invented priorities, or missing information affects schedule, deadline, or core priority. It extracts supported planning facts from user-provided materials and returns tracker-ready text without making final priority or automation decisions.

## Inputs

- `user_plan.md` or pasted user plan.
- Source `phase_plan.md`, `month_plan.md`, and `profile.md`, if present.
- Existing `outputs/life_energy_tracker.md` or `outputs/daily-reports/`, if present.
- `templates/tracker.md` and `claudecode/prompts/subagents.md`.

## Procedure

1. Extract facts only from the supplied plan material.
2. Normalize the long-term goal into a North Star.
3. Convert phase and month material into the tracker structure.
4. Identify active micro-sprints and ongoing commitments only when supported by evidence. Never generate multi-day-task-to-temporary-sprint rules; the container for accepted multi-day extra tasks is the Ongoing Commitments table.
5. Draft priority rules that protect the active phase from secondary work.
6. Ensure every persistent output path points under `outputs/`.
7. Identify missing information that changes schedule, deadline, or core priority.
8. Mark each item as evidence or inference.

## Output

Return concise tracker-ready sections:

- normalized North Star,
- phase plan,
- monthly plan,
- priority rules,
- active micro-sprints,
- output-root notes,
- missing information.

## Boundaries

- Do not invent project-specific priorities.
- Do not create daily artifacts.
- Do not make final tracker, priority, or automation decisions.
- The main session must decide the final `outputs/life_energy_tracker.md` content.
