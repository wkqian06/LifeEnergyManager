# LifeEnergyManager - Codex Entry Point

This repository supports two agent platforms with physically separated instruction sets. **You are reading the Codex entry point.**

## Platform Routing

- **Codex (you): use `codex/` only.** All Codex workflow prompts live in `codex/prompts/` and all Codex skills in `codex/skills/`.
- **Ignore `claudecode/`, `.claude/`, and `CLAUDE.md`.** They are the Claude Code edition of the same workflow. Never read them when configuring or running Codex automations; mixing the two editions produces wrong scheduling instructions and wrong skill/subagent invocation syntax.
- Exception: when the user explicitly asks to maintain, compare, audit, or synchronize both platform editions, you may read the Claude Code files for that maintenance task only. Do not use Claude Code instructions as Codex runtime instructions.
- Shared, platform-neutral assets: `templates/`, `examples/`, and the user's `outputs/` directory.

## What This Workflow Is

LifeEnergyManager is a daily planning workflow with three scheduled tasks per project:

- `LifeEnergyManager - <project name> (morning planning)` - Monday-Saturday
- `LifeEnergyManager - <project name> (evening check-in)` - Monday-Saturday
- `LifeEnergyManager - <project name> (Sunday review)` - Sunday

## Codex File Map

- `codex/prompts/setup.md`: normalize a user's plan and initialize the tracker.
- `codex/prompts/automation.md`: scheduled-task names, cadence, RRULE encoding, and prompt bodies.
- `codex/prompts/morning.md`, `codex/prompts/evening.md`, `codex/prompts/sunday_review.md`: the three workflows.
- `codex/prompts/subagents.md`: skill-default and subagent-escalation contracts. Read it before every workflow run.
- `codex/skills/life-energy-*/`: the seven `$life-energy-*` skill contracts.
- `templates/daily_workbench_template.html`: shared HTML workbench template.
- `templates/artifact_spec.md` and `templates/wallpaper_spec.md`: shared artifact and wallpaper requirements.
- `templates/wallpaper_generator.ps1`: optional Windows PowerShell wallpaper generator. If the current environment can run it, use it; otherwise generate the PNG by another suitable method while following the shared specs.

## Hard Rules

- All persistent files created after setup must live under `outputs/`.
- For local Codex automations, encode schedules with RRULE `BYHOUR`/`BYMINUTE` exactly as specified in `codex/prompts/automation.md`.
- Matching `$life-energy-*` skills are the default bounded-analysis path; escalate to subagents only per `codex/prompts/subagents.md`; otherwise record `main-thread fallback`.
- Final plan confirmation, priority tradeoffs, urgent-task acceptance, commitment dispositions (skips, inquiries, mainline displacement, cap evictions), and intensity changes stay in the main Codex thread.
