# LifeEnergyManager Skill And Subagent Invocation Contracts (Claude Code)

LifeEnergyManager uses the matching LifeEnergyManager skill as the default bounded-analysis path. In Claude Code, the skills are auto-discovered from `.claude/skills/life-energy-*` and can be invoked by name (for example `/life-energy-daily-planner`) or triggered by their descriptions. Use a subagent only when the task benefits from independent review, parallel analysis, or a second perspective on a bias-prone judgment. The subagents are defined in `.claude/agents/`. The main Claude Code session keeps final responsibility for decisions.

## Role To Asset Mapping

The workflow role names below are shared with the Codex edition so tracker audit blocks stay comparable across platforms.

| Workflow role | Default skill (`.claude/skills/`) | Escalation subagent (`.claude/agents/`) |
| --- | --- | --- |
| PlanNormalizerAgent | `life-energy-plan-normalizer` | `plan-normalizer` |
| UrgencyTriageAgent | `life-energy-urgency-triage` | `urgency-triage` |
| DailyPlannerAgent | `life-energy-daily-planner` | `daily-planner` |
| EnergyQuantAgent | `life-energy-drive-resistance` | `energy-quant` |
| AdviceAgent | `life-energy-advice` | `advice` |
| ArtifactQAAgent | `life-energy-artifact-qa` | `artifact-qa` |
| WeeklyReviewAgent | `life-energy-weekly-review` | `weekly-review` |

## Invocation Policy

- Each setup, morning, evening, and Sunday workflow must read this file before execution.
- When a trigger applies, use the matching skill by default and record `skill used`.
- Escalate to the matching subagent only when at least one escalation signal applies. Delegate with an explicit request, for example "use the `urgency-triage` subagent".
- If neither the matching skill nor a justified subagent path is available, continue in the main session and record `main-thread fallback`.
- If a trigger does not apply, record `not needed`.
- Every workflow must include this audit block in its output:

```text
Subagent calls:
- <workflow role>: skill used / subagent used / main-thread fallback / not needed
- Reason:
- Main-thread decision:
```

## Subagent Escalation Signals

Use a subagent instead of the default skill when one or more of these apply:

- Independent review: the main session just generated an artifact, plan, score, or summary and a checklist-based second pass is likely to catch omissions.
- Parallel analysis: the subtask is self-contained, can run while the main session continues non-overlapping work, and returns material the main session can integrate later.
- Bias-prone judgment: the task involves urgent-but-tempting work, compensating for an incomplete day, emotionally strong evening reports, repeated deferrals, or secondary projects competing with the primary critical path.
- High consequence: the result would change the day's core workload, next-day intensity, weekly priorities, or a user-facing artifact.

Do not use a subagent when the task is a simple application of the skill contract, when the result is immediately blocking the next main-session step, or when the hidden conversation context is more important than the written inputs. Subagents run with their own context; give them the written inputs they need.

## Invocation Map

- Setup: use `life-energy-plan-normalizer` when creating or updating `outputs/life_energy_tracker.md`; escalate to the `plan-normalizer` subagent when source plans conflict, are messy enough to risk invented priorities, or missing information affects schedule, deadline, or core priority.
- Morning: use `life-energy-urgency-triage` if the user provides extra urgent, external, or tempting tasks; escalate to the `urgency-triage` subagent when a task would displace thesis-critical work, has ambiguous urgency, or looks like productive procrastination.
- Morning: use `life-energy-daily-planner` for provisional plan options; escalate to the `daily-planner` subagent when repeated deferrals, real deadline pressure, low energy, or competing workstreams make intensity selection bias-prone.
- Morning: use `life-energy-advice` for status summary, today advice, and anti-distraction tip; escalate to the `advice` subagent only when the distraction pattern or state interpretation is unclear from evidence.
- Morning: use the `artifact-qa` subagent for generated HTML/PNG artifact QA by default, because artifact QA is an independent-review task; if subagent delegation is unavailable, use `life-energy-artifact-qa`.
- Evening: use `life-energy-drive-resistance` when enough report content exists to produce the three daily metrics (energy reserve, predicted next-day drive, actual drive); escalate to the `energy-quant` subagent when the report is ambiguous, its signals diverge, or the result would change next-day intensity.
- Sunday: use `life-energy-weekly-review` before updating the next weekly plan; escalate to the `weekly-review` subagent when the week contains repeated deferrals, unclear blockers, or major priority changes.

## Global Rules

- Every skill or subagent output must return concrete text that can be pasted into the tracker or plan.
- Every skill or subagent output must distinguish evidence from inference.
- Skills and subagents do not make final priority decisions.
- Skills and subagents do not generate final daily artifacts unless asked by the main session.
- Skills and subagents should keep outputs short and structured.
- Short output must still be readable. Do not use unexplained planning jargon,
  metaphors, or compressed English phrases when a concrete sentence is needed.

