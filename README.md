# LifeEnergyManager

> Long-term progress is often constrained not by the size of the task list, but by the energy available to act on it.

LifeEnergyManager is a Codex-based daily planning routine that turns big goals, current priorities, blockers, and available energy into a realistic plan for today.

Each day, it helps create:

- a realistic morning plan,
- a local HTML checklist/workbench,
- a desktop wallpaper reminder,
- an evening review that updates the running tracker.

It is meant for people whose progress depends on planning around real capacity, not an ideal version of the day.

| Question | What LifeEnergyManager does |
| --- | --- |
| What should I do today? | Turns the larger plan into a realistic daily plan. |
| What deserves my best energy? | Protects time for the work that matters most. |
| What is getting stuck? | Tracks blockers and drift before they become invisible. |
| How should tomorrow change? | Uses today's report to make the next plan easier. |

## Core philosophy

**Action first, tracking in service of action.**

Track only what helps tomorrow's action.

LifeEnergyManager is not designed to create perfect plans or exhaustive self-quantification. It is designed to reduce decision fatigue, lower the cost of starting, and help important work move forward even when energy is limited.

## What it actually does

LifeEnergyManager gives Codex a repeatable routine for helping you plan and review your day.

In the morning, it looks at your bigger plan, current priorities, recent state, blockers, and available energy, then turns them into a realistic daily plan. It also creates a simple HTML workbench you can use as a checklist during the day and a desktop wallpaper that keeps the plan visible.

In the evening, you report what happened. LifeEnergyManager updates the running tracker, records what moved forward or got blocked, estimates how hard tomorrow may feel to start, and leaves a short seed for the next morning. Once a week, it compresses the recent logs and helps choose the next week's focus.

The practical goal is simple: keep the important work visible, choose fewer and more realistic actions, and make tomorrow's planning easier than starting from scratch.

## How it works

Under the hood, LifeEnergyManager is a reusable Codex prompt package for adaptive daily planning.
It turns a user's phase plan, monthly plan, and rolling state into:

- a morning plan with a 3h baseline and optional 2h stretch,
- an interactive local HTML workbench for low-friction checklists and reporting,
- a static 2560x1440 desktop wallpaper plan,
- an evening check-in flow that updates rolling planning memory,
- a light Sunday review that keeps the next week aligned with the larger goal.

Version 1 is intentionally not a full web app or command-line product. It is a
Codex scheduled-task workflow with Markdown templates, reusable prompts, and
artifact specifications.

## Quick Start

1. Create your own `user_plan.md`.
   - Start from `templates/user_plan.md`.
   - Use `examples/graduation/` or `examples/product_launch/user_plan.md` as concrete references.
   - At minimum, include a phase plan and a current month plan. Schedule preferences and output preferences are strongly recommended because they become the automation cadence.

2. Ask Codex to configure the workflow and automations with a prompt like:

```text
Create automation from LifeEnergyManager and my user_plan.md.

Requirements:
- Read LifeEnergyManager/README.md, prompts/setup.md, prompts/automation.md, prompts/subagents.md, and my user_plan.md.
- Initialize outputs/life_energy_tracker.md from user_plan.md.
- Put all persistent outputs under outputs/.
- Name the scheduled tasks `LifeEnergyManager - <project name> (morning planning)`, `LifeEnergyManager - <project name> (evening check-in)`, and `LifeEnergyManager - <project name> (Sunday review)`.
- Create the three scheduled tasks from prompts/automation.md: morning planning, evening check-in, and Sunday review.
- Use the matching LifeEnergyManager skill from skills/ or an installed $life-energy-* skill by default. Escalate to the matching subagent only for independent review, parallel analysis, bias-prone judgment, or high-consequence planning changes as defined in prompts/subagents.md. If neither is available, record main-thread fallback.
```

3. After setup, use the generated daily HTML workbench during the day. At night, submit the generated report back to the evening check-in automation.

Use `prompts/automation.md` for the exact scheduled-task names, cadence, and prompt bodies.

Automation task names should be:

- `LifeEnergyManager - <project name> (morning planning)`
- `LifeEnergyManager - <project name> (evening check-in)`
- `LifeEnergyManager - <project name> (Sunday review)`

The custom project name goes before the parentheses. The text inside parentheses is the workflow type.

> The skill pipeline is the default local path. Subagents are an escalation path for independent review, parallel analysis, bias-prone judgments, and high-consequence changes.

## Recommended Files In A User Workspace

Codex creates one persistent output root during setup:

- `outputs/`

All persistent files created after local setup must live under `outputs/`:

- `outputs/life_energy_tracker.md`: the long-lived tracker and rolling state database.
- `outputs/daily-workbenches/YYYY-MM-DD-workbench.html`: interactive daily checklist and report generator.
- `outputs/daily-wallpapers/YYYY-MM-DD-daily-plan.png`: static desktop reminder.
- `outputs/daily-reports/YYYY-MM-DD-report.md`: optional saved report copied from the workbench.
- `outputs/phase_plan.md`: optional normalized phase plan.
- `outputs/month_plan.md`: optional normalized month plan.
- `outputs/profile.md`: optional normalized profile.

