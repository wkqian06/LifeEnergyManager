# LifeEnergyManager Skill And Subagent Invocation Contracts

LifeEnergyManager uses the matching LifeEnergyManager skill as the default bounded-analysis path, either as an installed `$life-energy-*` skill or by reading the local `codex/skills/<skill-name>/SKILL.md` file. Use a subagent only when the task benefits from independent review, parallel analysis, or a second perspective on a bias-prone judgment. The main Codex thread keeps final responsibility for decisions.

## Invocation Policy

- Each setup, morning, evening, and Sunday workflow must read this file before execution.
- When a trigger applies, use the matching skill by default and record `skill used`.
- Escalate to the matching subagent only when subagent tools are available and at least one escalation signal applies.
- If neither the matching skill nor a justified subagent path is available, continue in the main thread and record `main-thread fallback`.
- If a trigger does not apply, record `not needed`.
- Every workflow must include this audit block in its output:

```text
Subagent calls:
- <AgentName>: skill used / subagent used / main-thread fallback / not needed
- Reason:
- Main-thread decision:
```

## Subagent Escalation Signals

Use a subagent instead of the default skill when one or more of these apply:

- Independent review: the main thread just generated an artifact, plan, score, or summary and a checklist-based second pass is likely to catch omissions.
- Parallel analysis: the subtask is self-contained, can run while the main thread continues non-overlapping work, and returns material the main thread can integrate later.
- Bias-prone judgment: the task involves urgent-but-tempting work, compensating for an incomplete day, emotionally strong evening reports, repeated deferrals, or secondary projects competing with the primary graduation-critical path.
- High consequence: the result would change the day's core workload, next-day intensity, weekly priorities, or a user-facing artifact.

Do not use a subagent when the task is a simple application of the skill contract, when the result is immediately blocking the next main-thread step, or when the hidden conversation context is more important than the written inputs.

## Invocation Map

- Setup: use `$life-energy-plan-normalizer` when creating or updating `outputs/life_energy_tracker.md`; escalate to `PlanNormalizerAgent` when source plans conflict, are messy enough to risk invented priorities, or missing information affects schedule, deadline, or core priority.
- Morning: use `$life-energy-urgency-triage` if the user provides extra urgent, external, or tempting tasks; escalate to `UrgencyTriageAgent` when a task would displace thesis-critical work, has ambiguous urgency, or looks like productive procrastination.
- Morning: use `$life-energy-daily-planner` for provisional plan options; escalate to `DailyPlannerAgent` when repeated deferrals, real deadline pressure, low energy, or competing workstreams make intensity selection bias-prone.
- Morning: use `$life-energy-advice` for status summary, today advice, and anti-distraction tip; escalate to `AdviceAgent` only when the distraction pattern or state interpretation is unclear from evidence.
- Morning: use `ArtifactQAAgent` for generated HTML/PNG artifact QA when subagent tools are available, because artifact QA is an independent-review task; otherwise use `$life-energy-artifact-qa`.
- Evening: use `$life-energy-drive-resistance` when enough report content exists to infer next-day drive-resistance state; escalate to `EnergyQuantAgent` when completion, fatigue, motivation, and next-day willingness point in different directions or the score would change next-day intensity.
- Sunday: use `$life-energy-weekly-review` before updating the next weekly plan; escalate to `WeeklyReviewAgent` when the week contains repeated deferrals, unclear blockers, or major priority changes.

## Global Rules

- Every skill or subagent output must return concrete text that can be pasted into the tracker or plan.
- Every skill or subagent output must distinguish evidence from inference.
- Skills and subagents do not make final priority decisions.
- Skills and subagents do not generate final daily artifacts unless asked by the main thread.
- Skills and subagents should keep outputs short and structured.
- Short output must still be readable. Do not use unexplained planning jargon,
  metaphors, or compressed English phrases when a concrete sentence is needed.

## Morning Run Context

The morning workflow must pass run context into planning and artifact QA:

- `run_mode`: `scheduled` or `manual_catchup`.
- `actual_run_time`.
- configured morning planning time.
- configured evening check-in time.
- remaining usable planning window.

Use `manual_catchup` when the user says the Codex automation missed its
scheduled start and was launched manually, or when the current local time is
more than 60 minutes after the configured morning planning time. In
`manual_catchup`, plan only from `actual_run_time` to evening check-in. Do not
schedule or imply already-elapsed morning or afternoon work.

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

- run mode and planning window,
- focus mode,
- today's overall task focus type,
- task focus color from the stable task-category color legend,
- recommended time combination,
- baseline tasks,
- stretch tasks,
- agent-delegable tasks,
- explicit non-goals,
- reason for intensity,
- remaining-time rationale when `run_mode` is `manual_catchup`.

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
- manual catch-up artifacts plan only the remaining window from actual run time
  to evening check-in,
- no title/subtitle overlap,
- top-right summary clearly shows task focus type and recommended time combination,
- top-right focus type uses the correct task-category color,
- no clipped text,
- status/advice/tip are readable and do not rely on unexplained shorthand,
- HTML can use longer wording than the wallpaper,
- readability QA and layout QA are both complete before final presentation,
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
