---
name: life-energy-advice
description: Draft concise LifeEnergyManager status summary, today advice, and anti-distraction tip from rolling state and daily plan context. Use as the default bounded-analysis path before any justified AdviceAgent escalation.
---

# Life Energy Advice

## Overview

Use this skill as the default bounded-analysis contract for short daily reminder text. Escalate to `AdviceAgent` only when state interpretation or the distraction pattern is unclear from evidence. It drafts short reminder text for the provisional plan and wallpaper right column.

The skill must preserve readability before brevity. The HTML workbench may use
longer explanatory wording; the wallpaper should use shorter wording derived
from the same meaning, not cryptic compression.

## Inputs

- Rolling 30-day state.
- Active phase, month, week, and micro-sprints.
- Provisional daily plan context.
- Recurring blockers, repeated deferrals, and likely distraction patterns.
- Output surfaces:
  - HTML workbench: can use longer, clearer text.
  - Wallpaper: must fit the layout but still be understandable.
- User's working language or the dominant language of the current plan.

## Procedure

1. Identify the current state from evidence.
2. Draft clear HTML wording for:
   - status summary,
   - today advice,
   - anti-distraction tip.
3. Derive shorter wallpaper wording from the HTML meaning.
4. Check each line for readability:
   - It should be understandable without decoding planning jargon.
   - It should name the concrete action, time window, output, or decision when relevant.
   - It should avoid unexplained abstractions, metaphors, and compressed English planning phrases such as `protected exit block`, `external handoffs are real`, or `visibly smaller`.
   - It should use natural Chinese when the surrounding plan is Chinese, while preserving stable project names such as `WDM`.
5. Keep wallpaper lines short enough for wallpaper text, but if brevity makes a line unclear, reduce detail rather than using cryptic wording.
6. Avoid generic motivation.

## Output

Return:

- HTML status summary,
- HTML today advice,
- HTML anti-distraction tip,
- wallpaper status summary,
- wallpaper today advice,
- wallpaper anti-distraction tip,
- evidence basis.

If the caller requires the legacy fields `status summary`, `today advice`, and
`anti-distraction tip`, use the wallpaper wording for those fields and include
the HTML wording as separate notes.

## Boundaries

- Do not choose final plan tasks.
- Do not add process instructions to wallpaper copy.
- The main thread may edit the final wording.
- Do not sacrifice basic readability to satisfy wallpaper length.
