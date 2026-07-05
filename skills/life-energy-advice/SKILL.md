---
name: life-energy-advice
description: Draft concise LifeEnergyManager status summary, today advice, and anti-distraction tip from rolling state and daily plan context. Use as the default bounded-analysis path before any justified AdviceAgent escalation.
---

# Life Energy Advice

## Overview

Use this skill as the default bounded-analysis contract for short daily reminder text. Escalate to `AdviceAgent` only when state interpretation or the distraction pattern is unclear from evidence. It drafts short reminder text for the provisional plan and wallpaper right column.

## Inputs

- Rolling 30-day state.
- Active phase, month, week, and micro-sprints.
- Provisional daily plan context.
- Recurring blockers, repeated deferrals, and likely distraction patterns.

## Procedure

1. Identify the current state from evidence.
2. Draft one status summary line.
3. Draft one today advice line.
4. Draft one anti-distraction tip naming the likely distraction pattern.
5. Keep lines short enough for wallpaper text.
6. Avoid generic motivation.

## Output

Return:

- status summary,
- today advice,
- anti-distraction tip,
- evidence basis.

## Boundaries

- Do not choose final plan tasks.
- Do not add process instructions to wallpaper copy.
- The main thread may edit the final wording.
