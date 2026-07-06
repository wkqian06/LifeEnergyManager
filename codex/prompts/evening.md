# LifeEnergyManager Evening Check-In Prompt

Use this prompt for the Monday-Saturday evening scheduled task.

## Role

You are closing the day with minimal friction. Prefer the user's generated HTML workbench report over a new manual report.

## Inputs

Read `codex/prompts/subagents.md` before processing the evening report.

Ask the user to paste or provide the generated report from today's `outputs/daily-workbenches/YYYY-MM-DD-workbench.html`.

If the report is unavailable, ask only for:

- completed tasks,
- not completed tasks,
- blockers or next actions,
- total focus minutes,
- energy/condition,
- agent work launched or reviewed,
- tomorrow first action.

## Processing

From the report:

1. Update the daily log.
2. Update rolling 30-day state:
   - recent focus trend,
   - next-day drive-resistance pattern,
   - recurring blockers,
   - repeatedly deferred tasks (ongoing commitments are exempt - their absence is tracked only by Skip count),
   - agent tasks pending review.
3. Update active micro-sprints only when there was concrete artifact progress or a real blocker.
4. Settle the Ongoing Commitments table (this step is the ONLY writer of Skip count):
   - For every active row, from the workbench report: a day ending with 0 actual minutes on that commitment (slice card planned/skipped with actual empty or 0, or no slice card at all) -> Skip count +1; >0 actual minutes -> reset Skip count to 0; done/in-progress/blocked slice cards -> Skip count unchanged. If today's plan was a compressed (`manual_catchup`) or Recovery plan: no +1, no reset.
   - Update Done/Remaining minutes from the report.
   - Exit judgment: a done slice card proves the slice only, never the whole commitment. Close a commitment only with exit-criterion evidence (an artifact named in the card note, or ask the user one question: "Is the exit criterion <X> met?"). On close, ask once whether follow-up work remains (-> new commitment or backlog).
   - Terminal rows (done/dropped, incl. absorbed-as-dropped per the table-header rules) leave the table now; write the Daily Log closing line: `Commitment closed: <name> - entered <d1>, exited <d2>, total <n>m, outcome <line>`.
5. Generate a seed for tomorrow's morning plan.
6. If saving a standalone daily report, write it to `outputs/daily-reports/YYYY-MM-DD-report.md`.

## Next-Day Drive-Resistance Score Beta

When enough report content exists, use `$life-energy-drive-resistance` by default to infer:

- `agent_energy_score` from 0 to 100,
- `agent_energy_confidence`,
- `agent_energy_summary`,
- `planning_adjustment`.

Score direction:

- `0` means tomorrow's motivation and willingness are strong, including physically tired today but still eager to continue.
- `100` means tomorrow is likely to feel resistant, unwilling, or hard to start.
- Higher score means lower next-day drive, not merely more physical tiredness.
- If the user feels very tired but remains motivated and expects to continue meaningful work tomorrow, record a relatively low score.

Escalate to `EnergyQuantAgent` only when the report is ambiguous, emotionally strong, or completion, fatigue, motivation, and next-day willingness point in different directions, and subagent tools are available.

If only sparse data exists, ask for the minimal evening fields first, then use `$life-energy-drive-resistance` if available or escalate to `EnergyQuantAgent` only when the escalation signals apply. If neither `$life-energy-drive-resistance` nor a justified `EnergyQuantAgent` path is available, record `EnergyQuantAgent: main-thread fallback` and complete the same conservative next-day drive-resistance inference in the main thread.

Persist the user's own score if present:

- `user_energy_score`,
- `user_energy_note`.

Rules:

- This is not diagnosis.
- Do not punish low completion with automatic workload increase.
- Compare agent and user drive-resistance scores only as planning calibration.
- Today's user drive-resistance score appears in tomorrow's Recent State chart, not today's chart.

## Output

After updating the tracker, report:

- what changed in the tracker,
- current focus trend,
- current next-day drive-resistance pattern,
- unresolved blockers,
- tomorrow's first action,
- whether tomorrow should likely be Recovery, Standard, Push, or Deadline,
- the required `Subagent calls` audit block.

```text
Subagent calls:
- EnergyQuantAgent: skill used / subagent used / main-thread fallback / not needed
- Reason:
- Main-thread decision:
```
