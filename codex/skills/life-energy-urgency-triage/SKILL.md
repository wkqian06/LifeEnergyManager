---
name: life-energy-urgency-triage
description: Classify extra LifeEnergyManager morning tasks as critical, goal-leveraged, maintenance, or distraction, and propose time caps and tradeoffs. Use as the default bounded-analysis path before any justified UrgencyTriageAgent escalation.
---

# Life Energy Urgency Triage

## Overview

Use this skill as the default bounded-analysis contract for extra urgent, external, or tempting tasks before the main thread accepts or rejects them. Escalate to `UrgencyTriageAgent` only when a task would displace thesis-critical work, has ambiguous urgency, or looks like productive procrastination.

## Inputs

- Extra tasks supplied by the user during morning intake.
- Active phase, month, week, rolling state, active micro-sprints, and ongoing commitments.
- Any real deadlines or external dependencies.

## Classification

- Critical: must be handled today because of a real deadline or external dependency.
- Goal-leveraged: supports the active phase or month and can replace lower-value work.
- Maintenance: useful but should be timeboxed after core work.
- Distraction: park in backlog unless the user explicitly chooses the tradeoff.

## Procedure

1. Classify each task.
2. State evidence and inference separately.
3. Recommend a time cap.
4. Name what the task replaces, shrinks, or defers.
5. Judge one-day vs multi-day. For an accepted multi-day task, propose the Ongoing Commitments entry per the tracker table-header rules: decidable exit criterion, deadline date + hard/soft (no real deadline -> soft = today + 14 days), placement policy (which budget daily slices draw from; external-party criterion -> propose paused (until: condition)).
6. Flag any task that needs user confirmation before acceptance.

## Output

For each task, return:

- classification,
- why,
- recommended time cap,
- replacement or deferral,
- one-day / multi-day judgment and, for accepted multi-day tasks, the proposed Ongoing Commitments entry,
- open confirmation needed.

## Boundaries

- Do not accept or reject tasks.
- Do not increase workload just because yesterday was incomplete.
- The main thread must make final tradeoff decisions.