The user may provide either one combined `user_plan.md` or separate source files:

- `phase_plan.md`
- `month_plan.md`
- `profile.md`

The setup prompt normalizes either format into `outputs/` without moving the user's original source files.

## Workflow Contract

Morning planning:

- Read `prompts/subagents.md`, the user plan, `outputs/life_energy_tracker.md`, rolling 30-day state, active micro-sprints, and temporary urgent tasks.
- Ask whether there are extra tasks before finalizing the day.
- Triage extra tasks as critical, goal-leveraged, maintenance, or distraction.
- Use matching planning and triage skills when their triggers apply. Escalate to subagents only when the decision needs independent review, parallel analysis, or a second perspective on bias-prone tradeoffs.
- Produce a provisional plan and wait for user confirmation.
- After confirmation, generate both the HTML workbench and desktop wallpaper.
- QA artifacts with the artifact QA subagent when supported because artifact QA is an independent-review task; otherwise use the artifact QA skill.

Evening check-in:

- Prefer the report generated by the HTML workbench.
- Update daily log, rolling state, active micro-sprints, and temporary urgent tasks.
- Quantify next-day drive-resistance as a beta planning signal with the drive-resistance skill by default, not as diagnosis. Escalate to the energy subagent when the report is ambiguous or the score would change next-day intensity. `0` means tomorrow's motivation and willingness are strong, including physically tired today but still eager to continue; `100` means tomorrow is likely to feel resistant, unwilling, or hard to start.
- Generate a short seed for the next morning.

Sunday review:

- Keep it light.
- Summarize the last 7 days, compress older state, choose the next week's priorities, and identify agent-delegable work.
- Use the weekly review skill before finalizing next week's plan. Escalate to the weekly review subagent when repeated deferrals, unclear blockers, or major priority changes need a second pass.

## Skill Default And Subagent Escalation Strategy

LifeEnergyManager uses matching skills for bounded analysis by default. It escalates to subagents only when the Codex environment supports them and the task benefits from independent review, parallel analysis, a second perspective on bias-prone judgment, or extra care for a high-consequence planning change. Final judgment stays with the main Codex thread.

Default skill tasks:

- normalize phase/month plans,
- triage urgent tasks,
- draft daily plan options,
- quantify next-day drive-resistance from evening reports,
- suggest status/advice/anti-distraction guidance,
- QA generated HTML and wallpaper artifacts,
- summarize weekly logs.

Skill map:

- `PlanNormalizerAgent` -> `$life-energy-plan-normalizer`
- `UrgencyTriageAgent` -> `$life-energy-urgency-triage`
- `DailyPlannerAgent` -> `$life-energy-daily-planner`
- `EnergyQuantAgent` -> `$life-energy-drive-resistance`
- `AdviceAgent` -> `$life-energy-advice`
- `ArtifactQAAgent` -> `$life-energy-artifact-qa`
- `WeeklyReviewAgent` -> `$life-energy-weekly-review`

If neither matching skills nor justified subagent tools are available, the workflow continues in the main thread and records `main-thread fallback` in a `Subagent calls` audit block.

Do not fully delegate:

- final daily plan confirmation,
- major priority tradeoffs,
- accepting or rejecting urgent tasks,
- increasing or reducing the next day's workload.

See `prompts/subagents.md` for the full contract.

## Template Map

- `templates/user_plan.md`: user-facing intake template.
- `templates/tracker.md`: persistent state template.
- `templates/daily_workbench_template.html`: structure for the interactive daily HTML artifact.
- `templates/wallpaper_spec.md`: layout and visual rules for the desktop PNG.
- `prompts/setup.md`: normalize a user's plan and initialize the tracker.
- `prompts/automation.md`: scheduled-task setup instructions.
- `prompts/morning.md`: morning planning workflow.
- `prompts/evening.md`: evening report and state update workflow.
- `prompts/sunday_review.md`: weekly review workflow.
- `prompts/artifact_spec.md`: required HTML and wallpaper artifact behavior.
- `prompts/subagents.md`: skill-default and subagent-escalation contracts.
- `skills/`: default bounded-analysis contracts for LifeEnergyManager tasks.

## Example

`examples/graduation/` contains an anonymized dissertation-style workflow. It keeps the same planning logic as the original workflow while removing personal repository names and thesis-specific identifiers.

`examples/product_launch/` contains a non-academic example to verify that the workflow does not depend on thesis-specific language.

## Safety Notes

- Next-day drive-resistance scoring is a beta planning heuristic only. Higher score means lower next-day drive, not merely more physical tiredness.
- Do not use this workflow as medical, psychological, legal, or financial advice.
- Do not punish an incomplete day by automatically increasing the next day's workload. Identify whether the issue was energy, overplanning, blocker, external obligation, or avoidance.

## License

Apache License 2.0. See `LICENSE` and `NOTICE`.
