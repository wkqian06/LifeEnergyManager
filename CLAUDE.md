# LifeEnergyManager - Claude Code Entry Point

This repository supports two agent platforms with physically separated instruction sets. **You are reading the Claude Code entry point.**

## Platform Routing

- **Claude Code (you): use `claudecode/` + `.claude/` only.** Workflow prompts live in `claudecode/prompts/`; the nine `life-energy-*` skills are auto-discovered from `.claude/skills/`; the nine escalation subagents are defined in `.claude/agents/`.
- **Ignore `codex/` and `AGENTS.md`.** They are the Codex edition of the same workflow. Never read them when configuring or running Claude Code automations; their scheduling encoding (RRULE) and invocation syntax (`$life-energy-*`, `XxxAgent` subagent tools) do not apply here.
- Exception: when the user explicitly asks to maintain, compare, audit, or synchronize both platform editions, you may read the Codex files for that maintenance task only. Do not use Codex instructions as Claude Code runtime instructions.
- Shared, platform-neutral assets: `templates/`, `examples/`, and the user's `outputs/` directory.

## What This Workflow Is

LifeEnergyManager is a daily planning workflow with three local routines per project:

- `LifeEnergyManager - <project name> (morning planning)` - Monday-Saturday
- `LifeEnergyManager - <project name> (evening check-in)` - Monday-Saturday
- `LifeEnergyManager - <project name> (Sunday review)` - Sunday

Each scheduled run follows the matching workflow file:

- Setup: `claudecode/prompts/setup.md` (normalize the user plan, initialize `outputs/life_energy_tracker.md`).
- Scheduling: `claudecode/prompts/automation.md` (local routines in the Claude Code desktop app as the primary path; a system scheduler launching an interactive session as fallback; never cloud routines - they cannot ask questions mid-run or write local `outputs/`).
- Morning: `claudecode/prompts/morning.md`. Evening: `claudecode/prompts/evening.md`. Sunday: `claudecode/prompts/sunday_review.md`.
- Invocation contracts: `claudecode/prompts/subagents.md`. Read it before every workflow run.

## Skill Default And Subagent Escalation

- Default bounded-analysis path: the matching `life-energy-*` skill from `.claude/skills/`. Record `skill used` in the audit block.
- Escalate to the matching subagent from `.claude/agents/` (`plan-normalizer`, `urgency-triage`, `goal-drift-guard`, `plan-revision`, `daily-planner`, `energy-quant`, `advice`, `artifact-qa`, `weekly-review`) only when the escalation signals in `claudecode/prompts/subagents.md` apply: independent review, parallel analysis, bias-prone judgment, or high consequence. Exception: `artifact-qa` is the default for artifact QA because QA is an independent-review task.
- The role-specific `only` lists override those global signals: GoalDriftGuardAgent
  is limited to exit-evidence, original-baseline, or drift-attribution conflicts;
  PlanRevisionAgent is limited to month/phase, rebaseline, red feasibility, or
  conflicting-plan-source review. Generic high consequence alone invokes neither.
- If neither path is available, continue in the main session and record `main-thread fallback`.
- Every workflow output includes the `Subagent calls` audit block defined in `claudecode/prompts/subagents.md`.

## Hard Rules

- All persistent files created after setup must live under `outputs/` (`outputs/life_energy_tracker.md`, `outputs/phase_plan.md`, `outputs/month_plan.md`, `outputs/profile.md`, `outputs/artifact-locks/`, `outputs/daily-workbenches/`, `outputs/daily-wallpapers/`, `outputs/daily-reports/`).
- Decisions reserved for the main session: final plan confirmation, major priority tradeoffs, accepting or rejecting urgent tasks, commitment dispositions (skips, inquiries, mainline displacement, cap evictions), changing next-day intensity, creating or updating routines.
- The main session also owns goal terminal choices, correction-mode entry/exit,
  persistent revision confirmations, rebaseline, atomic writes/rollback, and the
  pre-artifact revision lock.
- The morning workflow must ask about extra tasks and wait for user confirmation before generating HTML/PNG artifacts.
- Energy remaining, predicted next-day drive, and actual drive are beta planning
  heuristics, never diagnosis; all use the tracker model's same-direction scale
  where higher means more energy/drive.
- Do not punish an incomplete day by automatically increasing the next day's workload.