## PlanNormalizerAgent

Purpose:

- Convert messy user plans into the LifeEnergyManager tracker structure.

Inputs:

- user plan,
- phase plan,
- month plan,
- profile,
- existing tracker if any.

Output:

- normalized north star,
- phase plan,
- monthly plan,
- priority rules,
- active micro-sprints,
- missing information.

## UrgencyTriageAgent

Purpose:

- Classify morning extra tasks and propose tradeoffs.

Classification:

- Critical,
- goal-leveraged,
- maintenance,
- distraction.

Output:

- classification,
- why,
- recommended time cap,
- what it replaces or defers,
- one-day / multi-day judgment and, for accepted multi-day tasks, the proposed Ongoing Commitments entry (exit criterion, deadline date + type, placement policy per the tracker table-header rules).

## DailyPlannerAgent

Purpose:

- Draft a provisional daily plan from tracker state.

Inputs:

- active phase,
- monthly plan,
- weekly plan,
- rolling state,
- active micro-sprints,
- active ongoing commitments and their today-allocation decisions.

Output:

- focus mode,
- today's overall task focus type,
- task focus color from the stable task-category color legend,
- recommended time combination,
- baseline tasks,
- stretch tasks,
- agent-delegable tasks,
- explicit non-goals,
- reason for intensity.

## EnergyQuantAgent

Purpose:

- Produce the three daily scoring metrics (energy reserve, predicted next-day drive, actual drive) from the evening report. Definitions live in the tracker's Daily Scoring Model; all are 0-100, higher = better.

Output:

- `reserveBlind`, `reserveCalibrated`,
- `predDriveBlind`, `predDriveCalibrated`,
- `actualDrive` (single blind value),
- `agent_energy_confidence`: low / medium / high,
- `agent_energy_summary`,
- `planning_adjustment`,
- actual-vs-predicted comparison note.

Rules:

- This is not diagnosis. Do not shame or punish the user.
- Blind pass first, from report evidence only: `reserveBlind`, `predDriveBlind`, `actualDrive` (anchor actual drive on focus minutes and completions). Then read the user self-scores (`reserveSelf`, `predDriveSelf`) and produce the calibrated values; blind values are never edited.
- `planning_adjustment` is informed by energy reserve and actual drive; the predicted-vs-actual comparison is calibration only, not a planning input.
- Compare `actualDrive` (today) with the calibrated prediction made last night; flag a large gap. Also flag a blind-vs-self drive-prediction gap of 30+ points.
- Prefer conservative planning adjustments.

## AdviceAgent

Purpose:

- Generate daily status/advice reminders from rolling state.

Output:

- HTML status summary,
- HTML today advice,
- HTML anti-distraction tip,
- wallpaper status summary,
- wallpaper today advice,
- wallpaper anti-distraction tip.

Rules:

- Draft clear HTML wording first, then derive shorter wallpaper wording.
- Keep each wallpaper line short enough for the wallpaper, but do not sacrifice
  basic readability.
- Advice must respond to actual state, not generic motivation.
- Anti-distraction tip should name the likely distraction pattern.
- Reject vague or cryptic phrases such as `protected exit block`, `external
  handoffs are real`, or `visibly smaller`.
- If the plan is in Chinese, use natural Chinese except for stable project names
  such as `WDM`.

## ArtifactQAAgent

Purpose:

- Inspect generated HTML and wallpaper artifacts before presentation.

Checks:

- no old sections,
- no title/subtitle overlap,
- top-right summary clearly shows task focus type and recommended time combination,
- top-right focus type uses the correct task-category color,
- no clipped text,
- status/advice/tip are readable and do not rely on unexplained shorthand,
- HTML can use longer wording than the wallpaper,
- readability QA and layout QA are both complete before final presentation,
- stable color legend,
- right wallpaper column contains only the three approved reminder blocks,
- the wallpaper progress row has at most 5 bars (month second-to-last, phase last) and no progress bars appear anywhere else,
- HTML report can be generated from task fields,
- HTML and PNG match the same confirmed plan.

Output:

- pass/fail,
- issues with file and location if available,
- required fixes.

## WeeklyReviewAgent

Purpose:

- Summarize last week and prepare next week's planning inputs.

Output:

- weekly summary,
- top 3 next outcomes,
- repeated deferrals,
- real blockers,
- agent-delegable tasks,
- Monday first action.

## Decisions Reserved For Main Thread

- Final plan confirmation.
- Major priority tradeoffs.
- Accepting or rejecting urgent tasks.
- Increasing or reducing next-day intensity.
- Creating or updating routines.
