---
name: life-energy-plan-revision
description: Audit LifeEnergyManager morning changes for future-plan impact, classify them as none, inline, correction, or rebaseline, and draft a confirmation-ready change set before daily artifacts exist.
---

# Life Energy Plan Revision

## Overview

Use this skill after morning intake and urgency triage whenever the user adds or
changes future work, a deadline, sequence, scope, commitment, weekly outcome,
monthly gate, or phase target. It proposes a bounded change set; the main thread
owns mode entry, confirmations, writes, rollback, and the final daily plan.

Escalate to `PlanRevisionAgent` only for month/phase changes, rebaseline, red
feasibility, or conflicting plan sources.

## Inputs

- Goal Lifecycle And Feasibility Model and Goal Baseline Registry from the tracker.
- Active phase, month, week, micro-sprints, and ongoing commitments.
- Accepted extra tasks or explicit user change requests.
- Goal Drift Guard result, planning calibration, and rolling history.
- Today's artifact existence/start state and persisted artifact-lock file.

## Procedure

1. If either daily artifact or today's persisted artifact lock exists/started,
   return no revision and route the change to unplanned-work capture for
   evening/next morning.
2. Identify affected Goal IDs and separate evidence from inference.
3. Test whether the change closes inside existing capacity without changing
   dependencies, critical-path order, or a month/phase gate.
4. Classify the request using the tracker's single-source definitions:
   `none`, `inline`, `correction`, or `rebaseline`.
   `rebaseline` always requires correction mode and three replies; it closes the
   old Goal ID, preserves original baseline/debt, and creates a successor ID.
5. Draft the smallest sufficient before/after change set and name displaced,
   reduced, extended, operationally paused, dropped, or successor work. Include
   required Goal Registry, Closure Log, Revision Log, revision-count/debt/delay,
   affected plan-file, and tracker writes; the Revision ID suffix is the next
   ordinal, not the confirmation count.
6. Return the required confirmation count. Never merge the three confirmations
   for month/phase/rebaseline into one user reply.
7. Give one concrete action for returning to the mainline after correction.

## Output

```yaml
revision_kind: none | inline | correction | rebaseline
affected_goal_ids:
affected_levels:
requires_correction_mode: true | false
confirmations_required: 0 | 1 | 3
change_set:
affected_files:
return_to_mainline_action:
evidence:
inference:
open_confirmation_needed:
```

## Boundaries

- Do not accept or reject the change.
- Do not enter or exit correction mode.
- Do not write plan files or generate artifacts.
- Keep original user input files read-only; every proposed persistent target in
  `affected_files` must be under `outputs/`.
- Do not move an external hard deadline without evidence that it changed.
- Do not overwrite an original goal; rebaseline closes it and creates a successor.
