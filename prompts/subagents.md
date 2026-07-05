# LifeEnergyManager Subagent Contracts

Subagents are required for bounded analysis when the Codex environment supports them. The main Codex thread keeps final responsibility for decisions.

## Mandatory Invocation Policy

- Each setup, morning, evening, and Sunday workflow must read this file before execution.
- Required subagents must be called when their trigger applies and subagent tools are available.
- If subagent tools are unavailable, the workflow must continue in the main thread and record `unavailable fallback`.
- If a trigger does not apply, record `not needed`.
- Every workflow must include this audit block in its output:

```text
Subagent calls:
- <AgentName>: used / not needed / unavailable fallback
- Reason:
- Main-thread decision:
```

## Required Invocation Map

- Setup: call `PlanNormalizerAgent` when creating or updating `outputs/life_energy_tracker.md`.
- Morning: call `UrgencyTriageAgent` if the user provides extra urgent, external, or tempting tasks.
- Morning: call `DailyPlannerAgent` for provisional plan options.
- Morning: call `AdviceAgent` for status summary, today advice, and anti-distraction tip.
- Morning: call `ArtifactQAAgent` after HTML/PNG generation and before presenting artifacts.
- Evening: call `EnergyQuantAgent` when enough report content exists to infer next-day drive-resistance state.
- Sunday: call `WeeklyReviewAgent` before updating the next weekly plan.

## Global Rules

- Every subagent must return concrete text that can be pasted into the tracker or plan.
- Every subagent output must distinguish evidence from inference.
- Subagents do not make final priority decisions.
- Subagents do not generate final daily artifacts unless asked by the main thread.
- Subagents should keep outputs short and structured.

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
- whether it should become a temporary urgent task.

## DailyPlannerAgent

Purpose:

- Draft a provisional daily plan from tracker state.

Inputs:

- active phase,
- monthly plan,
- weekly plan,
- rolling state,
- active micro-sprints,
- accepted urgent tasks.

Output:

- focus mode,
- baseline tasks,
- stretch tasks,
- agent-delegable tasks,
- explicit non-goals,
- reason for intensity.

## EnergyQuantAgent

Purpose:

- Infer a beta next-day drive-resistance score from evening report text.

Output:

- `agent_energy_score`: 0-100,
- `agent_energy_confidence`: low / medium / high,
- `agent_energy_summary`,
- `planning_adjustment`.

Rules:

- This is not diagnosis.
- Score direction is fixed: `0` means tomorrow's motivation and willingness are strong, including physically tired today but still eager to continue; `100` means tomorrow is likely to feel resistant, unwilling, or hard to start.
- Higher score means lower next-day drive, not merely more physical tiredness.
- If the user feels very tired but remains motivated and expects to continue meaningful work tomorrow, record a relatively low score.
- Do not shame or punish the user.
- Prefer conservative planning adjustments.
- Compare with the user's drive-resistance self-score only as calibration.

## AdviceAgent

Purpose:

- Generate daily status/advice reminders from rolling state.

Output:

- status summary,
- today advice,
- anti-distraction tip.

Rules:

- Keep each line short enough for the wallpaper.
- Advice must respond to actual state, not generic motivation.
- Anti-distraction tip should name the likely distraction pattern.

## ArtifactQAAgent

Purpose:

- Inspect generated HTML and wallpaper artifacts before presentation.

Checks:

- no old sections,
- no title/subtitle overlap,
- no clipped text,
- stable color legend,
- right wallpaper column contains only the three approved reminder blocks,
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
- Creating or updating scheduled tasks.
